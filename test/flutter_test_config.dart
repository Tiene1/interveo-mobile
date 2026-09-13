import 'dart:async';

import 'package:drift/drift.dart';

/// Execute avant toute la suite. Desactive l'avertissement Drift sur les
/// instanciations multiples de AppDatabase : attendu ici, chaque test cree
/// sa propre base en memoire (NativeDatabase.memory()) volontairement.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  await testMain();
}
