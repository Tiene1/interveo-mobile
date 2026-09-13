import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'connexion_screen.dart';
import 'mes_interventions_screen.dart';

/// Ecran de demarrage : affiche le monogramme pendant 2 secondes pendant que
/// la session est verifiee (US4.2), puis bascule vers l'ecran de connexion
/// ou vers Mes interventions selon la presence d'un jeton.
class SplashScreen extends StatefulWidget {
  SplashScreen({super.key, AuthService? authService})
      : authService = authService ?? AuthService();

  final AuthService authService;

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
    final resultats = await Future.wait([
      widget.authService.sessionValide(),
      Future.delayed(const Duration(seconds: 2)),
    ]);
    if (!mounted) return;
    final sessionValide = resultats[0] as bool;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => sessionValide ? const MesInterventionsScreen() : ConnexionScreen(authService: widget.authService),
      ),
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
