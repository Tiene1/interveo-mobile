String _deuxChiffres(int n) => n.toString().padLeft(2, '0');

/// Format court "jj/mm · HH:mm" utilise sur les tuiles d'intervention.
String formatDateHeure(DateTime date) {
  final jour = _deuxChiffres(date.day);
  final mois = _deuxChiffres(date.month);
  final heure = _deuxChiffres(date.hour);
  final minute = _deuxChiffres(date.minute);
  return '$jour/$mois · $heure:$minute';
}

/// Format complet "jj/mm/aaaa · HH:mm" utilise sur l'ecran de detail.
String formatDateHeureComplete(DateTime date) {
  final jour = _deuxChiffres(date.day);
  final mois = _deuxChiffres(date.month);
  final heure = _deuxChiffres(date.hour);
  final minute = _deuxChiffres(date.minute);
  return '$jour/$mois/${date.year} · $heure:$minute';
}

/// Format date seule "jj/mm/aaaa" utilise dans le bandeau du detail.
String formatDate(DateTime date) {
  final jour = _deuxChiffres(date.day);
  final mois = _deuxChiffres(date.month);
  return '$jour/$mois/${date.year}';
}
