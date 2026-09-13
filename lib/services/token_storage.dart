import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Cle partagee entre AuthService (ecriture a la connexion) et SyncService
/// (lecture pour authentifier les appels de synchro).
const cleJetonJwt = 'jwt';

/// Abstraction du stockage du jeton : permet de substituer une fausse
/// implementation en test sans dependance de mock supplementaire.
abstract class TokenStorage {
  Future<String?> lire(String cle);
  Future<void> ecrire(String cle, String valeur);
}

class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> lire(String cle) => _storage.read(key: cle);

  @override
  Future<void> ecrire(String cle, String valeur) =>
      _storage.write(key: cle, value: valeur);
}
