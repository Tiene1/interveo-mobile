import 'package:flutter_test/flutter_test.dart';
import 'package:sim_interventions/utils/text.dart';

void main() {
  test('renvoie la valeur telle quelle si non vide', () {
    expect(nonRenseigne('Climatiseur en panne'), 'Climatiseur en panne');
  });

  test('renvoie "non renseigne" si null', () {
    expect(nonRenseigne(null), '— non renseigné —');
  });

  test('renvoie "non renseigne" si chaine vide ou espaces', () {
    expect(nonRenseigne(''), '— non renseigné —');
    expect(nonRenseigne('   '), '— non renseigné —');
  });
}
