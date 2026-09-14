import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sim_interventions/data/local_db.dart';
import 'package:sim_interventions/services/api_client.dart';
import 'package:sim_interventions/services/auth_service.dart';
import 'package:sim_interventions/services/sync_service.dart';
import 'package:sim_interventions/state/interventions_provider.dart';

import 'fake_token_storage.dart';

/// ProviderScope de test qui evite tout vrai appel reseau : MesInterventionsScreen
/// declenche une synchro et une recuperation opportuniste du nom du
/// technicien des son initState, donc tout test qui l'atteint (via le
/// splash, la connexion, ou directement) a besoin que syncServiceProvider
/// et authServiceProvider repondent instantanement plutot que d'attendre un
/// vrai serveur ou le vrai stockage securise (FlutterSecureStorage bloque
/// indefiniment sans canal de plateforme en test, cf. ticket 7).
Widget appTest({
  required Widget home,
  AppDatabase? db,
  List<Map<String, dynamic>> reponseSynchro = const [],
}) {
  final base = db ?? AppDatabase(NativeDatabase.memory());
  final client = MockClient((request) async => http.Response(jsonEncode(reponseSynchro), 200));

  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(base),
      syncServiceProvider.overrideWithValue(
        SyncService(
          interventionDao: base.interventionDao,
          photoDao: base.photoDao,
          apiClient: ApiClient(client: client),
          tokenStorage: FakeTokenStorage(),
        ),
      ),
      authServiceProvider.overrideWithValue(
        AuthService(apiClient: ApiClient(client: client), storage: FakeTokenStorage()),
      ),
    ],
    child: MaterialApp(home: home),
  );
}
