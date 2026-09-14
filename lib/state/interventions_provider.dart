import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_db.dart';
import '../services/photo_stockage_service.dart';
import '../services/sync_service.dart';

/// Instance unique de la base locale pour toute l'app (Riverpod garde le
/// meme AppDatabase tant que le provider n'est pas dispose).
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// US2.1 : interventions attribuees (non annulees), triees par date prevue.
final interventionsAttribueesProvider = StreamProvider((ref) {
  final db = ref.watch(databaseProvider);
  return db.interventionDao.watchAttribuees();
});

/// US2.2/US2.3 : detail reactif d'une intervention par idServeur.
final interventionParIdProvider = StreamProvider.family((ref, String idServeur) {
  final db = ref.watch(databaseProvider);
  return db.interventionDao.watchParId(idServeur);
});

/// US2.11. Meme instance tant que databaseProvider ne change pas.
final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  return SyncService(interventionDao: db.interventionDao, photoDao: db.photoDao);
});

/// US2.7/US2.8 : photos (avant et apres confondues, filtrees cote ecran).
final photosParInterventionProvider = StreamProvider.family((ref, String idServeur) {
  final db = ref.watch(databaseProvider);
  return db.photoDao.watchPourIntervention(idServeur);
});

/// Ids serveur des interventions ayant au moins une photo pas encore
/// confirmee par le serveur : une intervention peut etre elle-meme
/// synchronisee (cloture confirmee) tout en ayant des photos en attente,
/// le badge de liste doit le distinguer (voir docs/architecture.md).
final interventionsAvecPhotosEnAttenteProvider = StreamProvider<Set<String>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.photoDao
      .watchNonConfirmees()
      .map((photos) => photos.map((p) => p.interventionIdLocal).toSet());
});

/// Instance unique, testable via overrideWithValue (voir FakeTokenStorage
/// pour le meme principe).
final photoStockageServiceProvider = Provider<PhotoStockageService>((ref) {
  return PhotoStockageService();
});
