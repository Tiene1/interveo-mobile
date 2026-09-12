import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sim_interventions/app.dart';
import 'package:sim_interventions/services/api_client.dart';
import 'package:sim_interventions/services/auth_service.dart';

import 'support/fake_token_storage.dart';

void main() {
  testWidgets('demarre sur le splash puis atteint l ecran de connexion', (WidgetTester tester) async {
    final service = AuthService(apiClient: ApiClient(), storage: FakeTokenStorage());

    await tester.pumpWidget(ProviderScope(child: SimInterventionsApp(authService: service)));

    expect(find.text('SIM Interventions'), findsWidgets);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });
}
