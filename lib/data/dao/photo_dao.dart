import 'package:drift/drift.dart';

import '../../models/enums.dart';
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

  /// Lecture ponctuelle (non reactive), utile pour verifier l'etat sans
  /// s'abonner a un flux (une nouvelle souscription .watch() programme un
  /// timer interne, cf. issue simolus3/drift#3323, qui ne resout qu'avec un
  /// pump() de test supplementaire).
  Future<List<Photo>> listerPourIntervention(String interventionIdLocal) {
    return (select(
      photos,
    )..where((p) => p.interventionIdLocal.equals(interventionIdLocal))).get();
  }

  Future<int> ajouter(PhotosCompanion photo) => into(photos).insert(photo);

  Future<void> supprimer(int idLocal) =>
      (delete(photos)..where((p) => p.idLocal.equals(idLocal))).go();

  /// US2.11 (volet push photos) : photos locales pretes a etre envoyees.
  Future<List<Photo>> listerAPousser() {
    return (select(
      photos,
    )..where((p) => p.statutSync.equalsValue(StatutSync.local))).get();
  }

  /// Photo confirmee par le serveur : idServeur recu + statutSync confirme.
  Future<void> marquerConfirmee(int idLocal, String idServeur) {
    return (update(photos)..where((p) => p.idLocal.equals(idLocal))).write(
      PhotosCompanion(
        idServeur: Value(idServeur),
        statutSync: const Value(StatutSync.confirme),
      ),
    );
  }
}
