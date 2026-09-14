import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sim_interventions/data/local_db.dart';
import 'package:sim_interventions/models/enums.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  InterventionsCompanion interventionExemple({String idServeur = 'i-1'}) {
    final maintenant = DateTime(2026, 9, 12, 9);
    return InterventionsCompanion.insert(
      idServeur: idServeur,
      nomClient: 'Hotel Ivoire',
      adresse: 'Boulevard de Marseille, Cocody',
      telephone1: '0102030405',
      datePrevue: maintenant,
      technicienId: 'tech-1',
      creeParId: 'directeur-1',
      statut: StatutIntervention.planifiee,
      creeLe: maintenant,
      misAJourLe: maintenant,
      statutSync: StatutSync.confirme,
    );
  }

  test('insere une intervention puis la relit par idServeur', () async {
    await db.interventionDao.upsert(interventionExemple());

    final relue = await db.interventionDao.parId('i-1');

    expect(relue, isNotNull);
    expect(relue!.nomClient, 'Hotel Ivoire');
    expect(relue.statut, StatutIntervention.planifiee);
    expect(relue.statutSync, StatutSync.confirme);
  });

  test('upsert met a jour une intervention existante sans dupliquer la ligne', () async {
    await db.interventionDao.upsert(interventionExemple());
    await db.interventionDao.upsert(
      interventionExemple().copyWith(nomClient: const Value('Hotel Ivoire (corrige)')),
    );

    final toutes = await db.interventionDao.watchToutes().first;

    expect(toutes, hasLength(1));
    expect(toutes.single.nomClient, 'Hotel Ivoire (corrige)');
  });

  test('ajoute une photo liee a une intervention et la relit', () async {
    await db.interventionDao.upsert(interventionExemple());

    final idLocal = await db.photoDao.ajouter(PhotosCompanion.insert(
      interventionIdLocal: 'i-1',
      categorie: CategoriePhoto.avant,
      cheminLocal: '/donnees/photo1.jpg',
      statutSync: StatutSync.local,
    ));

    final photos = await db.photoDao.watchPourIntervention('i-1').first;

    expect(photos, hasLength(1));
    expect(photos.single.idLocal, idLocal);
    expect(photos.single.categorie, CategoriePhoto.avant);
  });

  test('supprime une photo par son id local', () async {
    await db.interventionDao.upsert(interventionExemple());
    final idLocal = await db.photoDao.ajouter(PhotosCompanion.insert(
      interventionIdLocal: 'i-1',
      categorie: CategoriePhoto.apres,
      cheminLocal: '/donnees/photo2.jpg',
      statutSync: StatutSync.local,
    ));

    await db.photoDao.supprimer(idLocal);

    final photos = await db.photoDao.watchPourIntervention('i-1').first;
    expect(photos, isEmpty);
  });

  test('listerAPousser renvoie les clotures locales, pas les saisies en cours', () async {
    await db.interventionDao.upsert(interventionExemple(idServeur: 'i-cloturee').copyWith(
      statut: const Value(StatutIntervention.realisee),
      statutSync: const Value(StatutSync.local),
      dateRealisation: Value(DateTime(2026, 9, 14, 15)),
    ));
    await db.interventionDao.upsert(interventionExemple(idServeur: 'i-en-cours').copyWith(
      statutSync: const Value(StatutSync.local),
    ));
    await db.interventionDao.upsert(interventionExemple(idServeur: 'i-confirmee').copyWith(
      statut: const Value(StatutIntervention.realisee),
      statutSync: const Value(StatutSync.confirme),
    ));

    final aPousser = await db.interventionDao.listerAPousser();

    expect(aPousser.map((i) => i.idServeur), ['i-cloturee']);
  });

  test('marquerConfirmee passe le statutSync a confirme', () async {
    await db.interventionDao.upsert(interventionExemple().copyWith(
      statut: const Value(StatutIntervention.realisee),
      statutSync: const Value(StatutSync.local),
    ));

    await db.interventionDao.marquerConfirmee('i-1');

    final intervention = await db.interventionDao.parId('i-1');
    expect(intervention!.statutSync, StatutSync.confirme);
  });

  test('photoDao.listerAPousser renvoie uniquement les photos locales', () async {
    await db.interventionDao.upsert(interventionExemple());
    await db.photoDao.ajouter(PhotosCompanion.insert(
      interventionIdLocal: 'i-1',
      categorie: CategoriePhoto.avant,
      cheminLocal: '/donnees/locale.jpg',
      statutSync: StatutSync.local,
    ));
    await db.photoDao.ajouter(PhotosCompanion.insert(
      interventionIdLocal: 'i-1',
      categorie: CategoriePhoto.apres,
      cheminLocal: '/donnees/confirmee.jpg',
      statutSync: StatutSync.confirme,
    ));

    final aPousser = await db.photoDao.listerAPousser();

    expect(aPousser.map((p) => p.cheminLocal), ['/donnees/locale.jpg']);
  });

  test('photoDao.marquerConfirmee enregistre l idServeur et passe a confirme', () async {
    await db.interventionDao.upsert(interventionExemple());
    final idLocal = await db.photoDao.ajouter(PhotosCompanion.insert(
      interventionIdLocal: 'i-1',
      categorie: CategoriePhoto.avant,
      cheminLocal: '/donnees/locale.jpg',
      statutSync: StatutSync.local,
    ));

    await db.photoDao.marquerConfirmee(idLocal, 'p-serveur-1');

    final photos = await db.photoDao.listerPourIntervention('i-1');
    expect(photos.single.idServeur, 'p-serveur-1');
    expect(photos.single.statutSync, StatutSync.confirme);
  });
}
