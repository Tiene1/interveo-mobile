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
}
