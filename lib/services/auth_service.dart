import 'api_client.dart';
import 'token_storage.dart';

/// Login, stockage securise du JWT, lecture de session au demarrage (US4.2).
/// Pas de deconnexion ni de changement de mot de passe : hors perimetre MVP.
class AuthService {
  AuthService({ApiClient? apiClient, TokenStorage? storage})
      : _apiClient = apiClient ?? ApiClient(),
        _storage = storage ?? const SecureTokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _storage;

  /// Appelle POST /auth/login puis stocke le jeton recu. Leve une
  /// [ApiException] (401 : identifiant/mot de passe incorrect) en cas
  /// d'echec, propagee telle quelle pour l'ecran de connexion.
  Future<void> connecter(String identifiant, String motDePasse) async {
    final reponse = await _apiClient.post(
      '/auth/login',
      corps: {'identifiant': identifiant, 'motDePasse': motDePasse},
    );
    await _storage.ecrire(cleJetonJwt, reponse['accessToken'] as String);
  }

  Future<String?> jetonActuel() => _storage.lire(cleJetonJwt);

  /// US4.2 : presence du jeton suffit, y compris hors reseau. Un jeton
  /// expire ou revoque echouera seulement au prochain appel reseau (sync),
  /// jamais bloquant pour la consultation locale.
  Future<bool> sessionValide() async => (await jetonActuel()) != null;

  /// GET /auth/moi, en opportuniste (nom du technicien affiche sur Mes
  /// interventions). Ne leve jamais : hors ligne, jeton absent ou erreur
  /// serveur renvoient simplement null, l'affichage du nom n'est qu'un
  /// complement, jamais bloquant.
  Future<String?> nomTechnicien() async {
    final jeton = await jetonActuel();
    if (jeton == null) return null;
    try {
      final reponse = await _apiClient.get('/auth/moi', jeton: jeton);
      return reponse['nom'] as String?;
    } catch (_) {
      // Hors ligne (SocketException...), jeton expire (ApiException 401)...
      // toute erreur reseau est attendue ici et ne doit jamais remonter.
      return null;
    }
  }
}
