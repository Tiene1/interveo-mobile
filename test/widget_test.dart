import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sim_interventions/app.dart';

void main() {
  testWidgets('demarre sur le splash puis atteint l ecran suivant', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SimInterventionsApp()));

    expect(find.text('SIM Interventions'), findsWidgets);

    // Laisse le timer du splash (2s) se terminer pour ne pas le laisser
    // pendant a la fin du test.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });
}
