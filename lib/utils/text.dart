/// Convention design/DESIGN-SYSTEM.md : toujours "— non renseigné —"
/// (cadratins), jamais un tiret simple. Miroir de web/.../lib/utils/text.ts.
String nonRenseigne(String? valeur) {
  final v = valeur?.trim();
  return (v != null && v.isNotEmpty) ? v : '— non renseigné —';
}
