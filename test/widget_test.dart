import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sim_interventions/app.dart';

void main() {
  testWidgets('affiche le titre SIM Interventions au demarrage', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SimInterventionsApp()));

    expect(find.text('SIM Interventions'), findsWidgets);
  });
}
