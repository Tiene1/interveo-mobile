# App terrain Interveo

Application Flutter des techniciens d'Interveo : consultation des interventions attribuées, complément du compte rendu (problème constaté, travaux réalisés, photos avant/après), clôture — entièrement hors ligne, synchronisation automatique au retour du réseau.

- Stack : Flutter, Android en priorité.
- Contrainte structurante : offline-first (base locale Drift, synchronisation par delta).
- Documentation : `docs/ADR.md`, `docs/architecture.md`.
- Règles de développement : `CLAUDE.md`.

## Démarrage

```bash
flutter pub get
flutter run --dart-define=API_URL=http://<ip locale du backend>:3000
```

Sur émulateur Android, `API_URL` peut être omis (`10.0.2.2` par défaut). Sur un appareil physique, l'IP locale du poste qui fait tourner le backend est obligatoire.

## Scripts

| Commande | Rôle |
|---|---|
| `flutter run` | Lancer l'app sur un appareil/émulateur connecté |
| `flutter test` | Tests unitaires et widgets |
| `flutter analyze` | Analyse statique |
| `dart run build_runner build --delete-conflicting-outputs` | Régénère le code Drift après une modification du schéma local |
| `flutter build apk --release --dart-define=API_URL=<url>` | Build de l'APK de distribution |
