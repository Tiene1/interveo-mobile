import 'package:flutter/material.dart';

/// Ecran temporaire, remplace des que l'ecran de connexion (US4.1) existe.
class PlaceholderHomeScreen extends StatelessWidget {
  const PlaceholderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('SIM Interventions')),
    );
  }
}
