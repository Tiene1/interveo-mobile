# architecture.md — Cible `mobile/` : app terrain SIM Interventions

Structure spécifique au dépôt mobile. La fiche ADR complète et le socle commun sont dans `docs/ADR.md`, qui fait foi. Le contrat d'API est dans `backend/docs/architecture.md`, qui fait foi pour les types. Le référentiel Flutter `C:\Users\TIENE\.claude\references\flutter\FLUTTER_BEST_PRACTICES.md` s'applique strictement.

- **Stack** : Flutter, Android en priorité.
- **Utilisateurs** : les 4 techniciens, sur le terrain.
- **Contrainte structurante** : offline-first.
- **Périmètre** : les 12 User Stories MVP qui touchent l'app mobile.

---

## 1. User Stories couvertes

| US | Écran / service | Élément |
|---|---|---|
| US4.1 | Connexion | Identifiant, mot de passe, bouton, message d'erreur |
| US4.2 | Connexion / session | JWT en stockage sécurisé, accès direct au lancement sans ressaisie, y compris hors réseau |
| US2.1 | Mes interventions | Liste des interventions attribuées non annulées, triées par date et heure prévues |
| US2.2 | Détail intervention | Nom du client, motif signalé ou « non renseigné », date et heure prévues |
| US2.3 | Détail intervention | Adresse, téléphone(s) cliquables, géolocalisation qui ouvre Google Maps avec itinéraire |
| US2.5 | Compléter l'intervention | Champ texte multiligne « Problème constaté » |
| US2.6 | Compléter l'intervention | Champ texte multiligne « Travaux réalisés » |
| US2.7 | Compléter l'intervention | Section Photos avant, appareil photo ou galerie, max 2, retrait tant que non clôturé |
| US2.8 | Compléter l'intervention | Section Photos après, max 2, affichée séparément |
| US2.9 | Compléter l'intervention | Persistance locale immédiate à chaque champ, pas de bouton Enregistrer |
| US2.10 | Compléter l'intervention | Bouton Clôturer actif si problème + travaux renseignés, puis écran en lecture seule |
| US2.11 | Service de synchronisation | Envoi automatique au retour du réseau, indicateur « synchronisée » par intervention |

---

## 2. Arborescence

Extension minimale de la structure standard `FLUTTER_BEST_PRACTICES.md` pour couvrir l'offline-first.

```
mobile/
  docs/
    ADR.md
    architecture.md
  CLAUDE.md
  pubspec.yaml
  pubspec.lock                    (versionné)
  lib/
    main.dart                     (runApp + ProviderScope, rien d'autre)
    app.dart                      (widget racine MaterialApp, theme --paper/--brand)
    models/
      enums.dart                  (miroir des enums serveur + StatutSync, local uniquement)
      utilisateur.dart
    screens/
      splash_screen.dart          (monogramme 2s, verifie la session US4.2 puis route)
      connexion_screen.dart
      mes_interventions_screen.dart (US2.1 : onglets Toutes/Planifiees/Realisees, badge de synchro)
      detail_intervention_screen.dart (US2.2/US2.3 : motif, rendez-vous, adresse, appels, itineraire)
      completer_intervention_screen.dart (US2.5/US2.6/US2.7/US2.8/US2.9/US2.10 : texte, photos et cloture)
    widgets/                       (un widget réutilisable par fichier : InterventionTile, PhotoPickerSection, SyncBadge, EtatVide, EtatErreur)
    services/
      api_client.dart             (wrapper réseau, ajoute le JWT, base = config API_URL)
      auth_service.dart           (login, stockage sécurisé du JWT, lecture au démarrage, nomTechnicien opportuniste)
      token_storage.dart          (abstraction testable sur flutter_secure_storage ; cle JWT + cle derniere synchro)
      sync_service.dart           (US2.11 : pull + push des clotures + push des photos, cf. section 4)
      photo_stockage_service.dart (US2.7/US2.8 : capture image_picker + copie dans le stockage permanent de l'app)
    data/
      local_db.dart               (base locale : tables intervention et photo + champs de synchro)
      dao/
        intervention_dao.dart     (watchAttribuees, watchParId, mettreAJourSaisie, cloturer, listerAPousser, marquerConfirmee, derniereMiseAJour)
        photo_dao.dart            (watchPourIntervention, listerPourIntervention, ajouter, supprimer, listerAPousser, marquerConfirmee, watchNonConfirmees)
    state/
      interventions_provider.dart (Riverpod : databaseProvider, liste attribuee US2.1, detail par id US2.2/US2.3, photos par intervention US2.7/US2.8, interventions avec photos en attente, syncServiceProvider, photoStockageServiceProvider, authServiceProvider)
    theme/
      design_tokens.dart           (couleurs du design system, partagees entre ecrans)
    utils/
      reference.dart               (reference courte visuelle, miroir de web/.../lib/reference.ts — plus utilisee dans lib/ depuis le 2026-09-14, cf. section 4)
      date.dart                    (formats court et complet jj/mm[/aaaa] · HH:mm)
      text.dart                    (nonRenseigne, miroir de web/.../lib/utils/text.ts)
      maps.dart                    (lienItineraire : dir Google Maps, pas simple recherche comme le web)
    config/
      env.dart                    (API_URL)
  test/                           (flutter test, couverture > 70 %)
```

---

## 3. Modèle de données local

Miroir du modèle serveur (voir `docs/ADR.md`, socle commun) plus les champs de synchro :

**Table `intervention` locale** : tous les champs du modèle serveur + `idServeur`, `statutSync` (LOCAL, ENVOYE, CONFIRME), `modifieLocalementLe`.

**Table `photo` locale** : `idLocal`, `interventionIdLocal`, `categorie` (AVANT, APRES), `cheminLocal` (fichier sur l'appareil), `statutSync`.

Une intervention n'est **jamais créée localement** dans le MVP : elle arrive par la synchro. Le technicien ne modifie que `problemeConstate`, `travauxRealises`, les photos, et passe le statut à `REALISEE` avec `dateRealisation`.

**Implémenté (2026-09-12)** avec Drift : `Interventions`/`Photos` sont des tables Drift dans `data/local_db.dart`, `idServeur` est la clé primaire d'`Interventions` (jamais de ligne locale sans identifiant serveur). Pas de `models/intervention.dart` ni `models/photo.dart` séparés : Drift génère déjà les classes `Intervention`/`Photo` à partir des tables, les dupliquer à la main serait une double maintenance sans bénéfice. `models/enums.dart` reste nécessaire (les enums, eux, ne sont pas générés par Drift). Statut de synchro par défaut : `CONFIRME` pour une intervention reçue par pull, `LOCAL` pour une photo prise sur le terrain.

---

## 4. Points de conception spécifiques au mobile

### Offline-first
- Tous les écrans lisent la **base locale** via les providers Riverpod. Aucun écran ne dépend d'un appel réseau pour s'afficher ou pour enregistrer.
- `sync_service.dart` parle à l'API pour toute écriture (push/pull). `AuthService.nomTechnicien()` (`GET /auth/moi`) est la seule lecture réseau hors synchro, purement pour un affichage opportuniste (voir ci-dessous) : jamais bloquante, jamais indispensable.

### Session (US4.2)
- Le JWT est conservé en **stockage sécurisé** (longue durée, 30 jours). Au lancement, si un token est présent, on va directement sur `MesInterventionsScreen` sans appel réseau.
- `GET /auth/moi` n'est appelé qu'en opportuniste quand le réseau est disponible (implémenté le 2026-09-14, voir "Nom du technicien" ci-dessous — US2.1, pas US4.2 : ce n'est pas utilisé pour valider la session).
- Après une connexion réussie : `Navigator.pushReplacement` vers `MesInterventionsScreen` (interdit de revenir à la connexion).

### Synchronisation (US2.11)
Déclenchée au retour de connectivité, au passage de l'app au premier plan, ou par un tirer-pour-rafraîchir.
1. **Push** : pour chaque intervention `statutSync = LOCAL`, `POST /sync/interventions` (lot des clôtures) puis `POST /interventions/:id/photos` (multipart, une par photo). Marquage `ENVOYE` puis `CONFIRME` à la confirmation serveur.
2. **Conflit** : si le serveur renvoie `CONFLIT` (intervention annulée entre-temps), la clôture locale est abandonnée, l'intervention est retirée de la liste, et le technicien est prévenu. **L'annulation du directeur gagne.**
3. **Pull** : `GET /sync/interventions?depuis=<dernier misAJourLe reçu>`, upsert dans la base locale.

**Pull implémenté (2026-09-13)** : `sync_service.dart`. `InterventionDao.derniereMiseAJour()` sert de curseur `depuis` (le plus récent `misAJourLe` connu localement, `null` = première synchro, tout est demandé). Le badge « synchronisée » lit directement `intervention.statutSync` sur chaque ligne (pas de provider dédié).

**Déclenchement au retour de connectivité implémenté (2026-09-14)** : `MesInterventionsScreen` s'abonne à `Connectivity().onConnectivityChanged` (`connectivity_plus`) dans `initState()`, résilié dans `dispose()`. `_etaitConnecte` démarre à `true` (l'ouverture d'écran déclenche déjà sa propre synchro via le `postFrameCallback` existant, pas besoin de la dupliquer sur le premier événement du flux) ; seule une **transition** vers connecté après une coupure détectée relance `_synchroniser()`. Le flux `onConnectivityChanged` ne garantit que le statut radio (Wi-Fi/données actives), pas que le serveur soit joignable — c'est `_synchroniser()` et son message d'erreur explicite qui gèrent ce cas. Testé via `ConnectivityPlatform.instance` remplacé par une fausse implémentation (`connectivity_plus_platform_interface` + `plugin_platform_interface`, déjà transitifs, déclarés en `dev_dependencies`), seule façon réaliste de simuler une coupure/reconnexion sans canal de plateforme réel.

**Bandeau hors ligne implémenté (2026-09-14)** : fidèle à l'état "Hors ligne" de `M2 - Mes interventions.html` (icône `wifi_off`, fond `--warning-bg` `#FEF3C7`, texte "Hors ligne — données locales"), affiché entre l'en-tête et les onglets quand `_horsLigne = true`. Deux sources mettent `_horsLigne` à jour : `Connectivity().checkConnectivity()` appelé une fois dans `initState()` (le premier événement du flux `onConnectivityChanged` n'est pas garanti immédiat selon la plateforme, sans ce contrôle explicite le bandeau pourrait mettre une fraction de seconde à apparaître si l'appareil est déjà hors ligne au lancement) et chaque événement de `_surChangementConnectivite` (contrairement au déclenchement de synchro, qui ne réagit qu'aux **transitions**, le bandeau reflète l'état courant à chaque événement).

**Indicateur de dernière synchro implémenté (2026-09-14)** : `_metaSynchro()` (ligne `sync-meta` de la maquette) affiche "Synchronisé à l'instant" / "... il y a X min" / "... il y a X h" / "Dernière synchro : jj/mm · HH:mm" au-delà de 24h, dérivé de `_derniereSynchro` (`DateTime?`, mis à jour à chaque synchro réussie dans `_synchroniser()`). Le texte ne se rafraîchit pas tout seul avec le temps qui passe (pas de `Timer` périodique) : il se met à jour à la prochaine synchro ou au prochain rebuild de l'écran, ce qui est suffisant en usage réel (le technicien resynchronise régulièrement).

**Persistance implémentée (2026-09-14)** : initialement non persisté (réinitialisé à chaque ouverture d'écran), noté et accepté comme dette mineure, puis traité à la demande de Cédric. `SyncService.synchroniser()` écrit l'heure de succès dans `TokenStorage` (nouvelle clé `cleDerniereSynchro`, réutilise l'abstraction déjà en place pour le JWT — aucun nouveau package, pas de `shared_preferences`) ; `SyncService.derniereSynchroReussie()` la relit. `MesInterventionsScreen._chargerDerniereSynchroPersistee()` charge cette valeur au démarrage **en complément** de la synchro fraîche déclenchée par le `postFrameCallback`, sans l'écraser si celle-ci a déjà abouti (`_derniereSynchro == null` revérifié à la résolution de la lecture, pas seulement au lancement — la lecture du stockage sécurisé est généralement plus rapide qu'un aller-retour réseau, mais rien ne le garantit). Effet concret : l'indicateur affiche la dernière synchro connue même si l'app vient d'être relancée et que la synchro automatique d'ouverture échoue (hors ligne, serveur injoignable...).

**Nom du technicien implémenté (2026-09-14)** : `AuthService.nomTechnicien()` (`GET /auth/moi`, opportuniste) complète `_metaSynchro()` — même ligne que l'indicateur de synchro, séparés par un point médian quand les deux sont disponibles (fidèle à `<strong>Koffi N'Guessan</strong><span class="dot"></span>Dernière synchro : ...` de la maquette). `nomTechnicien()` ne lève jamais (`try/catch` large et documenté : hors ligne, jeton absent, jeton expiré renvoient simplement `null`, jamais une exception qui remonterait) — cohérent avec le principe "jamais bloquant" déjà appliqué à `GET /auth/moi` pour la session (US4.2). Appelé une seule fois par ouverture d'écran (`initState`, en parallèle de la synchro, pas à chaque synchro : le nom ne change quasiment jamais). `authServiceProvider` ajouté à `interventions_provider.dart` (`MesInterventionsScreen` suit le style Riverpod des autres écrans avancés, contrairement à `ConnexionScreen`/`SplashScreen` qui injectent `AuthService` par le constructeur — deux styles cohabitent délibérément selon l'ancienneté de l'écran).

**Piège de test réel rencontré à ce ticket** : `MesInterventionsScreen` appelle désormais `AuthService` sans passer par le constructeur — un test qui ne surcharge pas `authServiceProvider` retombe sur le vrai `SecureTokenStorage`/`FlutterSecureStorage`, qui bloque indéfiniment en test (même piège que `SyncService` au ticket 7). `appTest()` (`test/support/app_test_scope.dart`) et `_appAvecClient()` (`mes_interventions_screen_test.dart`) surchargent désormais systématiquement les deux providers (`syncServiceProvider` **et** `authServiceProvider`) avec un `FakeTokenStorage()`. **Règle à retenir** : tout nouveau provider de service réseau/stockage ajouté à un écran doit être surchargé dans les helpers de test partagés dès son ajout, pas seulement dans le test qui l'exerce explicitement.

**Déclenchement au retour au premier plan implémenté (2026-09-14)** : `_MesInterventionsScreenState` applique `WidgetsBindingObserver` (`addObserver`/`removeObserver` dans `initState`/`dispose`), `didChangeAppLifecycleState(AppLifecycleState.resumed)` relance `_synchroniser()`. Pas de garde-fou type `_etaitConnecte` nécessaire ici : `didChangeAppLifecycleState` ne se déclenche que sur une vraie transition (jamais à froid au lancement), donc pas de doublon avec la synchro du `postFrameCallback`. Testé via `tester.binding.handleAppLifecycleStateChanged(...)` (API publique du binding de test Flutter). Les deux déclencheurs de la dette du ticket 7 (connectivité + premier plan) sont désormais réglés.

**Push des clotures implémenté (2026-09-14)** : `SyncService.pousserInterventions()` envoie `POST /sync/interventions` pour chaque intervention `statutSync = LOCAL` **et** `statut = REALISEE` (`InterventionDao.listerAPousser()` — une intervention seulement en cours de saisie, encore PLANIFIEE, n'a pas d'endpoint serveur pour une sauvegarde partielle et n'est donc jamais poussée). Ne fait aucun appel reseau si rien a pousser. Par resultat : `CONFIRME` marque la ligne `statutSync = CONFIRME` (`InterventionDao.marquerConfirmee()`) ; `CONFLIT` ne touche pas la ligne localement. `SyncService.synchroniser()` (nouvelle orchestration, appelee par le bouton/tirer-pour-rafraichir/ouverture de `MesInterventionsScreen` a la place de `tirerInterventions()` seul) pousse puis re-tire systematiquement : le pull qui suit un conflit **ecrase** la ligne locale avec l'etat serveur (upsert), ce qui applique naturellement la regle "l'annulation du directeur gagne" sans logique de resolution dediee. Le technicien est prevenu par un `SnackBar` (`MesInterventionsScreen`) si `synchroniser()` renvoie au moins un conflit.

**Message d'erreur explicite (2026-09-14)** : le `catch` de `_synchroniser()` affichait un texte fixe "Vérifiez votre connexion" pour **n'importe quelle** exception, masquant la vraie cause (bug applicatif, fichier photo manquant...) derriere un message qui n'était vrai qu'en cas de reseau realllement coupé. Corrigé : `ApiException` affiche le code et le message renvoyes par le serveur (`Erreur du serveur (500) : ...`), toute autre erreur affiche `Synchronisation impossible : <erreur>`. Trouvé en diagnostiquant un vrai cas Cédric (bouton de synchro sur le téléphone, Wi-Fi qui fonctionne, message "vérifiez votre connexion" trompeur).

**Push des photos implémenté (2026-09-14)** : `SyncService.pousserPhotos()` envoie `POST /interventions/:id/photos` (multipart, `ApiClient.postFichier()`) pour chaque `Photo` `statutSync = LOCAL`, une par une. Succès : `PhotoDao.marquerConfirmee()` enregistre l'`idServeur` renvoyé et passe `statutSync = CONFIRME`. Un **409** (deja 2 photos de cette categorie côté serveur — ex. retentative après un crash juste après un upload reussi) est compté comme échec sans arrêter les photos suivantes ; toute autre erreur (réseau, 401...) remonte et interrompt la boucle. Type MIME déduit de l'extension du fichier local (jpg/jpeg/png/webp), `image/jpeg` par défaut. Appelé par `SyncService.synchroniser()` juste après le push des clôtures, avant le pull final.

**Agrégation du statut de synchro des photos implémentée (2026-09-14)** : une intervention peut avoir sa clôture confirmée (`statutSync = CONFIRME`) tout en ayant des photos encore `LOCAL` (échec/retentative partielle du push photos). `PhotoDao.watchNonConfirmees()` + `interventionsAvecPhotosEnAttenteProvider` (`Set<String>` des `interventionIdLocal` concernés) permettent à `MesInterventionsScreen` (badge de tuile : « Photos à synchroniser ») et `CompleterInterventionScreen` (bandeau de succès : « PHOTOS À SYNCHRONISER ») de distinguer ce cas de « Synchronisée » / « À synchroniser ».

**Bug réel diagnostiqué et corrigé — photo bloquée en retentative infinie sans feedback (2026-09-14)** : Cédric a signalé une intervention affichant « Photos à synchroniser » sans que le bouton de synchro ne résorbe jamais l'état. Diagnostic par inspection directe de la base locale de l'appareil (`adb shell run-as <package> ls .../app_flutter/` puis `adb exec-out run-as <package> cat .../*.sqlite > copie.sqlite`, `MSYS_NO_PATHCONV=1` obligatoire sous Git Bash Windows pour un chemin `/data/data/...`) croisée avec la base Postgres serveur : une photo AVANT locale (`statutSync = LOCAL`) se heurtait à un **409** (`POST /interventions/:id/photos`, catégorie déjà à 2 photos côté serveur, données de test obsolètes). `pousserPhotos()` traitait alors tout 409 comme « déjà envoyée, sans danger à ignorer » — vrai seulement pour la retentative d'une *même* photo, faux pour une catégorie pleine à cause d'*autres* photos : la photo restait `LOCAL` indéfiniment, retentée à chaque synchro, sans jamais aboutir ni prévenir le technicien (aucun mécanisme de pull des photos n'existe côté mobile pour corriger l'état autrement). Déblocage immédiat par nettoyage des données de test obsolètes (2 lignes `Photo` + 2 fichiers, base partagée de dev — dette déjà notée dans la mémoire projet), puis correction du bug de conception à la demande explicite de Cédric :
- Nouvel état `StatutSync.conflit` (`models/enums.dart`) : un 409 marque désormais la photo `conflit` (`PhotoDao.marquerEnConflit()`) plutôt que de la laisser `LOCAL` — exclue de `listerAPousser()` (qui ne filtre que `LOCAL`), donc plus jamais retentée automatiquement. Toute autre erreur (réseau, 401...) continue de remonter et d'interrompre la boucle, comportement inchangé.
- `SyncService.synchroniser()` renvoie désormais `ResultatSynchro` (`conflitsClotures`, `photosEnConflit`) au lieu d'un simple `int` — les deux compteurs de conflit (clôtures annulées, photos définitivement refusées) restent distincts car ce sont deux causes différentes côté technicien.
- Signalement au technicien à deux niveaux, priorité **« Photo en échec » au-dessus de « Photos à synchroniser »** (un conflit définitif ne se résorbera jamais tout seul, contrairement à une simple attente) : badge rouge/`danger` sur la tuile (`MesInterventionsScreen._tuile()`) et bandeau « PHOTO EN ÉCHEC » (`CompleterInterventionScreen._bandeauSucces()`), plus un `SnackBar` ponctuel à la fin du cycle de synchro (`_messageResultatSynchro()`, `MesInterventionsScreen`) si `photosEnConflit > 0` et/ou `conflitsClotures > 0`.
- `PhotoDao.watchEnConflit()` (nouveau, symétrique à `watchNonConfirmees()`) + `interventionsAvecPhotosEnConflitProvider` alimentent le badge, même schéma que le provider « photos en attente » du ticket précédent.
- **Limite acceptée** : la photo en conflit reste visible et non supprimable automatiquement — aucun mécanisme de pull des photos n'existe côté mobile (hors périmètre de ce ticket), le technicien doit constater l'échec et reprendre la photo manuellement si besoin (suppression + nouvelle capture). Traiter un pull des photos serait une dette technique séparée, à ne soulever que si le cas se reproduit avec de vraies données (pas un doublon de catégorie côté serveur dû à des données de test).

**Piège de test découvert à cette occasion** : un `testWidgets` qui laisse la synchro automatique d'ouverture de `MesInterventionsScreen` exercer le vrai chemin d'upload de photo (`http.MultipartFile.fromPath`, I/O fichier réelle) reste bloqué indéfiniment, **même avec un fichier existant** — l'horloge simulée (`FakeAsync`) des `testWidgets` ne fait avancer que les `Timer`/microtasks Dart, pas les opérations `dart:io` réelles (mêmes tests en `test()` pur, asynchrone réel, fonctionnent). Contrairement au piège du timer Drift #3323, un `pump()` supplémentaire ne suffit pas à le débloquer. **Règle à retenir** : ne jamais laisser un `testWidgets` atteindre le vrai chemin d'upload (photo ou tout futur appel `dart:io` réel type fichier/socket) — semer les données locales *après* que la synchro automatique d'ouverture soit déjà passée (`pumpAndSettle` avant d'insérer), ou fournir un client qui ne déclenche jamais cet appel.

### Saisie au fil de l'eau (US2.9) — implémenté le 2026-09-13
- `InterventionDao.mettreAJourSaisie()` : chaque textarea a son propre anti-rebond (`Timer` 400 ms) sur `CompleterInterventionScreen`, écrit dans la base locale des que l'utilisateur arrete de taper, marque `statutSync = LOCAL`. Pas de bouton Enregistrer. À la réouverture, les valeurs saisies sont présentes (relues depuis la base au premier chargement de l'écran, jamais réécrasées ensuite par le flux réactif pour ne pas entrer en conflit avec la saisie en cours).
- **Flush au `dispose()` implémenté (2026-09-14)** : si l'utilisateur quitte l'écran dans les 400 ms suivant sa dernière frappe (anti-rebond pas encore déclenché), `_flushSaisieEnAttente()` force l'écriture du texte courant du/des champ(s) concerné(s) — vérifié via `Timer.isActive` sur `_debounceProbleme`/`_debounceTravaux`. Écriture fire-and-forget (non `await`-able, `dispose()` est synchrone) : sans risque, `AppDatabase` est un singleton gardé par `databaseProvider`, jamais lui-même disposé avec cet écran. **Piège Riverpod rencontré** : `ref.read(...)` lève `StateError` ("Using ref when a widget is about to or has been unmounted is unsafe") s'il est appelé depuis `dispose()` — corrigé en capturant `InterventionDao` dans un champ (`late final _interventionDao`) au moment de `initState()` plutôt que de relire le provider à la fermeture ; c'est la solution recommandée par le message d'erreur de Riverpod lui-même.
- **Bug réel diagnostiqué et corrigé — course entre l'anti-rebond et la clôture (2026-09-14)** : `_peutCloturer` (bouton Clôturer actif) lit le texte des `TextEditingController`, pas la base — donc le bouton s'active dès la frappe, avant que l'anti-rebond (400 ms) n'ait écrit ce texte en base. `_demanderCloture()` appelait `dao.cloturer()` (qui ne touche que `statut`/`statutSync`/`dateRealisation`, jamais `problemeConstate`/`travauxRealises`) sans jamais forcer cette écriture au préalable : une clôture juste après une frappe rapide (avant les 400 ms, malgré la modale de confirmation entre les deux) pouvait donc faire passer `statut = REALISEE` avec `problemeConstate`/`travauxRealises` encore vides en base. Trouvé en diagnostiquant un vrai cas Cédric : une intervention de test coincée en boucle sur une erreur `400` du serveur (`problemeConstate should not be empty...`) à chaque synchro, qui bloquait aussi la synchro des autres clôtures en attente du même appareil (`POST /sync/interventions` valide tout le lot d'un coup, `ParseArrayPipe` refuse la requête entière si un seul élément est invalide — fragilité connue, notée en dette technique, non corrigée à la demande de Cédric puisque ce bug précis ne devrait plus se reproduire). Corrigé : `_flushSaisieEnAttente()` généralisée (annule aussi les `Timer`, pas seulement `dispose()`) et `await`ée en tête de `_demanderCloture()`, juste après la confirmation, avant `dao.cloturer()`. Test de régression écrit avec des `pump(duration)` bornés (jamais `pumpAndSettle()`, qui avance l'horloge simulée par pas de 100 ms jusqu'à stabilisation et aurait lui-même déclenché l'anti-rebond, masquant la régression) — vérifié manuellement qu'il échoue sans le correctif avant de le committer.

### Clôture (US2.10) — implémenté le 2026-09-13
- Bouton Clôturer actif seulement si `problemeConstate` et `travauxRealises` sont non vides (verifie sur le texte des controleurs, pas seulement sur la base). **Le type d'équipement n'est pas requis** (US2.4 Nice to have).
- Modale de confirmation (bottom sheet) avant clôture : « Action définitive », Retour/Clôturer.
- À la clôture (`InterventionDao.cloturer()`) : `statut = REALISEE`, `dateRealisation = maintenant`, `statutSync = LOCAL`. L'écran passe en lecture seule (bandeau succès, champs en lecture seule, plus de barre du bas). Meme écran utilisé pour "Compléter" (PLANIFIEE) et "Voir le compte rendu" (REALISEE), le comportement change uniquement selon `statut`.

### Photos (US2.7, US2.8) — implémenté le 2026-09-13
- `PhotoStockageService.capturer()` : ouvre `image_picker` (appareil photo ou galerie, choix via une modale bottom sheet propre à l'app) puis copie immédiatement le fichier renvoyé dans un dossier permanent (`getApplicationDocumentsDirectory()/photos/`) — le fichier temporaire d'`image_picker` n'est pas garanti de survivre. `PhotoDao.ajouter()` marque la ligne `statutSync = LOCAL` (elle devra être poussée au serveur).
- Maximum 2 photos par catégorie (avant/après), vérifié côté écran : le bouton « Ajouter » disparaît au-delà. Retrait possible (bouton croix) tant que l'intervention n'est pas clôturée, via `PhotoDao.supprimer()` + suppression best-effort du fichier local (`PhotoStockageService.supprimerFichier()`). Une fois clôturée, les photos s'affichent en lecture seule, sans bouton Ajouter ni Supprimer.
- **Bordure pointillée implémentée (2026-09-14)** : `_BordurePointillee` (`CustomPainter` privé, `completer_intervention_screen.dart`) trace un rectangle à coins arrondis en tirets (`Path.computeMetrics()` + `extractPath()` sur un `RRect`) — Flutter n'a pas d'équivalent natif à `border-style: dashed`. Utilisé en `foregroundPainter` d'un `CustomPaint` autour du bouton « Ajouter » (`_boutonAjouterPhoto`), fidèle à `M4 - Completer intervention.html`.
- `PhotoDao.listerPourIntervention()` (lecture ponctuelle, ajoutée à ce ticket) complète `watchPourIntervention()` (flux réactif, utilisé par l'écran) : une nouvelle souscription `.watch()` programme un timer interne (issue connue simolus3/drift#3323, déjà documentée pour les écrans) qui ne se résout, en test widget, qu'avec un `pump()` supplémentaire — un aller simple évite le problème pour les vérifications ponctuelles dans les tests.
- Envoi des photos au serveur : voir "Push des photos" dans la section Synchronisation (US2.11) ci-dessus.

### Fidélité à la maquette de l'en-tête « Mes interventions » — complétée le 2026-09-14
Cédric a relevé, capture d'écran à l'appui, trois écarts entre `MesInterventionsScreen` et `M2 - Mes interventions.html` restés non traités depuis le ticket 6 : pas de ligne kicker date/heure au-dessus du titre, bouton de synchro sans le cadre carré ni le point d'état coloré de la maquette, pas de repère « Tirez pour synchroniser » au-dessus de la liste.
- **Kicker date/heure** : `_kickerDateHeure()`, trait de 16px + `formatJourDateHeure(DateTime.now())` (nouveau, `utils/date.dart`, ex. « Sam. 12 sept · 09:41 »), tout en capitales (`.toUpperCase()` — Flutter n'a pas d'équivalent à `text-transform: uppercase`). Purement décoratif, pas de `Timer` de rafraîchissement (même choix assumé que `_texteDerniereSynchro`, cf. ci-dessus) : se met à jour au prochain rebuild, pas seconde par seconde.
- **Bouton de synchro** : conteneur carré 36×36 à bordure (`--line`), coins à 6px, remplace l'`IconButton` nu. Un point d'état (8px, bordure `--paper` 2px, `Key('indicateurSynchro')`) se superpose en haut à droite, calculé par `_couleurIndicateurSynchro()` — **rouge** si au moins une photo est définitivement en conflit (priorité la plus haute, même hiérarchie que le badge de tuile), **orange** si une synchro est en cours ou s'il reste des clôtures/photos locales non confirmées, **vert** sinon. La maquette ne montre pas explicitement l'état rouge (seulement vert/orange) : extrapolation directe et cohérente avec le badge « Photo en échec » ajouté au ticket précédent, pas une invention.
- **Repère « Tirez pour synchroniser »** : `_indiceTirerPourSynchroniser()`, première entrée de la liste scrollable (pas un en-tête fixe) — comme dans la maquette, il défile avec le contenu et disparaît dès qu'on descend dans la liste. N'apparaît que si la liste filtrée n'est pas vide ; l'état vide garde son propre message (`_etatVide()`), non modifié par ce ticket (hors périmètre de la demande de Cédric, qui portait sur les trois points ci-dessus).
- 6 tests nouveaux (111 tests verts au total) : présence du kicker, présence/absence du repère selon liste vide ou non, couleur de l'indicateur pour les trois états.

### Références courtes (#0142) retirées de l'affichage — 2026-09-14
Cédric a demandé le retrait des références courtes (`referenceCourte()`, ex. `#0142`) affichées sur la tuile de `MesInterventionsScreen`, l'en-tête de `DetailInterventionScreen` et celui de `CompleterInterventionScreen` : sans utilité visuelle pour un technicien (il identifie une intervention par le nom du client et la date, jamais par cette référence). Même raisonnement déjà appliqué côté web le 2026-09-12 (colonne « Réf. » retirée du tableau liste, gardée sur le détail à l'époque) — ici le retrait va plus loin, sur les trois écrans mobile. Texte simplement retiré des lignes concernées (pas de remplacement) : la tuile ne garde que le badge de statut de synchro, l'en-tête de Détail ne garde que le bouton retour, l'en-tête de Compléter ne garde que « Compléter »/« Compte rendu ». **`lib/utils/reference.dart` (`referenceCourte()`) n'est plus appelé nulle part dans `lib/`** — laissé en place (jamais de suppression de fichier sans confirmation explicite), à supprimer si Cédric confirme qu'il ne sera pas réutilisé. 111 tests toujours verts (aucun test n'asserait sur ce texte).

### Google Maps et téléphone (US2.3)
- La géolocalisation ouvre Google Maps via `url_launcher` (`https://www.google.com/maps/dir/?api=1&destination=...` ou `geo:`). Si la géolocalisation est vide, seule l'adresse texte s'affiche.
- Les numéros de téléphone sont cliquables (`tel:`).

### State
- **Riverpod** (préféré sur nouveau projet, `FLUTTER_BEST_PRACTICES.md` §4). `Intervention.statut` est un state partagé (modifié par le directeur via la synchro, affiché sur la liste et le détail).

### Navigation
- Environ 4 écrans : `Navigator` avec `pushReplacement` après la connexion suffit. `go_router` optionnel, à soumettre à Cédric s'il est proposé.

### Typographie — Fraunces implémenté (2026-09-14)
- Police système par défaut de la Phase III jusqu'à ce ticket (dette notée au ticket 3, splash). Fraunces (titres, `DESIGN-SYSTEM.md`) est maintenant embarquée et appliquée partout où la maquette la prévoit : le monogramme « S » du splash, le titre « Bon retour. » (connexion), « Mes interventions » et l'état vide (Mes interventions), le nom du client (Détail et Compléter intervention), le titre de la modale de clôture. Repéré par recherche systématique de tous les `fontSize` ≥ 22 des écrans (motif Fraunces : `fontWeight.w400`, `letterSpacing` négatif, parfois un span en italique) — les textes italiques de type placeholder/valeur non renseignée restent volontairement en police système (pas des titres).
- **Fichiers embarqués, pas `google_fonts`** : l'app est offline-first (techniciens sans connexion fiable sur le terrain), un package qui télécharge la police au premier lancement est un mauvais fit. `assets/fonts/Fraunces-Variable.ttf` + `Fraunces-Italic-Variable.ttf` (polices variables, licence OFL, source `google/fonts` sur GitHub — `OFL.txt` inclus), déclarés dans `pubspec.yaml` (`flutter: fonts:`). Une police variable suffit pour toutes les graisses utilisées (400/500/600) via `fontWeight` standard ; les axes optiques `SOFT`/`WONK`/`opsz` de la maquette ne sont pas pilotés explicitement (valeurs par défaut de la police), écart mineur non perceptible pour l'usage terrain.

---

## 5. Besoins de packages (validés au fil des tickets)

Conformément à `FLUTTER_BEST_PRACTICES.md` §7, chaque package fait l'objet d'une shortlist présentée à Cédric avant installation.

- Base locale : **Drift** (`drift_flutter`), tranché le 2026-09-12 — pas Isar, dépôt original à l'arrêt.
- Stockage sécurisé du JWT : `flutter_secure_storage`, validé au ticket socle.
- Détection de connectivité : `connectivity_plus`, en usage depuis le 2026-09-14 (`MesInterventionsScreen`, cf. section 4). Tests : `connectivity_plus_platform_interface` + `plugin_platform_interface` en `dev_dependencies` (déjà transitifs, déclarés explicitement le 2026-09-14).
- Sélection d'image : `image_picker`, validé au ticket socle, en usage depuis le ticket Compléter intervention (US2.7/US2.8, `photo_stockage_service.dart`).
- Ouverture de liens : `url_launcher`, validé et installé au ticket Détail intervention (2026-09-13) — `tel:` pour les appels, `https://.../maps/dir/` pour l'itinéraire.
- Client HTTP : `http` (officiel Dart), en usage depuis le ticket service auth.
- Gestion d'état : `flutter_riverpod`, en usage depuis le ticket Mes interventions.
- Types MIME multipart : `http_parser`, validé le 2026-09-14 — dépendance transitive de `http` (aucun téléchargement supplémentaire), déclarée explicitement pour la classe `MediaType` (upload de photos, `ApiClient.postFichier()`).

---

## 6. Hors périmètre mobile pour le MVP

- Créer une intervention depuis le mobile (M. Kouassi crée toutes les interventions).
- Type d'équipement (US2.4) : colonne présente, nullable, pas d'UI de saisie.
- Consulter ses interventions déjà réalisées (US2.12).
- Se déconnecter (US4.3), changer son mot de passe (US4.8).
- Build iOS (Android en priorité).
