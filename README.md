# App terrain Interveo

![CI](https://github.com/Tiene1/interveo-mobile/actions/workflows/ci.yml/badge.svg)

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

## Publier une nouvelle version de l'APK

L'APK n'est pas dans le dépôt (le dossier `build/` est ignoré) : il est distribué via les **Releases GitHub** du dépôt.

1. Incrémenter `version:` dans `pubspec.yaml`, par exemple `1.0.1+2`. Le nombre après le `+` est le *versionCode* Android : il **doit augmenter à chaque version**, sinon Android refuse la mise à jour.
2. Construire l'APK de production :
   ```bash
   flutter build apk --release --dart-define=API_URL=https://interveo-api.onrender.com
   ```
3. Publier la release (nom de fichier explicite, notes de version) :
   ```bash
   cp build/app/outputs/flutter-apk/app-release.apk interveo-1.0.1.apk
   gh release create v1.0.1 interveo-1.0.1.apk --repo Tiene1/interveo-mobile --title "Interveo 1.0.1" --notes "Ce qui change dans cette version"
   ```
4. Sur le téléphone : ouvrir la page **Releases** du dépôt (connecté à GitHub, le dépôt étant privé), télécharger l'APK et l'ouvrir. Android propose « Mettre à jour » et **conserve les données** de l'app.

Point d'attention : une mise à jour n'est acceptée que si l'APK est signé avec la **même clé** que celui déjà installé. La signature actuelle est la clé de debug de la machine de build (`~/.android/debug.keystore`) : builder toujours depuis le même poste, ou passer à un keystore dédié (jamais versionné) avant de changer de machine.
