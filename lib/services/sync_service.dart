import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:path/path.dart' as chemin;

import '../data/dao/intervention_dao.dart';
import '../data/dao/photo_dao.dart';
import '../data/local_db.dart';
import '../models/enums.dart';
import 'api_client.dart';
import 'token_storage.dart';

final _typesMimeParExtension = {
  '.jpg': MediaType('image', 'jpeg'),
  '.jpeg': MediaType('image', 'jpeg'),
  '.png': MediaType('image', 'png'),
  '.webp': MediaType('image', 'webp'),
};

/// US2.11. Pull (GET /sync/interventions), push des clotures et des photos
/// (POST /sync/interventions, POST /interventions/:id/photos).
class SyncService {
  SyncService({
    required this._interventionDao,
    required this._photoDao,
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? const SecureTokenStorage();

  final InterventionDao _interventionDao;
  final PhotoDao _photoDao;
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

  /// Envoie au serveur les clotures locales (`statutSync = LOCAL`,
  /// `statut = REALISEE`) via POST /sync/interventions. Marque `CONFIRME`
  /// les clotures acceptees. Renvoie le nombre de conflits (intervention
  /// annulee ou deja traitee entre-temps par le directeur) : ces lignes ne
  /// sont pas modifiees ici, `tirerInterventions()` (appele ensuite par
  /// [synchroniser]) les ecrasera avec l'etat serveur, qui fait foi.
  Future<int> pousserInterventions() async {
    final aPousser = await _interventionDao.listerAPousser();
    if (aPousser.isEmpty) return 0;

    final jeton = await _tokenStorage.lire(cleJetonJwt);
    final corps = aPousser
        .map(
          (intervention) => {
            'idServeur': intervention.idServeur,
            'problemeConstate': intervention.problemeConstate,
            'travauxRealises': intervention.travauxRealises,
            'statut': 'REALISEE',
            'dateRealisation': intervention.dateRealisation!.toUtc().toIso8601String(),
          },
        )
        .toList();

    final resultats = await _apiClient.postListe(
      '/sync/interventions',
      corps: corps,
      jeton: jeton,
    );

    var conflits = 0;
    for (final resultat in resultats) {
      final item = resultat as Map<String, dynamic>;
      if (item['resultat'] == 'CONFIRME') {
        await _interventionDao.marquerConfirmee(item['idServeur'] as String);
      } else {
        conflits++;
      }
    }
    return conflits;
  }

  /// Envoie au serveur les photos locales (`statutSync = LOCAL`) via
  /// POST /interventions/:id/photos (multipart). Marque `CONFIRME` avec
  /// l'`idServeur` recu les photos acceptees. Un 409 (deja 2 photos de cette
  /// categorie cote serveur, ex. retentative apres un crash post-upload) est
  /// compte comme echec sans bloquer les photos suivantes ; toute autre
  /// erreur (reseau, 401...) remonte et arrete la boucle. Renvoie le nombre
  /// d'echecs.
  Future<int> pousserPhotos() async {
    final aPousser = await _photoDao.listerAPousser();
    if (aPousser.isEmpty) return 0;

    final jeton = await _tokenStorage.lire(cleJetonJwt);
    var echecs = 0;
    for (final photo in aPousser) {
      try {
        final reponse = await _apiClient.postFichier(
          '/interventions/${photo.interventionIdLocal}/photos',
          champFichier: 'fichier',
          fichier: File(photo.cheminLocal),
          typeFichier: _typesMimeParExtension[chemin.extension(photo.cheminLocal).toLowerCase()] ??
              MediaType('image', 'jpeg'),
          champs: {'categorie': categoriePhotoVersServeur(photo.categorie)},
          jeton: jeton,
        );
        await _photoDao.marquerConfirmee(photo.idLocal, reponse['id'] as String);
      } on ApiException catch (erreur) {
        if (erreur.statusCode != 409) rethrow;
        echecs++;
      }
    }
    return echecs;
  }

  /// Orchestration complete de la synchro : pousse les clotures locales et
  /// les photos, puis re-tire les interventions (fait foi en cas de conflit,
  /// cf. "l'annulation gagne" dans docs/architecture.md). Renvoie le nombre
  /// de conflits de clotures (les echecs de photos sont un cas distinct,
  /// cf. [pousserPhotos]).
  Future<int> synchroniser() async {
    final conflits = await pousserInterventions();
    await pousserPhotos();
    await tirerInterventions();
    return conflits;
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
