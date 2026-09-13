/// Reference courte purement visuelle (mobile/design/DESIGN-SYSTEM.md : "#0142").
/// Meme regle que web/src/features/interventions/lib/reference.ts : pas de
/// numero de ticket sequentiel cote backend, on derive un identifiant
/// compact et stable a partir de l'UUID de l'intervention.
String referenceCourte(String id) {
  final sansTirets = id.replaceAll('-', '');
  final fin = sansTirets.length > 4 ? sansTirets.substring(sansTirets.length - 4) : sansTirets;
  return fin.toUpperCase();
}
