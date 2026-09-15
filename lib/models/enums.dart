/// Enumerations miroir des enums serveur (Prisma, voir docs/ADR.md, socle
/// commun). `StatutSync` est purement local, sans equivalent cote API : il
/// suit l'etat de synchronisation d'une ligne locale.
library;

enum RoleUtilisateur { technicien, directeur }

enum StatutIntervention { planifiee, realisee, annulee }

enum TypeEquipement {
  climatisation,
  groupeElectrogene,
  installationElectrique,
  autre,
}

enum CategoriePhoto { avant, apres }

/// `conflit` : le serveur a definitivement refuse l'envoi (ex. photo dont la
/// categorie est deja pleine cote serveur) - jamais reessaye automatiquement,
/// contrairement a `local` qui reste candidat a chaque synchro.
enum StatutSync { local, envoye, confirme, conflit }

/// Conversions depuis le format serveur (chaines en SCREAMING_CASE, ex.
/// "PLANIFIEE") vers les enums locaux. Utilisees par sync_service.dart pour
/// interpreter le JSON de GET /sync/interventions.

StatutIntervention statutInterventionDepuisServeur(String valeur) {
  switch (valeur) {
    case 'PLANIFIEE':
      return StatutIntervention.planifiee;
    case 'REALISEE':
      return StatutIntervention.realisee;
    case 'ANNULEE':
      return StatutIntervention.annulee;
    default:
      throw ArgumentError('Statut intervention inconnu : $valeur');
  }
}

TypeEquipement? typeEquipementDepuisServeur(String? valeur) {
  if (valeur == null) return null;
  switch (valeur) {
    case 'CLIMATISATION':
      return TypeEquipement.climatisation;
    case 'GROUPE_ELECTROGENE':
      return TypeEquipement.groupeElectrogene;
    case 'INSTALLATION_ELECTRIQUE':
      return TypeEquipement.installationElectrique;
    case 'AUTRE':
      return TypeEquipement.autre;
    default:
      throw ArgumentError('Type equipement inconnu : $valeur');
  }
}

/// Sens inverse (mobile -> serveur), utilise par sync_service.dart pour
/// l'envoi d'une photo (POST /interventions/:id/photos).
String categoriePhotoVersServeur(CategoriePhoto categorie) {
  switch (categorie) {
    case CategoriePhoto.avant:
      return 'AVANT';
    case CategoriePhoto.apres:
      return 'APRES';
  }
}

/// Metadonnees de photos recues dans GET /sync/interventions (jamais a
/// l'envoi, cf. [categoriePhotoVersServeur]).
CategoriePhoto categoriePhotoDepuisServeur(String valeur) {
  switch (valeur) {
    case 'AVANT':
      return CategoriePhoto.avant;
    case 'APRES':
      return CategoriePhoto.apres;
    default:
      throw ArgumentError('Categorie photo inconnue : $valeur');
  }
}
