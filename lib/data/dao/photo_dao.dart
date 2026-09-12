import 'package:drift/drift.dart';

import '../local_db.dart';

part 'photo_dao.g.dart';

/// Acces de base a la table Photos. L'envoi vers le serveur (upload
/// multipart) vit dans sync_service.dart, pas ici.
@DriftAccessor(tables: [Photos])
class PhotoDao extends DatabaseAccessor<AppDatabase> with _$PhotoDaoMixin {
  PhotoDao(super.db);

  Stream<List<Photo>> watchPourIntervention(String interventionIdLocal) {
    return (select(photos)
          ..where((p) => p.interventionIdLocal.equals(interventionIdLocal)))
        .watch();
  }

  Future<int> ajouter(PhotosCompanion photo) => into(photos).insert(photo);

  Future<void> supprimer(int idLocal) =>
      (delete(photos)..where((p) => p.idLocal.equals(idLocal))).go();
}
