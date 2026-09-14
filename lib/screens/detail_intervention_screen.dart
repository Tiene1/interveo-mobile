import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/local_db.dart';
import '../models/enums.dart';
import '../state/interventions_provider.dart';
import '../theme/design_tokens.dart';
import '../utils/date.dart';
import '../utils/maps.dart';
import '../utils/text.dart';
import 'completer_intervention_screen.dart';

/// Ecran de detail (US2.2 : motif signale/non renseigne, date et heure
/// prevues ; US2.3 : adresse, telephones cliquables, itineraire). Lit
/// uniquement la base locale via un flux reactif par id.
class DetailInterventionScreen extends ConsumerWidget {
  const DetailInterventionScreen({super.key, required this.idServeur});

  final String idServeur;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intervention = ref.watch(interventionParIdProvider(idServeur));
    final data = intervention.asData?.value;

    return Scaffold(
      backgroundColor: paper,
      body: SafeArea(
        child: Column(
          children: [
            _appBar(context),
            Expanded(
              child: intervention.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (erreur, _) => Center(
                  child: Text(
                    'Erreur de lecture locale : $erreur',
                    style: const TextStyle(color: danger),
                  ),
                ),
                data: (data) => data == null
                    ? const Center(child: Text('Intervention introuvable.'))
                    : _corps(context, data),
              ),
            ),
            if (data != null) _barreBas(context, data),
          ],
        ),
      ),
    );
  }

  Widget _barreBas(BuildContext context, Intervention data) {
    final estRealisee = data.statut == StatutIntervention.realisee;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: line)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: estRealisee
            ? OutlinedButton(
                onPressed: () => _ouvrirCompleter(context, data.idServeur),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: lineStrong),
                  foregroundColor: inkColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Voir le compte rendu'),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              )
            : ElevatedButton(
                onPressed: () => _ouvrirCompleter(context, data.idServeur),
                style: ElevatedButton.styleFrom(
                  backgroundColor: inkColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Compléter l'intervention"),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
      ),
    );
  }

  void _ouvrirCompleter(BuildContext context, String idServeur) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CompleterInterventionScreen(idServeur: idServeur),
      ),
    );
  }

  Widget _appBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: line)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: inkColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _corps(BuildContext context, Intervention data) {
    final estRealisee = data.statut == StatutIntervention.realisee;
    final couleurMarqueur = estRealisee ? success : warning;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _docHead(data, estRealisee, couleurMarqueur),
          _section(
            label: 'Rendez-vous',
            child: Text(
              formatDateHeureComplete(data.datePrevue),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: inkColor,
                fontFamily: 'monospace',
              ),
            ),
          ),
          _section(
            label: 'Motif signalé',
            child: Text(
              nonRenseigne(data.motifSignale),
              style: TextStyle(
                fontSize: 15,
                height: 1.55,
                color:
                    data.motifSignale == null ||
                        data.motifSignale!.trim().isEmpty
                    ? textWeak
                    : inkColor,
                fontStyle:
                    data.motifSignale == null ||
                        data.motifSignale!.trim().isEmpty
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
            ),
          ),
          _sectionLieu(data),
        ],
      ),
    );
  }

  Widget _docHead(Intervention data, bool estRealisee, Color couleurMarqueur) {
    final kicker = estRealisee && data.dateRealisation != null
        ? 'Clôturée · ${formatDateHeureComplete(data.dateRealisation!)}'
        : 'Rendez-vous · ${formatDate(data.datePrevue)}';

    return Container(
      padding: const EdgeInsets.only(bottom: 20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: inkColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 16, height: 1, color: inkColor),
              const SizedBox(width: 8),
              Text(
                kicker,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: textSoft,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data.nomClient,
            style: const TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 32,
              fontWeight: FontWeight.w400,
              color: inkColor,
              letterSpacing: -1,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: couleurMarqueur,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                estRealisee ? 'Réalisée' : 'Planifiée',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: inkColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _section({required String label, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: lineSoft)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textWeak,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _sectionLieu(Intervention data) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: lineSoft)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LIEU',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textWeak,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: textWeak,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.adresse,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: inkColor,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _actionBouton(
            icone: Icons.call_outlined,
            titre: 'Appeler',
            sousTitre: data.telephone1,
            onTap: () => _ouvrir('tel:${data.telephone1}'),
          ),
          if (data.telephone2 != null &&
              data.telephone2!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _actionBouton(
              icone: Icons.call_outlined,
              titre: 'Appeler le 2',
              sousTitre: data.telephone2!,
              onTap: () => _ouvrir('tel:${data.telephone2}'),
            ),
          ],
          if (data.geolocalisation != null &&
              data.geolocalisation!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _actionBouton(
              icone: Icons.navigation_outlined,
              titre: 'Itinéraire Google Maps',
              sousTitre: "Ouvrir dans l'application",
              onTap: () => _ouvrir(lienItineraire(data.geolocalisation!)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionBouton({
    required IconData icone,
    required String titre,
    required String sousTitre,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: line),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(icone, size: 18, color: textSoft),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titre,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: inkColor,
                      ),
                    ),
                    Text(
                      sousTitre,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textSoft,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 16, color: textWeak),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _ouvrir(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
