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
/// reagir la liste. Encore absents (dependent de capacites non construites) :
/// bandeau hors ligne, "Synchronise il y a X min" et nom du technicien
/// (necessiteraient GET /auth/moi, explicitement opportuniste).
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

  @override
  void initState() {
    super.initState();
    // setState ne doit pas etre appele de facon synchrone pendant initState :
    // on attend le premier frame (addPostFrameCallback) avant de lancer la
    // synchro, qui met _synchronisationEnCours a jour via setState.
    WidgetsBinding.instance.addPostFrameCallback((_) => _synchroniser());

    _abonnementConnectivite = Connectivity().onConnectivityChanged.listen(
      _surChangementConnectivite,
    );
    WidgetsBinding.instance.addObserver(this);
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
  }

  Future<void> _synchroniser() async {
    if (_synchronisationEnCours) return;
    setState(() => _synchronisationEnCours = true);
    try {
      final conflits = await ref.read(syncServiceProvider).synchroniser();
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
          data: (toutes) => _corps(toutes),
        ),
      ),
    );
  }

  Widget _corps(List<Intervention> toutes) {
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
        _onglets(toutes.length, planifiees.length, realisees.length),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _synchroniser,
            child: affichees.isEmpty ? _etatVide() : _liste(affichees),
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

  Widget _liste(List<Intervention> interventions) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: interventions.length,
      separatorBuilder: (_, _) => const Divider(height: 1, color: lineSoft),
      itemBuilder: (context, index) => _tuile(interventions[index]),
    );
  }

  Widget _tuile(Intervention intervention) {
    final couleurMarqueur = intervention.statut == StatutIntervention.planifiee
        ? warning
        : success;
    final synchronisee = intervention.statutSync == StatutSync.confirme;

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
                        synchronisee ? 'Synchronisée' : 'À synchroniser',
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
