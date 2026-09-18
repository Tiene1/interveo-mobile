# CLAUDE.md — Dépôt `mobile/` : app terrain Interveo

Règles pour l'agent Claude Code de ce dépôt. Tu écris l'app Flutter des techniciens d'Interveo, utilisée sur le terrain, hors ligne.

## Sources de vérité

- `docs/ADR.md` : fiche ADR complète, socle commun (modèles, énumérations, relations), tableau une ligne par User Story MVP. **Ne se refactore pas.**
- `docs/architecture.md` : structure du dépôt mobile, arborescence, écrans, modèle local, points de conception.
- `../backend/docs/architecture.md` : le contrat d'API (endpoints, méthode, corps, rôle). Fait foi pour les types.
- `C:\Users\TIENE\.claude\references\flutter\FLUTTER_BEST_PRACTICES.md` : le référentiel Flutter de NISSI BAT SERVICES. **S'applique strictement.**
- En cas d'ambiguïté ou d'incomplétude d'un document, tu t'arrêtes et tu demandes.

## Langue

Réponds toujours en français.

## Méthode de travail (Phase III)

- **Un ticket = une seule responsabilité**, avec son **périmètre explicite listé** : fichiers, écrans, services concernés. Tu ne modifies que ce périmètre.
- Dès que tu envisages de toucher un fichier hors périmètre, tu **t'arrêtes et tu demandes avant d'agir**. Formulation : *« Ceci est hors du périmètre du ticket [X]. Je le note en dette technique et je continue sur le périmètre prévu, confirme si tu veux que je traite ça maintenant à la place. »*
- **Definition of Done** : le code compile, le cas nominal fonctionne (test manuel de Cédric en 1 à 2 minutes sur un appareil réel), aucun crash évident. Pas un critère de perfection.
- **3 tentatives maximum** sur un bug donné, puis tu rends la main avec le message d'erreur Flutter complet (widget fautif, type d'exception) et l'explication du blocage.
- **Un commit par ticket terminé**. Jamais un commit géant en fin de session.
- **Transparence des commandes** : tu affiches les commandes exactes que tu exécutes.
- La **dette technique** hors scope se note dans une liste, elle ne se résout pas en boucle en cours de développement.

## Référentiel Flutter (strict)

Applique `FLUTTER_BEST_PRACTICES.md` sans exception, notamment :
- Structure `lib/` respectée (voir `docs/architecture.md` section 2). `main.dart` ne contient que `runApp` + `ProviderScope`.
- Null safety : **aucun `!` non justifié** par une vérification immédiatement précédente. Ne jamais faire taire une erreur avec `!` ou un `try/catch` vide.
- `child` (un widget) vs `children` (une liste) : ne jamais confondre. `const` devant tout widget figé.
- État : `setState` pour le local, **Riverpod** pour le partagé. Toute variable affichée qui change passe par un rebuild déclenché proprement.
- Asynchrone : gérer les 3 états d'un `FutureBuilder` avant d'utiliser `snapshot.data`. Stocker le `Future` dans une variable, pas dans `future:` d'un widget qui se redessine. Jamais de `context` après un `await` sans `context.mounted`.
- Navigation : `pushReplacement` après la connexion réussie.
- Packages : voir section ci-dessous.

## Périmètre fonctionnel

- **Seulement les 12 User Stories MVP** qui touchent le mobile (voir `docs/architecture.md` section 1). Le Nice to have est hors périmètre.
- **Pas de création d'intervention côté mobile** : elles arrivent par la synchro.
- `typeEquipement` : colonne présente, **nullable**, aucune UI de saisie.
- Clôture d'une intervention : exige `problemeConstate` et `travauxRealises` uniquement.
- Pas de déconnexion, pas de changement de mot de passe, pas de consultation de l'historique personnel, pas de build iOS.

## Offline-first (règle centrale)

- Tous les écrans lisent la **base locale** via les providers Riverpod. Aucun écran ne dépend d'un appel réseau pour s'afficher ni pour enregistrer une saisie.
- Seul `sync_service.dart` parle à l'API.
- Conflit clôture hors ligne contre annulation directeur : **l'annulation gagne**, la clôture locale est abandonnée et signalée au technicien.
- Le **socle** (modèles dans `docs/ADR.md`) ne se refactore pas. La table locale ajoute seulement les champs de synchro (`idServeur`, `statutSync`, `modifieLocalementLe`).

## Packages (validation obligatoire)

- **Ne jamais installer un package sans validation explicite de Cédric.** Pour chaque besoin, présenter une **shortlist de 2 à 3 candidats** avec Pub Points, Likes, popularité, date de dernière mise à jour, et compatibilité avec les dépendances déjà présentes. Attendre son choix.
- Choix structurant à trancher en premier : **base locale Drift ou Isar**.
- `pubspec.lock` est versionné. Ne jamais modifier `pubspec.lock` à la main. Ne jamais toucher `android/` ou `ios/` sans raison justifiée à Cédric.

## Sécurité

- Aucun secret dans le code. `API_URL` dans `lib/config/env.dart`.
- JWT en stockage sécurisé (package de la shortlist), jamais en clair, jamais dans les logs.

## Tests

- `flutter test`. Couverture **> 70 %**.
- Cas à couvrir : connexion échouée, liste vide, saisie récupérée après fermeture de l'app hors réseau, clôture bloquée si problème ou travaux manquants, conflit de synchro (intervention annulée).

## Confirmation obligatoire avant

- Tout build de distribution (`flutter build apk`) et toute distribution aux techniciens.
- Toute suppression de fichier.
- Toute modification de `android/` ou `ios/`.

## Commandes que tu affiches toujours

```
flutter pub get
flutter run
flutter test
dart run build_runner build --delete-conflicting-outputs   (si Drift ou Isar génère du code)
flutter build apk
git add -A && git commit -m "<ticket> : <résumé>"
```
