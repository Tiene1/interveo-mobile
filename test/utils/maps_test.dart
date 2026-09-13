import 'package:flutter_test/flutter_test.dart';
import 'package:sim_interventions/utils/maps.dart';

void main() {
  test('renvoie un lien https colle tel quel inchange', () {
    const lien = 'https://maps.app.goo.gl/abc123';
    expect(lienItineraire(lien), lien);
  });

  test('construit un lien itineraire (dir) a partir de coordonnees', () {
    final lien = lienItineraire('5.359,-3.996');
    expect(lien, 'https://www.google.com/maps/dir/?api=1&destination=5.359%2C-3.996');
  });

  test('construit un lien itineraire a partir d une adresse texte', () {
    final lien = lienItineraire('Boulevard Hassan II, Cocody');
    expect(lien, contains('/maps/dir/?api=1&destination='));
    expect(lien, contains('Boulevard'));
  });
}
