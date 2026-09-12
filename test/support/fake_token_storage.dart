import 'package:sim_interventions/services/token_storage.dart';

/// Fausse implementation en memoire de [TokenStorage], partagee par les
/// tests qui ont besoin d'un AuthService sans toucher au stockage reel.
class FakeTokenStorage implements TokenStorage {
  final Map<String, String> _valeurs = {};

  @override
  Future<String?> lire(String cle) async => _valeurs[cle];

  @override
  Future<void> ecrire(String cle, String valeur) async => _valeurs[cle] = valeur;
}
