import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../data/dao/intervention_dao.dart';
import '../data/local_db.dart';
import '../models/enums.dart';
import '../services/sync_service.dart';
import '../state/interventions_provider.dart';
import '../theme/design_tokens.dart';
import '../utils/date.dart';

const _maxPhotosParCategorie = 2;

/// Ecran Completer l'intervention (US2.5, US2.6, US2.7, US2.8, US2.9,
/// US2.10). La saisie et la cloture marquent la ligne LOCAL ; l'envoi au
/// serveur (push des clotures et des photos) est fait par sync_service.dart,
/// pas ici.
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
  late final InterventionDao _interventionDao;

  /// Photos dont le fichier local a ete libere (intervention Realisee, cf.
  /// SyncService._viderCachePhotosConfirmees) : telechargees automatiquement
  /// depuis le serveur des l'affichage, mises en cache ici par idServeur
  /// pour ne pas relancer un telechargement a chaque rebuild (l'ecran en
  /// declenche beaucoup, ex. a chaque frappe dans les champs de saisie).
  final Map<String, Future<Uint8List>> _cachePhotosReseau = {};

  Future<Uint8List> _futurePhotoReseau(String idServeur) {
    return _cachePhotosReseau.putIfAbsent(
      idServeur,
      () => ref.read(syncServiceProvider).telechargerPhoto(idServeur),
    );
  }

  @override
  void initState() {
    super.initState();
    // Capture au lieu d'un ref.read() dans dispose() : Riverpod interdit
    // d'utiliser ref une fois le widget en cours de demontage ("Using ref
    // when a widget is about to or has been unmounted is unsafe").
    _interventionDao = ref.read(databaseProvider).interventionDao;
    _problemeCtrl.addListener(() => setState(() {}));
    _travauxCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _flushSaisieEnAttente();
    _problemeCtrl.dispose();
    _travauxCtrl.dispose();
    super.dispose();
  }

  /// Si moins de 400 ms se sont ecoulees depuis la derniere frappe, l'anti-
  /// rebond n'a pas encore ecrit ce dernier fragment : on le force ici.
  /// Utilisee a la fois par [dispose] (fire-and-forget, synchrone, sans
  /// risque : `AppDatabase` est un singleton garde par `databaseProvider`,
  /// jamais dispose avec cet ecran) et par [_demanderCloture] (`await`ee,
  /// pour garantir que `problemeConstate`/`travauxRealises` sont bien en
  /// base avant de cloturer - cf. bug reel diagnostique le 2026-09-14 :
  /// une cloture juste apres une frappe rapide pouvait passer `statut` a
  /// REALISEE avec ces deux champs encore vides en base).
  Future<void> _flushSaisieEnAttente() async {
    final ecritures = <Future<void>>[];
    if (_debounceProbleme?.isActive ?? false) {
      _debounceProbleme!.cancel();
      ecritures.add(_interventionDao.mettreAJourSaisie(
        widget.idServeur,
        problemeConstate: Value(_problemeCtrl.text),
      ));
    }
    if (_debounceTravaux?.isActive ?? false) {
      _debounceTravaux!.cancel();
      ecritures.add(_interventionDao.mettreAJourSaisie(
        widget.idServeur,
        travauxRealises: Value(_travauxCtrl.text),
      ));
    }
    await Future.wait(ecritures);
  }

  /// Appelee inconditionnellement a chaque build (par [_controleursInitialises],
  /// une seule fois par instance d'ecran, meme si l'intervention est deja
  /// cloturee). Bug reel corrige le 2026-09-14 : l'appel etait auparavant
  /// garde par `if (!estCloturee)`, donc jamais declenche en ouvrant
  /// directement le detail d'une intervention deja realisee - les
  /// controleurs restaient vides (valeur par defaut de TextEditingController)
  /// alors que problemeConstate/travauxRealises etaient bien en base, et le
  /// bandeau succes en lecture seule les affiche via ces memes controleurs
  /// (cf. _corps, _champTexte(controller: _problemeCtrl, ...)).
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

    await _flushSaisieEnAttente();
    final dao = ref.read(databaseProvider).interventionDao;
    await dao.cloturer(widget.idServeur, dateRealisation: DateTime.now());

    // Capture avant toute navigation : ref devient invalide une fois le
    // widget demonte (piege Riverpod deja documente sur ce projet - "Using
    // ref when a widget is about to or has been unmounted is unsafe").
    final syncService = ref.read(syncServiceProvider);

    // Retour direct a "Mes interventions" (US demandee par Cedric le
    // 2026-09-14 : le technicien ne doit pas rester sur l'ecran ni repasser
    // par le detail). popUntil(isFirst) plutot que deux pop() : robuste a la
    // profondeur de la pile (Detail -> Completer aujourd'hui), pas fragile
    // si un ecran intermediaire change plus tard.
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }

    // Tentative de synchro immediate (push + pull), opportuniste : si
    // l'appareil est deja connecte, la cloture part sans attendre un appui
    // manuel sur le bouton de synchro (constat reel Cedric le 2026-09-14).
    // Declenchee apres la navigation, sans l'attendre : ne doit jamais
    // retarder le retour a la liste. Erreur ignoree (hors ligne, serveur
    // injoignable...) : "Mes interventions" reprend le relais via ses
    // propres declencheurs.
    unawaited(_synchroniserSansAttendre(syncService));
  }

  Future<void> _synchroniserSansAttendre(SyncService service) async {
    try {
      await service.synchroniser();
    } catch (_) {
      // Volontairement silencieux, cf. commentaire dans _demanderCloture().
    }
  }

  @override
  Widget build(BuildContext context) {
    final intervention = ref.watch(interventionParIdProvider(widget.idServeur));
    final photos =
        ref.watch(photosParInterventionProvider(widget.idServeur)).asData?.value ??
        const <Photo>[];

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
            _initialiserControleurs(data);
            return Column(
              children: [
                _appBar(estCloturee),
                if (estCloturee) _bandeauSucces(data, photos),
                Expanded(child: _corps(data, estCloturee, photos)),
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
                  estCloturee ? 'Compte rendu' : 'Compléter',
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

  Widget _bandeauSucces(Intervention data, List<Photo> photos) {
    final clotureSynchronisee = data.statutSync == StatutSync.confirme;
    final aDesPhotosEnConflit = photos.any((p) => p.statutSync == StatutSync.conflit);
    final photosSynchronisees =
        photos.every((p) => p.statutSync == StatutSync.confirme);
    final String etiquette;
    final Color couleurEtiquette;
    if (!clotureSynchronisee) {
      etiquette = 'À SYNCHRONISER';
      couleurEtiquette = success;
    } else if (aDesPhotosEnConflit) {
      etiquette = 'PHOTO EN ÉCHEC';
      couleurEtiquette = danger;
    } else if (!photosSynchronisees) {
      etiquette = 'PHOTOS À SYNCHRONISER';
      couleurEtiquette = success;
    } else {
      etiquette = 'SYNCHRONISÉE';
      couleurEtiquette = success;
    }
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
                etiquette,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: couleurEtiquette,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _corps(Intervention data, bool estCloturee, List<Photo> photos) {
    final photosAvant =
        photos.where((p) => p.categorie == CategoriePhoto.avant).toList();
    final photosApres =
        photos.where((p) => p.categorie == CategoriePhoto.apres).toList();
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
          const SizedBox(height: 24),
          _sectionPhotos(
            label: 'Photos avant',
            categorie: CategoriePhoto.avant,
            photos: photosAvant,
            lectureSeule: estCloturee,
          ),
          const SizedBox(height: 24),
          _sectionPhotos(
            label: 'Photos après',
            categorie: CategoriePhoto.apres,
            photos: photosApres,
            lectureSeule: estCloturee,
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
              fontFamily: 'Fraunces',
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

  Widget _sectionPhotos({
    required String label,
    required CategoriePhoto categorie,
    required List<Photo> photos,
    required bool lectureSeule,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            children: [
              TextSpan(
                text: '   ${photos.length} / $_maxPhotosParCategorie',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                  color: textWeak,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < photos.length; i++) ...[
              _miniaturePhoto(photos[i], i + 1, lectureSeule),
              const SizedBox(width: 10),
            ],
            if (!lectureSeule && photos.length < _maxPhotosParCategorie)
              _boutonAjouterPhoto(categorie),
          ],
        ),
      ],
    );
  }

  /// Fichier local si present (saisie en cours), sinon telechargement
  /// automatique depuis le serveur (intervention Realisee, cache local
  /// libere) : jamais une action manuelle du technicien.
  Widget _imagePhoto(Photo photo) {
    if (photo.cheminLocal != null) {
      return Image.file(
        File(photo.cheminLocal!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.image_outlined, color: textWeak),
      );
    }
    return FutureBuilder<Uint8List>(
      future: _futurePhotoReseau(photo.idServeur!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Icon(Icons.image_outlined, color: textWeak);
        }
        if (!snapshot.hasData) {
          return const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return Image.memory(
          snapshot.data!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.image_outlined, color: textWeak),
        );
      },
    );
  }

  Widget _miniaturePhoto(Photo photo, int numero, bool lectureSeule) {
    final etiquette = photo.categorie == CategoriePhoto.avant ? 'AVANT' : 'APRES';
    return Container(
      key: Key('photo-${photo.idLocal}'),
      width: 88,
      height: 88,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(2),
        color: const Color(0xFFF5F5F1), // --paper-soft
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _imagePhoto(photo),
          Positioned(
            left: 5,
            bottom: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: inkColor,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                '$etiquette · ${numero.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
          if (!lectureSeule)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                key: Key('supprimerPhoto-${photo.idLocal}'),
                onTap: () => _supprimerPhoto(photo),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xE60F172A), // rgba(--ink-1, .9)
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _boutonAjouterPhoto(CategoriePhoto categorie) {
    return GestureDetector(
      key: Key('ajouterPhoto-${categorie.name}'),
      onTap: () => _demanderSourcePhoto(categorie),
      child: CustomPaint(
        foregroundPainter: const _BordurePointillee(couleur: lineStrong),
        child: Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(2)),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt_outlined, size: 20, color: textSoft),
              SizedBox(height: 4),
              Text(
                'AJOUTER',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: textSoft,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _demanderSourcePhoto(CategoriePhoto categorie) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: paper,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: inkColor, width: 2),
        borderRadius: BorderRadius.vertical(top: Radius.zero),
      ),
      builder: (context) => const _ModaleSourcePhoto(),
    );
    if (source == null) return;

    final chemin = await ref.read(photoStockageServiceProvider).capturer(source);
    if (chemin == null) return;

    final dao = ref.read(databaseProvider).photoDao;
    await dao.ajouter(
      PhotosCompanion.insert(
        interventionIdLocal: widget.idServeur,
        categorie: categorie,
        cheminLocal: Value(chemin),
        statutSync: StatutSync.local,
      ),
    );
  }

  /// Uniquement disponible pendant la saisie (bouton absent en lecture
  /// seule) : `cheminLocal` est donc toujours renseigne ici, une photo
  /// affichee en lecture seule (cache libere) n'est jamais supprimable.
  Future<void> _supprimerPhoto(Photo photo) async {
    final dao = ref.read(databaseProvider).photoDao;
    await dao.supprimer(photo.idLocal);
    await ref.read(photoStockageServiceProvider).supprimerFichier(photo.cheminLocal!);
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
              fontFamily: 'Fraunces',
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

class _ModaleSourcePhoto extends StatelessWidget {
  const _ModaleSourcePhoto();

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
                'AJOUTER UNE PHOTO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: textSoft,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _option(
            context,
            cle: 'optionCamera',
            icone: Icons.camera_alt_outlined,
            libelle: 'Prendre une photo',
            source: ImageSource.camera,
          ),
          const SizedBox(height: 8),
          _option(
            context,
            cle: 'optionGalerie',
            icone: Icons.photo_library_outlined,
            libelle: 'Choisir dans la galerie',
            source: ImageSource.gallery,
          ),
        ],
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required String cle,
    required IconData icone,
    required String libelle,
    required ImageSource source,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        key: Key(cle),
        onPressed: () => Navigator.of(context).pop(source),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: line),
          foregroundColor: inkColor,
          alignment: Alignment.centerLeft,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        icon: Icon(icone, size: 18),
        label: Text(libelle),
      ),
    );
  }
}

/// Bordure en pointilles autour d'un rectangle a coins arrondis (Flutter n'a
/// pas d'equivalent au `border-style: dashed` du CSS). Fidele au bouton
/// "Ajouter" de M4 - Completer intervention.html.
class _BordurePointillee extends CustomPainter {
  const _BordurePointillee({required this.couleur});

  final Color couleur;

  static const _rayon = 2.0;
  static const _longueurTiret = 4.0;
  static const _espacement = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final contour = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(_rayon)));
    final peinture = Paint()
      ..color = couleur
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final metrique in contour.computeMetrics()) {
      var distance = 0.0;
      while (distance < metrique.length) {
        final fin = math.min(distance + _longueurTiret, metrique.length);
        canvas.drawPath(metrique.extractPath(distance, fin), peinture);
        distance = fin + _espacement;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BordurePointillee oldDelegate) =>
      couleur != oldDelegate.couleur;
}
