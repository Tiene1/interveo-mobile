import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'services/auth_service.dart';

class SimInterventionsApp extends StatelessWidget {
  SimInterventionsApp({super.key, AuthService? authService})
      : authService = authService ?? AuthService();

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIM Interventions',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFBFBF9), // --paper
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)), // --brand
      ),
      home: SplashScreen(authService: authService),
    );
  }
}
