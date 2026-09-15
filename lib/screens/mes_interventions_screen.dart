import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_db.dart';
import '../models/enums.dart';
import '../services/api_client.dart';
import '../services/sync_service.dart';
import '../state/interventions_provider.dart';
import '../theme/design_tokens.dart';
import '../utils/date.dart';
import 'connexion_screen.dart';
import 'detail_intervention_screen.dart';

enum _Onglet { toutes, planifiees, realisees }

/// Fenetre au-dela de laquelle une intervention n'est plus consideree comme
/// recemment assignee (badge "Nouveau" sur la tuile).
const _dureeNouveaute = Duration(hours: 24);

/// Ecran "Mes interventions" (US2.1). L'affichage lit uniquement la base
/// locale, jamais le reseau directement : seule la synchro (bouton, tirer-
/// pour-rafraichir, automatique a l'ouverture, retour de connectivite, ou
/// retour au premier plan) parle a l'API et met a jour la base, ce qui fait
/// reagir la liste.
class MesInterventionsScreen extends ConsumerStatefulWidget {
  const MesInterventionsScreen({super.key});

  @override
  ConsumerState<MesInterventionsScreen> createState() =>
      _MesInterventionsScreenState();
}

class _MesInterventionsScreenState extends ConsumerState<MesInterventionsScreen>
    with WidgetsBindingObserver {
  _Onglet _onglet = _Onglet.toutes;
  bool _synchronisationEnCours = false;
  StreamSubscription<List<ConnectivityResult>>? _abonnementConnectivite;
  bool _etaitConnecte = true;
  bool _horsLigne = false;
  DateTime? _derniereSynchro;
  String? _nomTechnicien;

  @override
  void initState() {
    super.initState();
    // setState ne doit pas etre appele de facon synchrone pendant initState :
    // on attend le premier frame (addPostFrameCallback) avant de lancer la
    // synchro, qui met _synchronisationEnCours a jour via setState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _synchroniser();
      _chargerNomTechnicien();
      _chargerDerniereSynchroPersistee();
    });

    _abonnementConnectivite = Connectivity().onConnectivityChanged.listen(
      _surChangementConnectivite,
    );
    _verifierConnectiviteInitiale();
    WidgetsBinding.instance.addObserver(this);
  }

  /// Opportuniste (GET /auth/moi) : simple complement d'affichage, jamais
  /// bloquant. AuthService.nomTechnicien() ne leve jamais (hors ligne, jeton
  /// expire... renvoient null), donc pas de try/catch ici.
  Future<void> _chargerNomTechnicien() async {
    final nom = await ref.read(authServiceProvider).nomTechnicien();
    if (mounted && nom != null) setState(() => _nomTechnicien = nom);
  }

  /// Valeur persistee (survit a un redemarrage de l'app), affichee tant que
  /// la synchro automatique de cette ouverture d'ecran n'a pas encore abouti.
  /// `_derniereSynchro == null` (verifie a la resolution, pas au lancement)
  /// evite d'ecraser une synchro fraiche si elle a deja abouti entre-temps :
  /// la lecture du stockage securise est generalement plus rapide qu'un
  /// aller-retour reseau, mais rien ne le garantit.
  Future<void> _chargerDerniereSynchroPersistee() async {
    final derniere = await ref.read(syncServiceProvider).derniereSynchroReussie();
    if (mounted && derniere != null && _derniereSynchro == null) {
      setState(() => _derniereSynchro = derniere);
    }
  }

  /// Etat reel a l'ouverture (le premier evenement du flux onConnectivityChanged
  /// n'est pas garanti immediat selon la plateforme) : evite que le bandeau
  /// hors ligne mette une fraction de seconde a apparaitre si l'appareil est
  /// deja hors ligne au lancement de l'ecran.
  Future<void> _verifierConnectiviteInitiale() async {
    final resultats = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() => _horsLigne = resultats.contains(ConnectivityResult.none));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _abonnementConnectivite?.cancel();
    super.dispose();
  }

  /// Retour au premier plan (le technicien revient sur l'app apres etre alle
  /// sur une autre, ex. l'appareil photo natif ou un appel telephonique) :
  /// meme logique que la synchro automatique a l'ouverture de l'ecran.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _synchroniser();
  }

  /// `_etaitConnecte` demarre a true pour ne pas redeclencher une synchro
  /// des le premier evenement (qui reflete l'etat courant a l'abonnement,
  /// generalement deja connecte) : seul un vrai retour de connexion, apres
  /// une coupure detectee, doit relancer une synchro automatique.
  void _surChangementConnectivite(List<ConnectivityResult> resultats) {
    final connecte = !resultats.contains(ConnectivityResult.none);
    if (connecte && !_etaitConnecte) {
      _synchroniser();
    }
    _etaitConnecte = connecte;
    if (mounted) setState(() => _horsLigne = !connecte);
  }

  Future<void> _synchroniser() async {
    if (_synchronisationEnCours) return;
    setState(() => _synchronisationEnCours = true);
    try {
      final resultat = await ref.read(syncServiceProvider).synchroniser();
      if (mounted) setState(() => _derniereSynchro = DateTime.now());
      final message = _messageResultatSynchro(resultat);
      if (mounted && message != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (erreur) {
      final message = _messageErreurSynchro(erreur);
      if (mounted && message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) setState(() => _synchronisationEnCours = false);
    }
  }

  /// Message affiche au technicien : distingue une vraie erreur serveur
  /// (code + texte du backend) d'un probleme de connexion, plutot qu'un
  /// message generique "verifiez votre connexion" qui masquait la cause
  /// reelle (ex. bug cote app, fichier photo manquant).
  ///
  /// Null si l'erreur est un simple probleme de connectivite (ex. l'appareil
  /// vient de passer hors ligne pile pendant la requete, avant meme que
  /// `_horsLigne` ait ete mis a jour par l'ecouteur de connectivite) : le
  /// bandeau "Hors ligne" l'annonce deja, un second message technique brut
  /// (SocketException, errno...) n'apporte rien au technicien et ressemble a
  /// un plantage alors que c'est un etat normal sur le terrain.
  String? _messageErreurSynchro(Object erreur) {
    if (erreur is ApiException) {
      return 'Erreur du serveur (${erreur.statusCode}) : ${erreur.message}';
    }
    if (_horsLigne || erreur.toString().contains('SocketException')) {
      return null;
    }
    return 'Synchronisation impossible : $erreur';
  }

  /// Combine les deux types de conflits d'un cycle de synchro en un seul
  /// message (rare d'avoir les deux a la fois, mais pas exclu). Null si tout
  /// s'est bien passe.
  String? _messageResultatSynchro(ResultatSynchro resultat) {
    final phrases = <String>[];
    if (resultat.conflitsClotures > 0) {
      phrases.add(
        resultat.conflitsClotures == 1
            ? "1 intervention a été annulée entre-temps, la clôture locale a été abandonnée."
            : '${resultat.conflitsClotures} interventions ont été annulées entre-temps, les clôtures locales ont été abandonnées.',
      );
    }
    if (resultat.photosEnConflit > 0) {
      phrases.add(
        resultat.photosEnConflit == 1
            ? "1 photo n'a pas pu être synchronisée (catégorie déjà complète)."
            : '${resultat.photosEnConflit} photos n\'ont pas pu être synchronisées (catégorie déjà complète).',
      );
    }
    return phrases.isEmpty ? null : phrases.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final interventions = ref.watch(interventionsAttribueesProvider);
    final idsAvecPhotosEnAttente =
        ref.watch(interventionsAvecPhotosEnAttenteProvider).asData?.value ??
        const <String>{};
    final idsAvecPhotosEnConflit =
        ref.watch(interventionsAvecPhotosEnConflitProvider).asData?.value ??
        const <String>{};

    return Scaffold(
      backgroundColor: paper,
      body: SafeArea(
        child: interventions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (erreur, _) => Center(
            child: Text(
              'Erreur de lecture locale : $erreur',
              style: const TextStyle(color: danger),
            ),
          ),
          data: (toutes) => _corps(toutes, idsAvecPhotosEnAttente, idsAvecPhotosEnConflit),
        ),
      ),
    );
  }

  /// Plus recent de misAJourLe (serveur) et modifieLocalementLe (local, non
  /// nul uniquement si une saisie/cloture locale n'a pas encore ete
  /// confirmee) : reflete quand l'intervention a reellement change en
  /// dernier, contrairement a datePrevue qui ne bouge jamais apres creation.
  DateTime _derniereActivite(Intervention intervention) {
    final local = intervention.modifieLocalementLe;
    if (local == null) return intervention.misAJourLe;
    return local.isAfter(intervention.misAJourLe) ? local : intervention.misAJourLe;
  }

  Widget _corps(
    List<Intervention> toutes,
    Set<String> idsAvecPhotosEnAttente,
    Set<String> idsAvecPhotosEnConflit,
  ) {
    // "Planifiees" reste trie par date prevue croissante (prochaine echeance
    // en premier, source directe de watchAttribuees()) : c'est ce qui rend
    // une nouvelle intervention visible en premiere ligne des sa reception,
    // demande confirmee par Cedric. "Toutes" et "Realisees" sont trie par
    // derniere activite decroissante (la plus recente en premier, comme un
    // flux d'activite). Premiere version (simple `.reversed` sur la liste
    // triee par datePrevue) etait fausse : datePrevue est la date prevue au
    // depart, jamais mise a jour a la cloture - une intervention fraichement
    // cloturee mais planifiee a une date ancienne restait invisible derriere
    // d'autres interventions a datePrevue plus lointaine. `_derniereActivite`
    // prend le plus recent de misAJourLe (mis a jour par le serveur au pull)
    // et modifieLocalementLe (mis a jour immediatement a la cloture, avant
    // meme que la synchro n'ait confirme) : couvre le court instant entre
    // cloture locale et confirmation serveur.
    final planifiees = toutes
        .where((i) => i.statut == StatutIntervention.planifiee)
        .toList();
    final toutesRecentDabord = [...toutes]
      ..sort((a, b) => _derniereActivite(b).compareTo(_derniereActivite(a)));
    final realisees = toutesRecentDabord
        .where((i) => i.statut == StatutIntervention.realisee)
        .toList();
    final affichees = switch (_onglet) {
      _Onglet.toutes => toutesRecentDabord,
      _Onglet.planifiees => planifiees,
      _Onglet.realisees => realisees,
    };

    return Column(
      children: [
        _entete(toutes, idsAvecPhotosEnAttente, idsAvecPhotosEnConflit),
        _metaSynchro(),
        if (_horsLigne) _bandeauHorsLigne(),
        _onglets(toutes.length, planifiees.length, realisees.length),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _synchroniser,
            child: affichees.isEmpty
                ? _etatVide()
                : _liste(affichees, idsAvecPhotosEnAttente, idsAvecPhotosEnConflit),
          ),
        ),
      ],
    );
  }

  Widget _entete(
    List<Intervention> toutes,
    Set<String> idsAvecPhotosEnAttente,
    Set<String> idsAvecPhotosEnConflit,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kickerDateHeure(),
                const SizedBox(height: 6),
                const Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      color: inkColor,
                      letterSpacing: -0.8,
                    ),
                    children: [
                      TextSpan(text: 'Mes '),
                      TextSpan(
                        text: 'interventions',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _boutonDeconnexion(),
          const SizedBox(width: 8),
          _boutonSynchroniser(
            _couleurIndicateurSynchro(toutes, idsAvecPhotosEnAttente, idsAvecPhotosEnConflit),
          ),
        ],
      ),
    );
  }

  /// US4.3 (promue le 2026-09-14). Meme gabarit que _boutonSynchroniser
  /// (boite 36x36, bordure `line`) pour former un seul groupe d'actions
  /// coherent dans l'en-tete plutot que deux styles de bouton differents
  /// (constat Cedric le 2026-09-15 : l'icone de sortie denotait a cote du
  /// bouton de synchro). Modale de confirmation (pas juste un appui direct) :
  /// la deconnexion vide aussi la base locale
  /// (AppDatabase.viderPourDeconnexion(), cf. son commentaire), le
  /// technicien doit savoir qu'il perd le cache local avant de confirmer.
  Widget _boutonDeconnexion() {
    return Tooltip(
      message: 'Se déconnecter',
      child: InkWell(
        key: const Key('boutonDeconnexion'),
        onTap: _demanderDeconnexion,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            border: Border.all(color: line),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Center(
            child: Icon(Icons.logout, size: 16, color: textSoft),
          ),
        ),
      ),
    );
  }

  Future<void> _demanderDeconnexion() async {
    final database = ref.read(databaseProvider);
    final authService = ref.read(authServiceProvider);

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: paper,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: inkColor, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        title: const Text('Se déconnecter ?'),
        content: const Text(
          "Les interventions et photos deja telechargees sur cet appareil seront effacees. "
          "Vous les retrouverez a la prochaine connexion, une fois reconnecte.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            key: const Key('boutonConfirmerDeconnexion'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Se déconnecter', style: TextStyle(color: danger)),
          ),
        ],
      ),
    );
    if (confirme != true || !mounted) return;

    await database.viderPourDeconnexion();
    await authService.deconnecter();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => ConnexionScreen(authService: authService)),
      (route) => false,
    );
  }

  /// Ligne "kicker" au-dessus du titre (mobile/design/M2 - Mes
  /// interventions.html) : jour, date et heure courants, purement decoratif.
  Widget _kickerDateHeure() {
    return Row(
      key: const Key('kickerDateHeure'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 1, color: inkColor),
        const SizedBox(width: 8),
        Text(
          formatJourDateHeure(DateTime.now()).toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: textWeak,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }

  /// Vert : tout est synchronise. Orange : une synchro est en cours ou il
  /// reste des clotures/photos locales non confirmees. Rouge : au moins une
  /// photo definitivement en conflit (priorite la plus haute, cf. le badge de
  /// tuile qui applique la meme hierarchie).
  Color _couleurIndicateurSynchro(
    List<Intervention> toutes,
    Set<String> idsAvecPhotosEnAttente,
    Set<String> idsAvecPhotosEnConflit,
  ) {
    if (idsAvecPhotosEnConflit.isNotEmpty) return danger;
    final clotureEnAttente = toutes.any((i) => i.statutSync != StatutSync.confirme);
    if (_synchronisationEnCours || clotureEnAttente || idsAvecPhotosEnAttente.isNotEmpty) {
      return warning;
    }
    return success;
  }

  Widget _boutonSynchroniser(Color couleurIndicateur) {
    return InkWell(
      key: const Key('boutonSynchroniser'),
      onTap: _synchronisationEnCours ? null : _synchroniser,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: _synchronisationEnCours
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync, size: 16, color: textSoft),
            ),
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                key: const Key('indicateurSynchro'),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: couleurIndicateur,
                  shape: BoxShape.circle,
                  border: Border.all(color: paper, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// US2.1 : nom du technicien (GET /auth/moi, opportuniste, absent si
  /// jamais recupere) et heure de la derniere synchro reussie (push + pull),
  /// persistee (SyncService.derniereSynchroReussie()) pour survivre a un
  /// redemarrage de l'app.
  Widget _metaSynchro() {
    if (_derniereSynchro == null && _nomTechnicien == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          if (_nomTechnicien != null)
            Text(
              _nomTechnicien!,
              key: const Key('nomTechnicien'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: textSoft,
                letterSpacing: 0.1,
              ),
            ),
          if (_nomTechnicien != null && _derniereSynchro != null) ...[
            const SizedBox(width: 8),
            Container(
              width: 3,
              height: 3,
              decoration: const BoxDecoration(color: textWeak, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
          ],
          if (_derniereSynchro != null)
            Text(
              _texteDerniereSynchro(_derniereSynchro!),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: textWeak,
                letterSpacing: 0.1,
              ),
            ),
        ],
      ),
    );
  }

  String _texteDerniereSynchro(DateTime derniere) {
    final ecart = DateTime.now().difference(derniere);
    if (ecart.inMinutes < 1) return "Synchronisé à l'instant";
    if (ecart.inHours < 1) return 'Synchronisé il y a ${ecart.inMinutes} min';
    if (ecart.inDays < 1) return 'Synchronisé il y a ${ecart.inHours} h';
    return 'Dernière synchro : ${formatDateHeure(derniere)}';
  }

  Widget _bandeauHorsLigne() {
    return Container(
      key: const Key('bandeauHorsLigne'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFFFEF3C7), // --warning-bg
      child: const Row(
        children: [
          Icon(Icons.wifi_off, size: 14, color: warning),
          SizedBox(width: 10),
          Text(
            'Hors ligne — données locales',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: warning,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _onglets(int nbToutes, int nbPlanifiees, int nbRealisees) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: line)),
      ),
      child: Row(
        children: [
          _ongletBouton(
            label: 'Toutes',
            nombre: nbToutes,
            valeur: _Onglet.toutes,
          ),
          const SizedBox(width: 16),
          _ongletBouton(
            label: 'Planifiées',
            nombre: nbPlanifiees,
            valeur: _Onglet.planifiees,
          ),
          const SizedBox(width: 16),
          _ongletBouton(
            label: 'Réalisées',
            nombre: nbRealisees,
            valeur: _Onglet.realisees,
          ),
        ],
      ),
    );
  }

  Widget _ongletBouton({
    required String label,
    required int nombre,
    required _Onglet valeur,
  }) {
    final actif = _onglet == valeur;
    return InkWell(
      onTap: () => setState(() => _onglet = valeur),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: actif ? inkColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: actif ? FontWeight.w600 : FontWeight.w500,
                color: actif ? inkColor : textWeak,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$nombre',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: actif ? inkColor : textWeak,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _liste(
    List<Intervention> interventions,
    Set<String> idsAvecPhotosEnAttente,
    Set<String> idsAvecPhotosEnConflit,
  ) {
    final tuiles = <Widget>[];
    for (var i = 0; i < interventions.length; i++) {
      if (i > 0) tuiles.add(const Divider(height: 1, color: lineSoft));
      tuiles.add(_tuile(
        interventions[i],
        idsAvecPhotosEnAttente.contains(interventions[i].idServeur),
        idsAvecPhotosEnConflit.contains(interventions[i].idServeur),
      ));
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [_indiceTirerPourSynchroniser(), ...tuiles],
    );
  }

  /// Repere visuel (mobile/design/M2 - Mes interventions.html) : fait partie
  /// du contenu scrollable, disparait donc quand on descend dans la liste,
  /// coherent avec le geste de tirer-pour-rafraichir deja branche via
  /// [RefreshIndicator] sur [_corps].
  Widget _indiceTirerPourSynchroniser() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.arrow_downward, size: 12, color: textWeak),
          SizedBox(width: 6),
          Text(
            'TIREZ POUR SYNCHRONISER',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textWeak,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeNouveau() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: brand,
        borderRadius: BorderRadius.circular(3),
      ),
      child: const Text(
        'NOUVEAU',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _tuile(Intervention intervention, bool aDesPhotosEnAttente, bool aDesPhotosEnConflit) {
    final couleurMarqueur = intervention.statut == StatutIntervention.planifiee
        ? warning
        : success;
    final clotureSynchronisee = intervention.statutSync == StatutSync.confirme;
    final String etiquetteSynchro;
    final Color couleurEtiquette;
    if (!clotureSynchronisee) {
      etiquetteSynchro = 'À synchroniser';
      couleurEtiquette = warning;
    } else if (aDesPhotosEnConflit) {
      etiquetteSynchro = 'Photo en échec';
      couleurEtiquette = danger;
    } else if (aDesPhotosEnAttente) {
      etiquetteSynchro = 'Photos à synchroniser';
      couleurEtiquette = warning;
    } else {
      etiquetteSynchro = 'Synchronisée';
      couleurEtiquette = textWeak;
    }
    // Cree il y a moins de _dureeNouveaute (web ou mobile) : le tri de
    // "Planifiees" reste par date prevue (utile pour "quoi faire ensuite"),
    // ce badge sert a reperer une nouvelle assignation sans avoir a changer
    // ce tri (demande Cedric du 2026-09-14, tranchee apres discussion sur le
    // compromis entre les deux). Uniquement sur une Planifiee pas encore
    // touchee (ni cloturee, ni deja "a synchroniser" - un technicien qui a
    // commence a saisir a deja vu l'intervention) et pas encore consultee
    // (vueLe, marque au tap ci-dessous : disparait une fois le detail ouvert).
    final estNouvelle = intervention.statut == StatutIntervention.planifiee &&
        clotureSynchronisee &&
        intervention.vueLe == null &&
        DateTime.now().difference(intervention.creeLe) < _dureeNouveaute;

    return InkWell(
      onTap: () {
        ref.read(databaseProvider).interventionDao.marquerVue(intervention.idServeur);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                DetailInterventionScreen(idServeur: intervention.idServeur),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3,
              height: 56,
              margin: const EdgeInsets.only(right: 12),
              color: couleurMarqueur,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        etiquetteSynchro,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: couleurEtiquette,
                        ),
                      ),
                      if (estNouvelle) ...[
                        const SizedBox(width: 6),
                        _badgeNouveau(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    intervention.nomClient,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: inkColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    intervention.adresse,
                    style: const TextStyle(fontSize: 12, color: textSoft),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatDateHeure(intervention.datePrevue),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: inkColor,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: couleurMarqueur,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            intervention.statut == StatutIntervention.planifiee
                                ? 'Planifiée'
                                : 'Réalisée',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: inkColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _etatVide() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      children: [
        Container(width: 24, height: 1, color: inkColor),
        const SizedBox(height: 12),
        const Text(
          'AUCUNE TÂCHE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: textSoft,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 8),
        const Text.rich(
          TextSpan(
            style: TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: inkColor,
              height: 1.15,
            ),
            children: [
              TextSpan(text: 'Aucune intervention '),
              TextSpan(
                text: 'attribuée.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Vous n'avez actuellement aucune intervention assignée.",
          style: TextStyle(fontSize: 13, color: textSoft, height: 1.5),
        ),
      ],
    );
  }
}
