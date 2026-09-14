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

  /// Le serveur a definitivement refuse cette photo (409 : categorie deja
  /// pleine cote serveur). Passe a `conflit` : exclue de [listerAPousser],
  /// donc plus jamais reessayee automatiquement.
  Future<void> marquerEnConflit(int idLocal) {
    return (update(photos)..where((p) => p.idLocal.equals(idLocal)))
        .write(const PhotosCompanion(statutSync: Value(StatutSync.conflit)));
  }

  /// Photos pas encore confirmees par le serveur (LOCAL, ENVOYE ou CONFLIT),
  /// toutes interventions confondues. Sert a signaler qu'une intervention par
  /// ailleurs synchronisee a quand meme des photos en attente ou en echec (le
  /// badge de l'intervention ne suffit pas a lui seul, cf. docs/architecture.md).
  /// Voir [watchEnConflit] pour distinguer specifiquement les echecs.
  Stream<List<Photo>> watchNonConfirmees() {
    return (select(
      photos,
    )..where((p) => p.statutSync.equalsValue(StatutSync.confirme).not())).watch();
  }

  /// Photos definitivement en echec (categorie pleine cote serveur), toutes
  /// interventions confondues. Contrairement a `local`, ne se resorbe jamais
  /// tout seul : le technicien doit supprimer la photo localement.
  Stream<List<Photo>> watchEnConflit() {
    return (select(
      photos,
    )..where((p) => p.statutSync.equalsValue(StatutSync.conflit))).watch();
  }
}
