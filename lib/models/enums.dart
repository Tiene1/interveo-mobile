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

enum StatutSync { local, envoye, confirme }

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
