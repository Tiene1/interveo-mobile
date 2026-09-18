/// URL de base de l'API Interveo.
///
/// Sur émulateur Android, `10.0.2.2` pointe vers le localhost de la
/// machine hôte. Sur un appareil physique (ex. le Xiaomi de test),
/// remplacer via `--dart-define=API_URL=http://<ip locale du backend>:3000`.
const String apiBaseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:3000',
);
