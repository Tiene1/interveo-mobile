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
