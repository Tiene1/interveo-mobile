import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/design_tokens.dart';
import 'mes_interventions_screen.dart';

/// Ecran de connexion (US4.1). Mene vers MesInterventionsScreen (US2.1)
/// une fois la connexion reussie.
class ConnexionScreen extends StatefulWidget {
  ConnexionScreen({super.key, AuthService? authService})
    : authService = authService ?? AuthService();

  final AuthService authService;

  @override
  State<ConnexionScreen> createState() => _ConnexionScreenState();
}

class _ConnexionScreenState extends State<ConnexionScreen> {
  final _identifiantCtrl = TextEditingController();
  final _motDePasseCtrl = TextEditingController();
  bool _motDePasseVisible = false;
  bool _enCours = false;
  String? _erreur;

  @override
  void dispose() {
    _identifiantCtrl.dispose();
    _motDePasseCtrl.dispose();
    super.dispose();
  }

  Future<void> _seConnecter() async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });

    try {
      await widget.authService.connecter(
        _identifiantCtrl.text,
        _motDePasseCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MesInterventionsScreen()),
      );
    } on ApiException catch (e) {
      setState(() {
        _erreur = e.message;
        _enCours = false;
      });
    } catch (_) {
      setState(() {
        _erreur = 'Vérifiez votre connexion et réessayez';
        _enCours = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: paper,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _brandStrip(),
              _kicker(),
              const SizedBox(height: 12),
              _titre(),
              const SizedBox(height: 8),
              const Text(
                'Connectez-vous pour retrouver vos interventions du jour.',
                style: TextStyle(fontSize: 14, color: textSoft, height: 1.5),
              ),
              const SizedBox(height: 32),
              _champ(
                label: 'IDENTIFIANT',
                controller: _identifiantCtrl,
                key: const Key('champIdentifiant'),
              ),
              const SizedBox(height: 24),
              _champMotDePasse(),
              if (_erreur != null) _ligneErreur(_erreur!),
              const SizedBox(height: 40),
              _boutonConnexion(),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  _texteAide(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: textWeak,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _texteAide() {
    if (_enCours) return 'Connexion sécurisée en cours';
    if (_erreur != null) return 'Vérifiez vos identifiants et réessayez';
    return 'Utilisez vos identifiants professionnels';
  }

  Widget _brandStrip() {
    return Container(
      margin: const EdgeInsets.only(bottom: 36),
      padding: const EdgeInsets.only(bottom: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: line)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.only(right: 10),
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: lineStrong)),
            ),
            child: const Text(
              'SIM',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: inkColor,
                letterSpacing: -0.7,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'INTERVENTIONS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textSoft,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kicker() {
    return const Row(
      children: [
        SizedBox(width: 20, height: 1, child: ColoredBox(color: inkColor)),
        SizedBox(width: 10),
        Text(
          'ESPACE TECHNICIEN',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: textSoft,
            letterSpacing: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _titre() {
    return const Text.rich(
      TextSpan(
        style: TextStyle(
          fontFamily: 'Fraunces',
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: inkColor,
          height: 1.05,
          letterSpacing: -1,
        ),
        children: [
          TextSpan(text: 'Bon '),
          TextSpan(
            text: 'retour.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _champ({
    required String label,
    required TextEditingController controller,
    required Key key,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: textSoft,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: _erreur != null ? danger : lineStrong),
            ),
          ),
          child: TextField(
            key: key,
            controller: controller,
            enabled: !_enCours,
            autocorrect: false,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: inkColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _champMotDePasse() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MOT DE PASSE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: textSoft,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: _erreur != null ? danger : lineStrong),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('champMotDePasse'),
                  controller: _motDePasseCtrl,
                  enabled: !_enCours,
                  obscureText: !_motDePasseVisible,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: inkColor,
                  ),
                ),
              ),
              IconButton(
                key: const Key('boutonVisibiliteMotDePasse'),
                icon: Icon(
                  _motDePasseVisible ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                  color: textWeak,
                ),
                onPressed: _enCours
                    ? null
                    : () => setState(
                        () => _motDePasseVisible = !_motDePasseVisible,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _ligneErreur(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 14, color: danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _boutonConnexion() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        key: const Key('boutonConnexion'),
        onPressed: _enCours ? null : _seConnecter,
        style: ElevatedButton.styleFrom(
          backgroundColor: inkColor,
          disabledBackgroundColor: inkColor.withValues(alpha: 0.7),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: _enCours
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text('Vérification en cours…'),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Se connecter'),
                  SizedBox(width: 10),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
      ),
    );
  }
}
