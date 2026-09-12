import 'package:flutter/material.dart';

import 'placeholder_home_screen.dart';

/// Ecran de demarrage : affiche le monogramme de l'app pendant 2 secondes
/// puis bascule vers la suite. Mene vers un placeholder tant que l'ecran
/// de connexion (US4.1) n'existe pas.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _demarrer();
  }

  Future<void> _demarrer() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PlaceholderHomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFBFBF9), // --paper
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'S',
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w600,
                letterSpacing: -2,
                color: Color(0xFF0F172A), // --ink-1
              ),
            ),
            SizedBox(height: 12),
            Text(
              'SIM Interventions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.4,
                color: Color(0xFF475569), // --text-soft
              ),
            ),
          ],
        ),
      ),
    );
  }
}
