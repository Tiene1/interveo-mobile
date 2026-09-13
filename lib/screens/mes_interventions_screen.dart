import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_db.dart';
import '../models/enums.dart';
import '../state/interventions_provider.dart';
import '../utils/date.dart';
import '../utils/reference.dart';

const _inkColor = Color(0xFF0F172A);
const _textSoft = Color(0xFF475569);
const _textWeak = Color(0xFF94A3B8);
const _warning = Color(0xFFD97706);
const _success = Color(0xFF16A34A);
const _line = Color(0xFFE2E8F0);
const _lineSoft = Color(0xFFEEF2F6);

enum _Onglet { toutes, planifiees, realisees }

/// Ecran "Mes interventions" (US2.1). Lit uniquement la base locale, jamais
/// le reseau : la synchronisation qui peuple cette liste est un ticket a
/// part (sync_service.dart). Le bouton de synchro, le bandeau hors ligne et
/// le tirer-pour-rafraichir de la maquette sont volontairement absents tant
/// que ce service n'existe pas (ils seraient decoratifs, pas fonctionnels).
class MesInterventionsScreen extends ConsumerStatefulWidget {
  const MesInterventionsScreen({super.key});

  @override
  ConsumerState<MesInterventionsScreen> createState() => _MesInterventionsScreenState();
}

class _MesInterventionsScreenState extends ConsumerState<MesInterventionsScreen> {
  _Onglet _onglet = _Onglet.toutes;

  @override
  Widget build(BuildContext context) {
    final interventions = ref.watch(interventionsAttribueesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9), // --paper
      body: SafeArea(
        child: interventions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (erreur, _) => Center(
            child: Text('Erreur de lecture locale : $erreur', style: const TextStyle(color: Color(0xFFDC2626))),
          ),
          data: (toutes) => _corps(toutes),
        ),
      ),
    );
  }

  Widget _corps(List<Intervention> toutes) {
    final planifiees = toutes.where((i) => i.statut == StatutIntervention.planifiee).toList();
    final realisees = toutes.where((i) => i.statut == StatutIntervention.realisee).toList();
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
          child: affichees.isEmpty ? _etatVide() : _liste(affichees),
        ),
      ],
    );
  }

  Widget _entete() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Text.rich(
        TextSpan(
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w400, color: _inkColor, letterSpacing: -0.8),
          children: [
            TextSpan(text: 'Mes '),
            TextSpan(text: 'interventions', style: TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  Widget _onglets(int nbToutes, int nbPlanifiees, int nbRealisees) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _line))),
      child: Row(
        children: [
          _ongletBouton(label: 'Toutes', nombre: nbToutes, valeur: _Onglet.toutes),
          const SizedBox(width: 16),
          _ongletBouton(label: 'Planifiées', nombre: nbPlanifiees, valeur: _Onglet.planifiees),
          const SizedBox(width: 16),
          _ongletBouton(label: 'Réalisées', nombre: nbRealisees, valeur: _Onglet.realisees),
        ],
      ),
    );
  }

  Widget _ongletBouton({required String label, required int nombre, required _Onglet valeur}) {
    final actif = _onglet == valeur;
    return InkWell(
      onTap: () => setState(() => _onglet = valeur),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: actif ? _inkColor : Colors.transparent, width: 2)),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: actif ? FontWeight.w600 : FontWeight.w500,
                color: actif ? _inkColor : _textWeak,
              ),
            ),
            const SizedBox(width: 6),
            Text('$nombre', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: actif ? _inkColor : _textWeak)),
          ],
        ),
      ),
    );
  }

  Widget _liste(List<Intervention> interventions) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: interventions.length,
      separatorBuilder: (_, _) => const Divider(height: 1, color: _lineSoft),
      itemBuilder: (context, index) => _tuile(interventions[index]),
    );
  }

  Widget _tuile(Intervention intervention) {
    final couleurMarqueur = intervention.statut == StatutIntervention.planifiee ? _warning : _success;
    final synchronisee = intervention.statutSync == StatutSync.confirme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 3, height: 56, margin: const EdgeInsets.only(right: 12), color: couleurMarqueur),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '#${referenceCourte(intervention.idServeur)}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _textWeak, fontFamily: 'monospace'),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      synchronisee ? 'Synchronisée' : 'À synchroniser',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: synchronisee ? _textWeak : _warning),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  intervention.nomClient,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _inkColor),
                ),
                const SizedBox(height: 2),
                Text(intervention.adresse, style: const TextStyle(fontSize: 12, color: _textSoft)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatDateHeure(intervention.datePrevue),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _inkColor, fontFamily: 'monospace'),
                    ),
                    Row(
                      children: [
                        Container(width: 6, height: 6, decoration: BoxDecoration(color: couleurMarqueur, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(
                          intervention.statut == StatutIntervention.planifiee ? 'Planifiée' : 'Réalisée',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _inkColor),
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
    );
  }

  Widget _etatVide() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 24, height: 1, color: _inkColor),
          const SizedBox(height: 12),
          const Text('AUCUNE TÂCHE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _textSoft, letterSpacing: 1.6)),
          const SizedBox(height: 8),
          const Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, color: _inkColor, height: 1.15),
              children: [
                TextSpan(text: 'Aucune intervention '),
                TextSpan(text: 'attribuée.', style: TextStyle(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Vous n'avez actuellement aucune intervention assignée.",
            style: TextStyle(fontSize: 13, color: _textSoft, height: 1.5),
          ),
        ],
      ),
    );
  }
}
