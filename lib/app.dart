import 'package:flutter/material.dart';

/// Point d'entree temporaire, remplace par l'ecran de connexion (US4.1)
/// des que le ticket auth est traite.
class SimInterventionsApp extends StatelessWidget {
  const SimInterventionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIM Interventions',
      home: const Scaffold(
        body: Center(child: Text('SIM Interventions')),
      ),
    );
  }
}
