import 'package:drift/drift.dart' show Value;

import '../data/dao/intervention_dao.dart';
import '../data/local_db.dart';
import '../models/enums.dart';
import 'api_client.dart';
import 'token_storage.dart';

/// US2.11, volet pull uniquement pour l'instant. Le push (cloture + photos)
/// et la resolution de conflit restent un ticket a part : rien ne met encore
/// statutSync a LOCAL cote mobile (l'ecran Completer intervention n'existe
/// pas), donc il n'y a rien a pousser pour le moment.
class SyncService {
  SyncService({
    required this._interventionDao,
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? const SecureTokenStorage();

  final InterventionDao _interventionDao;
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  /// Appelle GET /sync/interventions avec en parametre `depuis`, le dernier
  /// `misAJourLe` connu localement (omis si la base est vide), puis upsert
  /// chaque intervention recue. Renvoie le nombre d'interventions recues
  /// (0 si rien de nouveau).
  Future<int> tirerInterventions() async {
    final jeton = await _tokenStorage.lire(cleJetonJwt);
    final depuis = await _interventionDao.derniereMiseAJour();
    final chemin = depuis != null
        ? '/sync/interventions?depuis=${depuis.toUtc().toIso8601String()}'
        : '/sync/interventions';

    final items = await _apiClient.getListe(chemin, jeton: jeton);
    for (final item in items) {
      await _interventionDao.upsert(_versCompanion(item as Map<String, dynamic>));
    }
    return items.length;
  }

  InterventionsCompanion _versCompanion(Map<String, dynamic> json) {
    return InterventionsCompanion.insert(
      idServeur: json['id'] as String,
      nomClient: json['nomClient'] as String,
      adresse: json['adresse'] as String,
      telephone1: json['telephone1'] as String,
      telephone2: Value(json['telephone2'] as String?),
      geolocalisation: Value(json['geolocalisation'] as String?),
      motifSignale: Value(json['motifSignale'] as String?),
      datePrevue: DateTime.parse(json['datePrevue'] as String),
      technicienId: json['technicienId'] as String,
      creeParId: json['creeParId'] as String,
      typeEquipement: Value(typeEquipementDepuisServeur(json['typeEquipement'] as String?)),
      problemeConstate: Value(json['problemeConstate'] as String?),
      travauxRealises: Value(json['travauxRealises'] as String?),
      statut: statutInterventionDepuisServeur(json['statut'] as String),
      dateRealisation: Value(
        json['dateRealisation'] != null ? DateTime.parse(json['dateRealisation'] as String) : null,
      ),
      creeLe: DateTime.parse(json['creeLe'] as String),
      misAJourLe: DateTime.parse(json['misAJourLe'] as String),
      // Recue confirmee par le serveur : jamais LOCAL/ENVOYE a la reception.
      statutSync: StatutSync.confirme,
    );
  }
}
