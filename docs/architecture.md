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
      auth_service.dart           (login, stockage sécurisé du JWT, lecture au démarrage)
      token_storage.dart          (abstraction testable sur flutter_secure_storage)
      sync_service.dart           (US2.11 : pull + push des clotures + push des photos, cf. section 4)
      photo_stockage_service.dart (US2.7/US2.8 : capture image_picker + copie dans le stockage permanent de l'app)
    data/
      local_db.dart               (base locale : tables intervention et photo + champs de synchro)
      dao/
        intervention_dao.dart     (watchAttribuees, watchParId, mettreAJourSaisie, cloturer, listerAPousser, marquerConfirmee, derniereMiseAJour)
        photo_dao.dart            (watchPourIntervention, listerPourIntervention, ajouter, supprimer, listerAPousser, marquerConfirmee)
    state/
      interventions_provider.dart (Riverpod : databaseProvider, liste attribuee US2.1, detail par id US2.2/US2.3, photos par intervention US2.7/US2.8, syncServiceProvider, photoStockageServiceProvider)
    theme/
      design_tokens.dart           (couleurs du design system, partagees entre ecrans)
    utils/
      reference.dart               (reference courte visuelle, miroir de web/.../lib/reference.ts)
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
- Seul `sync_service.dart` parle à l'API.

### Session (US4.2)
- Le JWT est conservé en **stockage sécurisé** (longue durée, 30 jours). Au lancement, si un token est présent, on va directement sur `MesInterventionsScreen` sans appel réseau.
- `GET /auth/moi` n'est appelé qu'en opportuniste quand le réseau est disponible.
- Après une connexion réussie : `Navigator.pushReplacement` vers `MesInterventionsScreen` (interdit de revenir à la connexion).

### Synchronisation (US2.11)
Déclenchée au retour de connectivité, au passage de l'app au premier plan, ou par un tirer-pour-rafraîchir.
1. **Push** : pour chaque intervention `statutSync = LOCAL`, `POST /sync/interventions` (lot des clôtures) puis `POST /interventions/:id/photos` (multipart, une par photo). Marquage `ENVOYE` puis `CONFIRME` à la confirmation serveur.
2. **Conflit** : si le serveur renvoie `CONFLIT` (intervention annulée entre-temps), la clôture locale est abandonnée, l'intervention est retirée de la liste, et le technicien est prévenu. **L'annulation du directeur gagne.**
3. **Pull** : `GET /sync/interventions?depuis=<dernier misAJourLe reçu>`, upsert dans la base locale.

**Pull implémenté (2026-09-13)** : `sync_service.dart`. `InterventionDao.derniereMiseAJour()` sert de curseur `depuis` (le plus récent `misAJourLe` connu localement, `null` = première synchro, tout est demandé). Déclencheurs presents : automatique à l'ouverture de `MesInterventionsScreen`, bouton dans l'en-tête, tirer-pour-rafraîchir. Déclencheurs **absents** (dépendent de capacités non construites) : retour de connectivité (`connectivity_plus` installé mais pas encore écouté) et passage au premier plan (`WidgetsBindingObserver` pas encore ajouté) — dette technique notée, pas oubliée. Le badge « synchronisée » lit directement `intervention.statutSync` sur chaque ligne (pas de provider dédié).

**Push des clotures implémenté (2026-09-14)** : `SyncService.pousserInterventions()` envoie `POST /sync/interventions` pour chaque intervention `statutSync = LOCAL` **et** `statut = REALISEE` (`InterventionDao.listerAPousser()` — une intervention seulement en cours de saisie, encore PLANIFIEE, n'a pas d'endpoint serveur pour une sauvegarde partielle et n'est donc jamais poussée). Ne fait aucun appel reseau si rien a pousser. Par resultat : `CONFIRME` marque la ligne `statutSync = CONFIRME` (`InterventionDao.marquerConfirmee()`) ; `CONFLIT` ne touche pas la ligne localement. `SyncService.synchroniser()` (nouvelle orchestration, appelee par le bouton/tirer-pour-rafraichir/ouverture de `MesInterventionsScreen` a la place de `tirerInterventions()` seul) pousse puis re-tire systematiquement : le pull qui suit un conflit **ecrase** la ligne locale avec l'etat serveur (upsert), ce qui applique naturellement la regle "l'annulation du directeur gagne" sans logique de resolution dediee. Le technicien est prevenu par un `SnackBar` (`MesInterventionsScreen`) si `synchroniser()` renvoie au moins un conflit.

**Push des photos implémenté (2026-09-14)** : `SyncService.pousserPhotos()` envoie `POST /interventions/:id/photos` (multipart, `ApiClient.postFichier()`) pour chaque `Photo` `statutSync = LOCAL`, une par une. Succès : `PhotoDao.marquerConfirmee()` enregistre l'`idServeur` renvoyé et passe `statutSync = CONFIRME`. Un **409** (deja 2 photos de cette categorie côté serveur — ex. retentative après un crash juste après un upload reussi) est compté comme échec sans arrêter les photos suivantes ; toute autre erreur (réseau, 401...) remonte et interrompt la boucle. Chaque `Photo` garde son propre `statutSync`, jamais agrégé dans le badge de l'intervention (dette technique mineure assumée : pas d'indicateur visuel si des photos restent à synchroniser). Type MIME déduit de l'extension du fichier local (jpg/jpeg/png/webp), `image/jpeg` par défaut. Appelé par `SyncService.synchroniser()` juste après le push des clôtures, avant le pull final.

### Saisie au fil de l'eau (US2.9) — implémenté le 2026-09-13
- `InterventionDao.mettreAJourSaisie()` : chaque textarea a son propre anti-rebond (`Timer` 400 ms) sur `CompleterInterventionScreen`, écrit dans la base locale des que l'utilisateur arrete de taper, marque `statutSync = LOCAL`. Pas de bouton Enregistrer. À la réouverture, les valeurs saisies sont présentes (relues depuis la base au premier chargement de l'écran, jamais réécrasées ensuite par le flux réactif pour ne pas entrer en conflit avec la saisie en cours).
- Limite acceptée : si l'utilisateur quitte l'écran dans les 400 ms suivant sa dernière frappe, ce dernier fragment de texte peut ne pas être sauvegardé (pas de flush forcé au `dispose()`). Edge case mineur, non traité pour l'instant.

### Clôture (US2.10) — implémenté le 2026-09-13
- Bouton Clôturer actif seulement si `problemeConstate` et `travauxRealises` sont non vides (verifie sur le texte des controleurs, pas seulement sur la base). **Le type d'équipement n'est pas requis** (US2.4 Nice to have).
- Modale de confirmation (bottom sheet) avant clôture : « Action définitive », Retour/Clôturer.
- À la clôture (`InterventionDao.cloturer()`) : `statut = REALISEE`, `dateRealisation = maintenant`, `statutSync = LOCAL`. L'écran passe en lecture seule (bandeau succès, champs en lecture seule, plus de barre du bas). Meme écran utilisé pour "Compléter" (PLANIFIEE) et "Voir le compte rendu" (REALISEE), le comportement change uniquement selon `statut`.

### Photos (US2.7, US2.8) — implémenté le 2026-09-13
- `PhotoStockageService.capturer()` : ouvre `image_picker` (appareil photo ou galerie, choix via une modale bottom sheet propre à l'app) puis copie immédiatement le fichier renvoyé dans un dossier permanent (`getApplicationDocumentsDirectory()/photos/`) — le fichier temporaire d'`image_picker` n'est pas garanti de survivre. `PhotoDao.ajouter()` marque la ligne `statutSync = LOCAL` (elle devra être poussée au serveur).
- Maximum 2 photos par catégorie (avant/après), vérifié côté écran : le bouton « Ajouter » disparaît au-delà. Retrait possible (bouton croix) tant que l'intervention n'est pas clôturée, via `PhotoDao.supprimer()` + suppression best-effort du fichier local (`PhotoStockageService.supprimerFichier()`). Une fois clôturée, les photos s'affichent en lecture seule, sans bouton Ajouter ni Supprimer.
- Écart visuel assumé par rapport à la maquette `M4 - Completer intervention.html` : bordure pleine au lieu de pointillée sur le bouton « Ajouter » (pas de support natif pour les bordures en pointillés sans `CustomPainter` dédié) — dette technique mineure, purement esthétique.
- `PhotoDao.listerPourIntervention()` (lecture ponctuelle, ajoutée à ce ticket) complète `watchPourIntervention()` (flux réactif, utilisé par l'écran) : une nouvelle souscription `.watch()` programme un timer interne (issue connue simolus3/drift#3323, déjà documentée pour les écrans) qui ne se résout, en test widget, qu'avec un `pump()` supplémentaire — un aller simple évite le problème pour les vérifications ponctuelles dans les tests.
- Envoi des photos au serveur : voir "Push des photos" dans la section Synchronisation (US2.11) ci-dessus.

### Google Maps et téléphone (US2.3)
- La géolocalisation ouvre Google Maps via `url_launcher` (`https://www.google.com/maps/dir/?api=1&destination=...` ou `geo:`). Si la géolocalisation est vide, seule l'adresse texte s'affiche.
- Les numéros de téléphone sont cliquables (`tel:`).

### State
- **Riverpod** (préféré sur nouveau projet, `FLUTTER_BEST_PRACTICES.md` §4). `Intervention.statut` est un state partagé (modifié par le directeur via la synchro, affiché sur la liste et le détail).

### Navigation
- Environ 4 écrans : `Navigator` avec `pushReplacement` après la connexion suffit. `go_router` optionnel, à soumettre à Cédric s'il est proposé.

---

## 5. Besoins de packages (validés au fil des tickets)

Conformément à `FLUTTER_BEST_PRACTICES.md` §7, chaque package fait l'objet d'une shortlist présentée à Cédric avant installation.

- Base locale : **Drift** (`drift_flutter`), tranché le 2026-09-12 — pas Isar, dépôt original à l'arrêt.
- Stockage sécurisé du JWT : `flutter_secure_storage`, validé au ticket socle.
- Détection de connectivité : `connectivity_plus`, installé mais pas encore écouté (cf. section 4).
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
