import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_db.dart';
import '../models/enums.dart';
import '../services/api_client.dart';
import '../state/interventions_provider.dart';
import '../theme/design_tokens.dart';
import '../utils/date.dart';
import '../utils/reference.dart';
import 'detail_intervention_screen.dart';

enum _Onglet { toutes, planifiees, realisees }

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
      final conflits = await ref.read(syncServiceProvider).synchroniser();
      if (mounted) setState(() => _derniereSynchro = DateTime.now());
      if (mounted && conflits > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              conflits == 1
                  ? "1 intervention a été annulée entre-temps, la clôture locale a été abandonnée."
                  : '$conflits interventions ont été annulées entre-temps, les clôtures locales ont été abandonnées.',
            ),
          ),
        );
      }
    } catch (erreur) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_messageErreurSynchro(erreur))),
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
  String _messageErreurSynchro(Object erreur) {
    if (erreur is ApiException) {
      return 'Erreur du serveur (${erreur.statusCode}) : ${erreur.message}';
    }
    return 'Synchronisation impossible : $erreur';
  }

  @override
  Widget build(BuildContext context) {
    final interventions = ref.watch(interventionsAttribueesProvider);
    final idsAvecPhotosEnAttente =
        ref.watch(interventionsAvecPhotosEnAttenteProvider).asData?.value ??
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
          data: (toutes) => _corps(toutes, idsAvecPhotosEnAttente),
        ),
      ),
    );
  }

  Widget _corps(List<Intervention> toutes, Set<String> idsAvecPhotosEnAttente) {
    final planifiees = toutes
        .where((i) => i.statut == StatutIntervention.planifiee)
        .toList();
    final realisees = toutes
        .where((i) => i.statut == StatutIntervention.realisee)
        .toList();
    final affichees = switch (_onglet) {
      _Onglet.toutes => toutes,
      _Onglet.planifiees => planifiees,
      _Onglet.realisees => realisees,
    };

    return Column(
      children: [
        _entete(),
        _metaSynchro(),
        if (_horsLigne) _bandeauHorsLigne(),
        _onglets(toutes.length, planifiees.length, realisees.length),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _synchroniser,
            child: affichees.isEmpty
                ? _etatVide()
                : _liste(affichees, idsAvecPhotosEnAttente),
          ),
        ),
      ],
    );
  }

  Widget _entete() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text.rich(
            TextSpan(
              style: TextStyle(
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
          IconButton(
            key: const Key('boutonSynchroniser'),
            onPressed: _synchronisationEnCours ? null : _synchroniser,
            icon: _synchronisationEnCours
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync, size: 20, color: textSoft),
          ),
        ],
      ),
    );
  }

  /// US2.1 (dette technique) : nom du technicien (GET /auth/moi, opportuniste,
  /// absent si jamais recupere) et heure de la derniere synchro reussie
  /// (push + pull), pas persistee (reinitialisee a chaque ouverture d'ecran,
  /// qui relance de toute facon une synchro automatique).
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

  Widget _liste(List<Intervention> interventions, Set<String> idsAvecPhotosEnAttente) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: interventions.length,
      separatorBuilder: (_, _) => const Divider(height: 1, color: lineSoft),
      itemBuilder: (context, index) => _tuile(
        interventions[index],
        idsAvecPhotosEnAttente.contains(interventions[index].idServeur),
      ),
    );
  }

  Widget _tuile(Intervention intervention, bool aDesPhotosEnAttente) {
    final couleurMarqueur = intervention.statut == StatutIntervention.planifiee
        ? warning
        : success;
    final clotureSynchronisee = intervention.statutSync == StatutSync.confirme;
    final synchronisee = clotureSynchronisee && !aDesPhotosEnAttente;
    final etiquetteSynchro = !clotureSynchronisee
        ? 'À synchroniser'
        : (aDesPhotosEnAttente ? 'Photos à synchroniser' : 'Synchronisée');

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              DetailInterventionScreen(idServeur: intervention.idServeur),
        ),
      ),
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
                        '#${referenceCourte(intervention.idServeur)}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: textWeak,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        etiquetteSynchro,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: synchronisee ? textWeak : warning,
                        ),
                      ),
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
