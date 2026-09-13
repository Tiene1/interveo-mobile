/// Construit un lien d'itineraire Google Maps a partir de la geolocalisation
/// (docs/architecture.md section 4) : lien Google Maps colle tel quel, ou
/// coordonnees/texte libre transformes en lien "dir" (itineraire, pas simple
/// recherche : le technicien doit s'y rendre, contrairement au web ou
/// M. Kouassi consulte seulement).
String lienItineraire(String geolocalisation) {
  final valeur = geolocalisation.trim();
  if (valeur.startsWith('http://') || valeur.startsWith('https://')) {
    return valeur;
  }
  return 'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(valeur)}';
}
