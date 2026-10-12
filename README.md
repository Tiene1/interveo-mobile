# App terrain Interveo

![CI](https://github.com/Tiene1/interveo-mobile/actions/workflows/ci.yml/badge.svg)

Application Flutter des techniciens d'Interveo : consultation des interventions attribuées, complément du compte rendu (problème constaté, travaux réalisés, photos avant/après), clôture — entièrement hors ligne, synchronisation automatique au retour du réseau.

- Stack : Flutter, Android en priorité.
- Contrainte structurante : offline-first (base locale Drift, synchronisation par delta).
- Documentation : `docs/ADR.md`, `docs/architecture.md`.
- Règles de développement : `CLAUDE.md`.

## Démarrage

Prérequis :

- **Flutter 3.47.4** (version épinglée dans la CI), qui embarque **Dart ^3.13.2** (`environment.sdk` de `pubspec.yaml`). Vérifier avec `flutter --version`.
- Un émulateur Android, ou un téléphone Android en mode développeur. Pas de build iOS.
- Une API Interveo qui tourne : voir la section suivante.

```bash
flutter pub get
flutter run --dart-define=API_URL=http://<ip locale du backend>:3000
```

Sur émulateur Android, `API_URL` peut être omis (`10.0.2.2` par défaut, adresse sous laquelle l'émulateur voit le `localhost` du poste). Sur un appareil physique, l'IP locale du poste qui fait tourner le backend est obligatoire.

## Tester l'app en local

Sans compiler Flutter : il suffit de Docker, d'`adb` (outils de plateforme Android) et d'un téléphone Android ou d'un émulateur.

1. **Lancer l'API** (et le back-office web) avec le dépôt [interveo-backend](https://github.com/Tiene1/interveo-backend) :
   ```bash
   git clone https://github.com/Tiene1/interveo-backend.git
   cd interveo-backend
   docker compose up
   ```
   L'API écoute sur `http://localhost:3000` et le back-office sur `http://localhost:3001`.
2. **Installer l'APK « Interveo 1.0.2 (test local) »** depuis la page [Releases](https://github.com/Tiene1/interveo-mobile/releases) de ce dépôt. Il est construit pour joindre `http://localhost:3000`. Les autres APK des Releases visent un autre serveur : ils ne conviennent pas pour ce test. Si l'app Interveo est déjà installée sur l'appareil, cet APK la remplace (même identifiant).
3. **Relier l'appareil à l'API du poste** : téléphone branché en USB (débogage USB activé) ou émulateur démarré, puis
   ```bash
   adb reverse tcp:3000 tcp:3000
   ```
   `localhost:3000` sur l'appareil pointe alors vers le port 3000 du poste. Si l'API écoute sur un autre port (`API_PORT=3300` côté Docker), adapter la seconde moitié : `adb reverse tcp:3000 tcp:3300`. La commande est à relancer si le téléphone est débranché puis rebranché, ou si l'émulateur redémarre.
4. **Scénario** :
   - dans le back-office (`http://localhost:3001`), se connecter en directeur, `kouassi` / `directeur123`, et créer une intervention attribuée à `koffi` ;
   - ouvrir l'app et se connecter avec `koffi` / `technicien123` : l'intervention apparaît (l'app ne peut pas en créer, elles arrivent par la synchronisation) ;
   - compléter le compte rendu (problème constaté, travaux réalisés, photos) et clôturer : l'app synchronise avec l'API, le résultat est visible dans le back-office.
5. **Compiler soi-même** reste possible : Flutter 3.47.4 et Dart ^3.13.2 (voir « Démarrage »), avec `--dart-define=API_URL=<adresse de l'API>` : `http://10.0.2.2:3000` sur émulateur (valeur par défaut), ou `http://<ip du poste>:3000` sur un téléphone connecté au même réseau Wi-Fi (le pare-feu du poste doit alors laisser passer le port de l'API).

Les autres comptes techniciens de démo sont `awa`, `serge` et `ismael` (même mot de passe, `technicien123`).

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
4. Sur le téléphone : ouvrir la page **Releases** du dépôt (le dépôt est public, aucune connexion n'est nécessaire), télécharger l'APK et l'ouvrir. Android propose « Mettre à jour » et **conserve les données** de l'app.

Point d'attention : une mise à jour n'est acceptée que si l'APK est signé avec la **même clé** que celui déjà installé. La signature actuelle est la clé de debug de la machine de build (`~/.android/debug.keystore`) : builder toujours depuis le même poste, ou passer à un keystore dédié (jamais versionné) avant de changer de machine.

## Licence

Licence MIT — voir [LICENSE](LICENSE).
