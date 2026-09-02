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
    models/
      intervention.dart           (aligné sur les DTO backend)
      photo.dart
      utilisateur.dart
    screens/
      connexion_screen.dart
      mes_interventions_screen.dart
      detail_intervention_screen.dart
      completer_intervention_screen.dart
    widgets/                       (un widget réutilisable par fichier : InterventionTile, PhotoPickerSection, SyncBadge, EtatVide, EtatErreur)
    services/
      api_client.dart             (wrapper réseau, ajoute le JWT, base = config API_URL)
      auth_service.dart           (login, stockage sécurisé du JWT, lecture au démarrage)
      sync_service.dart           (détection de connectivité, push des LOCAL, pull delta, résolution de conflit)
    data/
      local_db.dart               (base locale : tables intervention et photo + champs de synchro)
      dao/
        intervention_dao.dart
        photo_dao.dart
    state/
      session_provider.dart       (Riverpod : état de session)
      interventions_provider.dart (Riverpod : liste et détail depuis la base locale)
      sync_status_provider.dart   (Riverpod : état de synchro par intervention)
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
- `sync_status_provider` alimente le badge « synchronisée » par intervention.

### Saisie au fil de l'eau (US2.9)
- Chaque modification de champ sur `CompleterInterventionScreen` écrit immédiatement dans la base locale (léger anti-rebond sur les champs texte). Pas de bouton Enregistrer. À la réouverture, les valeurs saisies sont présentes.

### Clôture (US2.10)
- Bouton Clôturer actif seulement si `problemeConstate` et `travauxRealises` sont non vides. **Le type d'équipement n'est pas requis** (US2.4 Nice to have).
- À la clôture : `statut = REALISEE`, `dateRealisation = maintenant`, `statutSync = LOCAL`. L'écran passe en lecture seule.

### Photos (US2.7, US2.8)
- `image_picker` : appareil photo ou galerie. Maximum 2 par catégorie. Fichiers stockés sur l'appareil, chemin dans `photo.cheminLocal`. Retrait possible tant que l'intervention n'est pas clôturée. Envoi lors de la synchro.

### Google Maps et téléphone (US2.3)
- La géolocalisation ouvre Google Maps via `url_launcher` (`https://www.google.com/maps/dir/?api=1&destination=...` ou `geo:`). Si la géolocalisation est vide, seule l'adresse texte s'affiche.
- Les numéros de téléphone sont cliquables (`tel:`).

### State
- **Riverpod** (préféré sur nouveau projet, `FLUTTER_BEST_PRACTICES.md` §4). `Intervention.statut` est un state partagé (modifié par le directeur via la synchro, affiché sur la liste et le détail).

### Navigation
- Environ 4 écrans : `Navigator` avec `pushReplacement` après la connexion suffit. `go_router` optionnel, à soumettre à Cédric s'il est proposé.

---

## 5. Besoins de packages (shortlist à valider en Phase III)

Conformément à `FLUTTER_BEST_PRACTICES.md` §7, chaque package fait l'objet d'une shortlist de 2 à 3 candidats présentée à Cédric avant installation. Besoins prévus :

- Base locale : **Drift** ou **Isar** (choix structurant, à trancher).
- Stockage sécurisé du JWT : `flutter_secure_storage` ou équivalent.
- Détection de connectivité : `connectivity_plus` ou équivalent.
- Sélection d'image : `image_picker` ou équivalent.
- Ouverture de liens : `url_launcher`.
- Client HTTP : `http` (officiel Dart) en premier choix.
- Gestion d'état : `flutter_riverpod`.

---

## 6. Hors périmètre mobile pour le MVP

- Créer une intervention depuis le mobile (M. Kouassi crée toutes les interventions).
- Type d'équipement (US2.4) : colonne présente, nullable, pas d'UI de saisie.
- Consulter ses interventions déjà réalisées (US2.12).
- Se déconnecter (US4.3), changer son mot de passe (US4.8).
- Build iOS (Android en priorité).
