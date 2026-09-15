import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:path/path.dart' as chemin;

import '../data/dao/intervention_dao.dart';
import '../data/dao/photo_dao.dart';
import '../data/local_db.dart';
import '../models/enums.dart';
import 'api_client.dart';
import 'photo_stockage_service.dart';
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
    PhotoStockageService? photoStockage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? const SecureTokenStorage(),
        _photoStockage = photoStockage ?? PhotoStockageService();

  final InterventionDao _interventionDao;
  final PhotoDao _photoDao;
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;
  final PhotoStockageService _photoStockage;

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
    for (final itemBrut in items) {
      final json = itemBrut as Map<String, dynamic>;
      final idServeurIntervention = json['id'] as String;
      await _interventionDao.upsert(_versCompanion(json));
      await _repeuplerMetadonneesPhotos(idServeurIntervention, json);
      if (statutInterventionDepuisServeur(json['statut'] as String) ==
          StatutIntervention.realisee) {
        await _viderCachePhotosConfirmees(idServeurIntervention);
      }
    }
    return items.length;
  }

  /// Recree les lignes de metadonnee (idServeur, categorie, sans fichier)
  /// des photos que le serveur connait mais que la base locale a perdues
  /// (ex. deconnexion, US4.3, qui vide interventions/photos locales). Ne
  /// telecharge jamais le fichier ici : seul l'ecran de detail le fait, a
  /// l'affichage, pour une intervention deja Realisee.
  Future<void> _repeuplerMetadonneesPhotos(
    String interventionIdLocal,
    Map<String, dynamic> json,
  ) async {
    final photosServeur = (json['photos'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    for (final photo in photosServeur) {
      final idServeurPhoto = photo['id'] as String;
      final dejaConnue = await _photoDao.parIdServeur(idServeurPhoto);
      if (dejaConnue != null) continue;
      await _photoDao.ajouterMetadonnee(
        idServeur: idServeurPhoto,
        interventionIdLocal: interventionIdLocal,
        categorie: categoriePhotoDepuisServeur(photo['categorie'] as String),
      );
    }
  }

  /// Libere l'espace disque des photos deja confirmees d'une intervention
  /// desormais Realisee (fichier local supprime, metadonnee conservee) :
  /// l'image sera rechargee a la demande depuis le serveur a l'affichage.
  Future<void> _viderCachePhotosConfirmees(String interventionIdLocal) async {
    final chemins = await _photoDao.cheminsAliberer(interventionIdLocal);
    for (final chemin in chemins) {
      await _photoStockage.supprimerFichier(chemin);
    }
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
  /// categorie cote serveur - un refus definitif, pas juste "deja envoyee
  /// par cette meme photo") marque la photo `conflit` (`PhotoDao.marquerEnConflit`) :
  /// exclue de [PhotoDao.listerAPousser], elle n'est donc plus jamais
  /// reessayee automatiquement, cf. docs/architecture.md. Toute autre erreur
  /// (reseau, 401...) remonte et arrete la boucle. Renvoie le nombre de
  /// photos en conflit.
  Future<int> pousserPhotos() async {
    final aPousser = await _photoDao.listerAPousser();
    if (aPousser.isEmpty) return 0;

    final jeton = await _tokenStorage.lire(cleJetonJwt);
    var echecs = 0;
    for (final photo in aPousser) {
      // listerAPousser() ne renvoie que des photos `local` : jamais creees
      // sans fichier, cheminLocal est donc toujours renseigne ici.
      final cheminPhoto = photo.cheminLocal!;
      try {
        final reponse = await _apiClient.postFichier(
          '/interventions/${photo.interventionIdLocal}/photos',
          champFichier: 'fichier',
          fichier: File(cheminPhoto),
          typeFichier: _typesMimeParExtension[chemin.extension(cheminPhoto).toLowerCase()] ??
              MediaType('image', 'jpeg'),
          champs: {'categorie': categoriePhotoVersServeur(photo.categorie)},
          jeton: jeton,
        );
        await _photoDao.marquerConfirmee(photo.idLocal, reponse['id'] as String);
      } on ApiException catch (erreur) {
        if (erreur.statusCode != 409) rethrow;
        await _photoDao.marquerEnConflit(photo.idLocal);
        echecs++;
      }
    }
    return echecs;
  }

  /// Orchestration complete de la synchro : pousse les clotures locales et
  /// les photos, puis re-tire les interventions (fait foi en cas de conflit,
  /// cf. "l'annulation gagne" dans docs/architecture.md). Persiste l'heure de
  /// succes (voir [derniereSynchroReussie]) : un cycle complet sans exception
  /// est considere reussi meme s'il y a eu des conflits de clotures ou des
  /// photos en conflit, ce sont des cas geres, pas des pannes de synchro.
  Future<ResultatSynchro> synchroniser() async {
    final conflitsClotures = await pousserInterventions();
    final photosEnConflit = await pousserPhotos();
    await tirerInterventions();
    await _tokenStorage.ecrire(cleDerniereSynchro, DateTime.now().toIso8601String());
    return ResultatSynchro(
      conflitsClotures: conflitsClotures,
      photosEnConflit: photosEnConflit,
    );
  }

  /// Telecharge le contenu binaire d'une photo dont seule la metadonnee est
  /// connue localement (`cheminLocal` absent). Appele par l'ecran de detail,
  /// jamais par le pull automatique : chaque image n'est recuperee qu'au
  /// moment ou le technicien l'affiche reellement.
  Future<Uint8List> telechargerPhoto(String idServeur) async {
    final jeton = await _tokenStorage.lire(cleJetonJwt);
    return _apiClient.getBinaire('/photos/$idServeur', jeton: jeton);
  }

  /// Heure de la derniere synchro reussie, persistee (survit a un
  /// redemarrage de l'app). Null si aucune synchro n'a jamais reussi.
  Future<DateTime?> derniereSynchroReussie() async {
    final valeur = await _tokenStorage.lire(cleDerniereSynchro);
    return valeur == null ? null : DateTime.tryParse(valeur);
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

/// Resultat d'un cycle [SyncService.synchroniser] complet.
class ResultatSynchro {
  const ResultatSynchro({
    required this.conflitsClotures,
    required this.photosEnConflit,
  });

  /// Clotures refusees par le serveur (intervention annulee entre-temps...).
  final int conflitsClotures;

  /// Photos definitivement refusees (categorie deja pleine cote serveur).
  final int photosEnConflit;
}
