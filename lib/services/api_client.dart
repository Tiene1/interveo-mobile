import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env.dart';

/// Erreur renvoyee par l'API (4xx/5xx). [message] reprend le champ `message`
/// de l'enveloppe d'erreur du backend (voir HttpExceptionFilter cote NestJS).
class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

/// Wrapper HTTP minimal : construit l'URL a partir de [apiBaseUrl], encode/
/// decode le JSON, transforme une reponse d'erreur en [ApiException]. Ne
/// gere pas le JWT lui-meme : chaque appelant fournit le jeton s'il en a un.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> post(
    String chemin, {
    Map<String, dynamic>? corps,
    String? jeton,
  }) async {
    final reponse = await _client.post(
      Uri.parse('$apiBaseUrl$chemin'),
      headers: _entetes(jeton),
      body: corps != null ? jsonEncode(corps) : null,
    );
    return _traiterReponse(reponse);
  }

  Future<Map<String, dynamic>> get(String chemin, {String? jeton}) async {
    final reponse = await _client.get(
      Uri.parse('$apiBaseUrl$chemin'),
      headers: _entetes(jeton),
    );
    return _traiterReponse(reponse);
  }

  /// Comme [get], pour les endpoints qui renvoient un tableau JSON a la
  /// racine (ex. GET /sync/interventions) plutot qu'un objet.
  Future<List<dynamic>> getListe(String chemin, {String? jeton}) async {
    final reponse = await _client.get(
      Uri.parse('$apiBaseUrl$chemin'),
      headers: _entetes(jeton),
    );
    _leverSiErreur(reponse);
    return reponse.body.isEmpty ? [] : jsonDecode(reponse.body) as List<dynamic>;
  }

  /// Comme [post], mais envoie un tableau JSON a la racine du corps et
  /// attend un tableau JSON en reponse (ex. POST /sync/interventions).
  Future<List<dynamic>> postListe(
    String chemin, {
    required List<dynamic> corps,
    String? jeton,
  }) async {
    final reponse = await _client.post(
      Uri.parse('$apiBaseUrl$chemin'),
      headers: _entetes(jeton),
      body: jsonEncode(corps),
    );
    _leverSiErreur(reponse);
    return reponse.body.isEmpty ? [] : jsonDecode(reponse.body) as List<dynamic>;
  }

  Map<String, String> _entetes(String? jeton) => {
        'Content-Type': 'application/json',
        if (jeton != null) 'Authorization': 'Bearer $jeton',
      };

  Map<String, dynamic> _traiterReponse(http.Response reponse) {
    _leverSiErreur(reponse);
    return reponse.body.isEmpty ? <String, dynamic>{} : jsonDecode(reponse.body) as Map<String, dynamic>;
  }

  void _leverSiErreur(http.Response reponse) {
    if (reponse.statusCode >= 200 && reponse.statusCode < 300) return;

    final corps = reponse.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(reponse.body) as Map<String, dynamic>;
    final message = corps['message'];
    final texte = message is List
        ? message.join(', ')
        : (message as String? ?? 'Erreur inconnue');
    throw ApiException(reponse.statusCode, texte);
  }
}
