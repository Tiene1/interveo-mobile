import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_db.dart';
import '../models/enums.dart';
import '../state/interventions_provider.dart';
import '../theme/design_tokens.dart';
import '../utils/date.dart';
import '../utils/reference.dart';

/// Ecran Completer l'intervention (US2.5, US2.6, US2.9, US2.10). Les photos
/// avant/apres (US2.7, US2.8) sont un ticket a part : capture appareil
/// photo/galerie, stockage fichier, DAO deja pret (photo_dao.dart) mais pas
/// encore branche a un ecran.
class CompleterInterventionScreen extends ConsumerStatefulWidget {
  const CompleterInterventionScreen({super.key, required this.idServeur});

  final String idServeur;

  @override
  ConsumerState<CompleterInterventionScreen> createState() =>
      _CompleterInterventionScreenState();
}

class _CompleterInterventionScreenState
    extends ConsumerState<CompleterInterventionScreen> {
  final _problemeCtrl = TextEditingController();
  final _travauxCtrl = TextEditingController();
  bool _controleursInitialises = false;
  Timer? _debounceProbleme;
  Timer? _debounceTravaux;
  bool _enregistreRecemment = false;

  @override
  void initState() {
    super.initState();
    _problemeCtrl.addListener(() => setState(() {}));
    _travauxCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _debounceProbleme?.cancel();
    _debounceTravaux?.cancel();
    _problemeCtrl.dispose();
    _travauxCtrl.dispose();
    super.dispose();
  }

  void _initialiserControleurs(Intervention data) {
    if (_controleursInitialises) return;
    _controleursInitialises = true;
    _problemeCtrl.text = data.problemeConstate ?? '';
    _travauxCtrl.text = data.travauxRealises ?? '';
  }

  void _onChangeProbleme(String valeur) {
    _debounceProbleme?.cancel();
    _debounceProbleme = Timer(const Duration(milliseconds: 400), () {
      _enregistrer(problemeConstate: Value(valeur));
    });
  }

  void _onChangeTravaux(String valeur) {
    _debounceTravaux?.cancel();
    _debounceTravaux = Timer(const Duration(milliseconds: 400), () {
      _enregistrer(travauxRealises: Value(valeur));
    });
  }

  Future<void> _enregistrer({
    Value<String?> problemeConstate = const Value.absent(),
    Value<String?> travauxRealises = const Value.absent(),
  }) async {
    final dao = ref.read(databaseProvider).interventionDao;
    await dao.mettreAJourSaisie(
      widget.idServeur,
      problemeConstate: problemeConstate,
      travauxRealises: travauxRealises,
    );
    if (mounted) setState(() => _enregistreRecemment = true);
  }

  bool get _peutCloturer =>
      _problemeCtrl.text.trim().isNotEmpty &&
      _travauxCtrl.text.trim().isNotEmpty;

  Future<void> _demanderCloture() async {
    final confirme = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: paper,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: inkColor, width: 2),
        borderRadius: BorderRadius.vertical(top: Radius.zero),
      ),
      builder: (context) => _ModaleConfirmationCloture(),
    );
    if (confirme != true) return;

    final dao = ref.read(databaseProvider).interventionDao;
    await dao.cloturer(widget.idServeur, dateRealisation: DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final intervention = ref.watch(interventionParIdProvider(widget.idServeur));

    return Scaffold(
      backgroundColor: paper,
      body: SafeArea(
        child: intervention.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (erreur, _) => Center(
            child: Text(
              'Erreur de lecture locale : $erreur',
              style: const TextStyle(color: danger),
            ),
          ),
          data: (data) {
            if (data == null) {
              return const Center(child: Text('Intervention introuvable.'));
            }
            final estCloturee = data.statut == StatutIntervention.realisee;
            if (!estCloturee) _initialiserControleurs(data);
            return Column(
              children: [
                _appBar(estCloturee),
                if (estCloturee) _bandeauSucces(data),
                Expanded(child: _corps(data, estCloturee)),
                if (!estCloturee) _barreBas(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _appBar(bool estCloturee) {
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
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${referenceCourte(widget.idServeur)} · ${estCloturee ? 'Compte rendu' : 'Compléter'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: inkColor,
                    fontFamily: 'monospace',
                    letterSpacing: 0.2,
                  ),
                ),
                if (!estCloturee)
                  Row(
                    children: [
                      Icon(
                        _enregistreRecemment
                            ? Icons.check
                            : Icons.cloud_outlined,
                        size: 10,
                        color: success,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _enregistreRecemment
                            ? "Enregistré à l'instant"
                            : 'Enregistrement automatique',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: textWeak,
                        ),
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

  Widget _bandeauSucces(Intervention data) {
    final synchronisee = data.statutSync == StatutSync.confirme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: const Color(0xFFDCFCE7), // --success-bg
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: success),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Réalisée le ${formatDateHeureComplete(data.dateRealisation ?? DateTime.now())}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: success,
                ),
              ),
              Text(
                synchronisee ? 'SYNCHRONISÉE' : 'À SYNCHRONISER',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: success,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _corps(Intervention data, bool estCloturee) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _entete(data),
          const SizedBox(height: 24),
          _champTexte(
            label: 'Problème constaté',
            controller: _problemeCtrl,
            lectureSeule: estCloturee,
            surChangement: _onChangeProbleme,
            texteVide: 'Décrivez le problème constaté sur place…',
          ),
          const SizedBox(height: 24),
          _champTexte(
            label: 'Travaux réalisés',
            controller: _travauxCtrl,
            lectureSeule: estCloturee,
            surChangement: _onChangeTravaux,
            texteVide: 'Décrivez les travaux effectués…',
          ),
        ],
      ),
    );
  }

  Widget _entete(Intervention data) {
    return Container(
      padding: const EdgeInsets.only(bottom: 14),
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
                'Rendez-vous · ${formatDateHeureComplete(data.datePrevue)}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: textSoft,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data.nomClient,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w400,
              color: inkColor,
              letterSpacing: -0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _champTexte({
    required String label,
    required TextEditingController controller,
    required bool lectureSeule,
    required ValueChanged<String> surChangement,
    required String texteVide,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text.rich(
              TextSpan(
                text: label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: textSoft,
                  letterSpacing: 1.6,
                ),
                children: lectureSeule
                    ? null
                    : const [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(color: danger),
                        ),
                      ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(lectureSeule ? 12 : 0),
          decoration: BoxDecoration(
            color: lectureSeule
                ? const Color(0xFFF5F5F1)
                : null, // --paper-soft
            borderRadius: lectureSeule ? BorderRadius.circular(2) : null,
            border: lectureSeule
                ? null
                : const Border(bottom: BorderSide(color: lineStrong)),
          ),
          child: TextField(
            controller: controller,
            readOnly: lectureSeule,
            onChanged: surChangement,
            minLines: 4,
            maxLines: null,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: inkColor,
              height: 1.5,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: texteVide,
              hintStyle: const TextStyle(
                color: textWeak,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _barreBas() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: line)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              key: const Key('boutonCloturer'),
              onPressed: _peutCloturer ? _demanderCloture : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: inkColor,
                disabledBackgroundColor: textWeak,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Clôturer'),
                  SizedBox(width: 10),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ),
          if (!_peutCloturer) ...[
            const SizedBox(height: 8),
            const Text(
              'Renseignez le problème et les travaux pour clôturer',
              style: TextStyle(fontSize: 11, color: textWeak),
            ),
          ],
        ],
      ),
    );
  }
}

class _ModaleConfirmationCloture extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 3,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: lineStrong,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Row(
            children: [
              Container(width: 16, height: 1, color: inkColor),
              const SizedBox(width: 10),
              const Text(
                'ACTION DÉFINITIVE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: textSoft,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Clôturer cette intervention ?",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: inkColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vous ne pourrez plus la modifier après clôture. Assurez-vous que le compte rendu est complet.',
            style: TextStyle(fontSize: 13, color: textSoft, height: 1.55),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(foregroundColor: textSoft),
                    child: const Text('Retour'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    key: const Key('boutonConfirmerCloture'),
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: inkColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text('Clôturer'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
