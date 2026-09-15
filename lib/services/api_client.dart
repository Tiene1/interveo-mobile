import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;

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

  /// Envoi multipart (ex. POST /interventions/:id/photos) : [champs] pour
  /// les valeurs texte du formulaire, [fichier] pour le fichier binaire.
  Future<Map<String, dynamic>> postFichier(
    String chemin, {
    required String champFichier,
    required File fichier,
    required MediaType typeFichier,
    Map<String, String> champs = const {},
    String? jeton,
  }) async {
    final requete = http.MultipartRequest('POST', Uri.parse('$apiBaseUrl$chemin'))
      ..fields.addAll(champs)
      ..files.add(
        await http.MultipartFile.fromPath(
          champFichier,
          fichier.path,
          contentType: typeFichier,
        ),
      );
    if (jeton != null) requete.headers['Authorization'] = 'Bearer $jeton';

    final reponseFlux = await _client.send(requete);
    final reponse = await http.Response.fromStream(reponseFlux);
    return _traiterReponse(reponse);
  }

  /// Telecharge un fichier binaire (ex. GET /photos/:id) : pas de JSON en
  /// reponse, contrairement a toutes les autres methodes de ce client.
  Future<Uint8List> getBinaire(String chemin, {String? jeton}) async {
    final reponse = await _client.get(
      Uri.parse('$apiBaseUrl$chemin'),
      headers: _entetes(jeton),
    );
    if (reponse.statusCode < 200 || reponse.statusCode >= 300) {
      throw ApiException(reponse.statusCode, _messageErreur(reponse.body));
    }
    return reponse.bodyBytes;
  }

  Map<String, String> _entetes(String? jeton) => {
        'Content-Type': 'application/json',
        if (jeton != null) 'Authorization': 'Bearer $jeton',
      };

  Map<String, dynamic> _traiterReponse(http.Response reponse) {
    _leverSiErreur(reponse);
    return reponse.body.isEmpty ? <String, dynamic>{} : jsonDecode(reponse.body) as Map<String, dynamic>;
  }

  /// Le corps d'une reponse d'erreur n'est pas toujours le JSON attendu du
  /// backend (ex. 404 texte brut d'un proxy, portail captif wifi, mauvais
  /// hote) : jsonDecode plante alors avec une FormatException qui remontait
  /// telle quelle jusqu'a l'ecran au lieu d'un message exploitable.
  void _leverSiErreur(http.Response reponse) {
    if (reponse.statusCode >= 200 && reponse.statusCode < 300) return;

    final texte = _messageErreur(reponse.body);
    throw ApiException(reponse.statusCode, texte);
  }

  String _messageErreur(String corpsBrut) {
    if (corpsBrut.isEmpty) return 'Erreur inconnue';
    try {
      final corps = jsonDecode(corpsBrut) as Map<String, dynamic>;
      final message = corps['message'];
      if (message is List) return message.join(', ');
      return message as String? ?? 'Erreur inconnue';
    } catch (_) {
      // Corps non-JSON (FormatException) ou JSON mais pas l'enveloppe
      // {message: ...} attendue (TypeError de cast) : dans les deux cas, on
      // retombe sur le texte brut plutot que de laisser planter la synchro.
      return corpsBrut.length > 100 ? '${corpsBrut.substring(0, 100)}…' : corpsBrut;
    }
  }
}
