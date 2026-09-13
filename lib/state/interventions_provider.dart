import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_db.dart';
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

/// US2.11 (volet pull). Meme instance tant que databaseProvider ne change pas.
final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  return SyncService(interventionDao: db.interventionDao);
});
