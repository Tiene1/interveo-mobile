import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';

class SimInterventionsApp extends StatelessWidget {
  const SimInterventionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIM Interventions',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFBFBF9), // --paper
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)), // --brand
      ),
      home: const SplashScreen(),
    );
  }
}
