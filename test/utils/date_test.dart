import 'package:flutter_test/flutter_test.dart';
import 'package:sim_interventions/utils/date.dart';

void main() {
  final date = DateTime(2026, 9, 14, 9, 5);

  test('formatDateHeure : format court jj/mm · HH:mm', () {
    expect(formatDateHeure(date), '14/09 · 09:05');
  });

  test('formatDateHeureComplete : format long jj/mm/aaaa · HH:mm', () {
    expect(formatDateHeureComplete(date), '14/09/2026 · 09:05');
  });

  test('formatDate : date seule jj/mm/aaaa', () {
    expect(formatDate(date), '14/09/2026');
  });

  test('salutation : Bonsoir avant 5h', () {
    expect(salutation(DateTime(2026, 9, 14, 4, 59)), 'Bonsoir');
  });

  test('salutation : Bonjour de 5h a 11h59', () {
    expect(salutation(DateTime(2026, 9, 14, 5, 0)), 'Bonjour');
    expect(salutation(DateTime(2026, 9, 14, 11, 59)), 'Bonjour');
  });

  test('salutation : Bon apres-midi de 12h a 17h59', () {
    expect(salutation(DateTime(2026, 9, 14, 12, 0)), 'Bon après-midi');
    expect(salutation(DateTime(2026, 9, 14, 17, 59)), 'Bon après-midi');
  });

  test('salutation : Bonsoir a partir de 18h', () {
    expect(salutation(DateTime(2026, 9, 14, 18, 0)), 'Bonsoir');
    expect(salutation(DateTime(2026, 9, 14, 23, 59)), 'Bonsoir');
  });
}
