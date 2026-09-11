# SIM Interventions — Design System v4

Direction : **Fiche technique éditoriale**
Toutes les valeurs ci-dessous sont exactes et prêtes à être recopiées dans Figma.

---

## 1. Palette (§2 du brief, non modifiée)

### Couleurs de marque
| Token | Hex | Usage |
|---|---|---|
| `--brand` | `#2563EB` | Liens, filet supérieur de page, focus rare |
| `--brand-hover` | `#1D4ED8` | Hover de --brand |
| `--brand-dark` | `#1E3A8A` | Non utilisé en v4 (réservé) |
| `--accent` | `#F59E0B` | Rare, mise en avant ponctuelle |

### Textes et surfaces
| Token | Hex | Usage |
|---|---|---|
| `--ink-1` | `#0F172A` | Titres, texte principal, bouton primaire |
| `--ink-2` | `#334155` | Texte secondaire fort |
| `--text-soft` | `#475569` | Labels, méta, texte descriptif |
| `--text-weak` | `#94A3B8` | Placeholders, texte "non renseigné", méta discrète |
| `--line` | `#E2E8F0` | Séparateurs standard, bordures d'input |
| `--line-strong` | `#CBD5E1` | Bordures accentuées, dashed |
| `--line-soft` | `#EEF2F6` | Séparateurs internes très discrets, hover, kbd |
| `--section` | `#F1F5F9` | Fonds de zone |
| `--surface` | `#FFFFFF` | Cartes, tableaux |
| `--paper` | `#FBFBF9` | **Fond général** (papier crème imperceptible) |
| `--paper-soft` | `#F5F5F1` | Zone posée (panneau gauche connexion, textarea readonly) |
| `--zebra` | `#FCFCFA` | Hover très léger des lignes de tableau |

### Statuts sémantiques
| Statut | Texte | Fond |
|---|---|---|
| Succès (Réalisée) | `#16A34A` | `#DCFCE7` |
| Alerte (Planifiée, À synchroniser) | `#D97706` | `#FEF3C7` |
| Erreur (Annulée, erreurs form) | `#DC2626` | `#FEE2E2` |
| Info (rare) | `#0891B2` | `#CFFAFE` |

---

## 2. Typographie

### Familles
| Rôle | Police | Fallback |
|---|---|---|
| **Titres éditoriaux** | Fraunces (variable) | ui-serif, Georgia, serif |
| **UI / corps** | Inter | system-ui, -apple-system, sans-serif |
| **Données techniques** | JetBrains Mono | ui-monospace, SFMono-Regular, Menlo |

### Fraunces — variations utilisées
```css
font-family: 'Fraunces', serif;
font-optical-sizing: auto;
font-variation-settings: "SOFT" 30, "WONK" 0;
letter-spacing: -0.02em;
```

### Échelle typographique
| Usage | Taille | Poids | Line-height | Letter-spacing |
|---|---|---|---|---|
| **Fraunces** – headline connexion web | 56 px | 400 | 1.02 | -0.035em |
| **Fraunces** – titre de page web | 44 px | 400 | 1.05 | -0.035em |
| **Fraunces** – headline mobile | 36 px | 400 | 1.05 | -0.03em |
| **Fraunces** – titre app mobile | 28-32 px | 400 | 1.05 | -0.03em |
| **Fraunces** – titre form / modal | 22-32 px | 400 | 1.15 | -0.025em |
| **Fraunces** – italique accent | (idem taille parent) | 400 italic | | |
| **Inter** – corps principal | 15 px | 400 | 1.5 | -0.003em |
| **Inter** – corps mobile | 16 px | 400 | 1.5 | -0.003em |
| **Inter** – lede / description | 14-15 px | 400 | 1.55 | -0.003em |
| **Inter** – labels form | 11 px | 600 | 1 | 0.12em uppercase |
| **Inter** – labels section | 10 px | 600 | 1 | 0.16em uppercase |
| **Inter** – label statut | 13 px | 500 | 1 | -0.003em |
| **Inter** – bouton | 13-15 px | 500 | 1 | -0.003em |
| **JetBrains Mono** – données/dates | 12-13 px | 500 | 1 | -0.005em |
| **JetBrains Mono** – références (#0142) | 11 px | 500-600 | 1 | 0.02em |
| **JetBrains Mono** – kbd | 10 px | 500 | 1 | 0.02em |

---

## 3. Spacing (multiples de 4)

| Token | Valeur | Usage |
|---|---|---|
| xs | 4 px | Micro-gaps entre éléments proches |
| sm | 8 px | Gaps de champs, entre bouton et icône |
| md | 12 px | Gaps standards |
| lg | 16 px | Padding intérieur, marges mobiles |
| xl | 20-24 px | Sections, cards |
| 2xl | 28-32 px | Séparation de blocs |
| 3xl | 40-48 px | Padding page desktop |
| 4xl | 56-80 px | Grands espaces éditoriaux (connexion) |

## 4. Rayons

| Token | Valeur | Usage |
|---|---|---|
| Sharp | 2 px | Photos, éléments architecturaux |
| Small | 6 px | Boutons, inputs, éléments interactifs |
| — | Aucun | La plupart des zones (bordures droites) |

**Principe v4** : rayons volontairement discrets. Pas de rounded-2xl à la SaaS.

---

## 5. Composants — spécifications

### Bouton primaire
```
Height: 36 px (compact) / 40 px (form) / 44-52 px (mobile)
Padding H: 14-20 px
Background: --ink-1 (#0F172A)
Text: white
Border: 1px solid --ink-1
Border-radius: 6 px
Font: Inter 13-15 px / 500 / -0.003em
Gap icône-label: 7-10 px
Hover: background #000
```

### Bouton secondaire
```
Height: idem primaire
Background: transparent
Text: --ink-1
Border: 1px solid --line (#E2E8F0)
Border-radius: 6 px
Hover: background --line-soft, border --line-strong
```

### Bouton ghost
```
Background: transparent
Text: --text-soft
Border: none
Hover: background --line-soft, text --ink-1
```

### Bouton danger (outline)
```
Background: transparent
Text: --danger
Border: 1px solid --danger
Hover: background --danger-bg
```

### Bouton danger (solid) — pour modales de confirmation
```
Background: --danger
Text: white
Border: 1px solid --danger
Hover: background #B91C1C
```

### Input (underline style — signature v4)
```
Height: variable, padding 8 px 0
Background: transparent
Border: none, sauf border-bottom 1px solid --line-strong
Font: Inter 16-17 px / 500 / -0.005em
Text color: --ink-1
Placeholder: --text-weak / 400
Focus: border-bottom-color --ink-1 (#0F172A)
Error: border-bottom-color --danger (#DC2626)
```

**Différence majeure vs classic** : pas de background, pas de rounded box.
Juste une ligne en dessous. Ça respire.

### Textarea (mobile M4)
Idem input underline, min-height 100 px, resize:none, font 16 px.

### Textarea readonly (M4 après clôture)
```
Background: --paper-soft
Padding: 12 px
Border: 1px solid --line
Border-radius: 2 px
```

### Chip / Status
Pas de "chip pill". Juste :
```
Layout: flex, align-center, gap 8-9 px
Text: Inter 13 px / 500 / --ink-1
Marker: carré 8×8 px, border-radius 1.5 px
Marker planifiée: background --warning (#D97706)
Marker réalisée: background --success (#16A34A)
Marker annulée: background --danger + text strikethrough
```

### Table (W2)
```
Header cell:
  Padding 16px 12px 12px
  Font Inter 10 px / 600
  Letter-spacing 0.14em uppercase
  Color --text-weak
  Border-bottom 1px solid --line

Body cell:
  Padding 16px 12px
  Font Inter 13 px / 400
  Color --ink-1
  Border-bottom 1px solid --line-soft

Row hover: background --zebra (#FCFCFA)
Row selected: background #F5F8FF
  + barre 2px --brand débordante à gauche (positioned absolute -40 px)
```

### Fiche / Détail (W4)
Structure grid 2 colonnes : 240 px meta side + 1fr content.
Pas de card. Séparateurs 1px --line et --line-soft.

### Modale de confirmation
```
Overlay: rgba(15,23,42,.55) + backdrop-blur 2px
Modal desktop:
  Width 440-480 px
  Background --paper
  Border 1px solid --line
  Border-top 2px solid --danger (ou --ink-1)
  Padding 32 px
  Box-shadow 0 40px 80px -20px rgba(15,23,42,.35)
Modal mobile: bottom-sheet, border-top 2px, padding 24 20
```

### Photos (vignettes)
```
Desktop détail: 120×90 px, aspect 4/3
Mobile M4: 88×88 px carré
Border: 1px solid --line
Border-radius: 2 px
Background placeholder: repeating-linear-gradient 45deg #E8E8E3, #EFEFEA
Tag (AVANT/APRES): background --ink-1, text white
  padding 2×5, JetBrains Mono 9px 500, letter-spacing 0.06em
Remove button (M4 rempli): cercle 20×20, fond rgba(15,23,42,.9)
```

### Rail navigation (Web, gauche)
```
Width: 56 px
Background: --paper
Border-right: 1px solid --line
Item: 36×36, padding centered, border-radius 6, color --text-soft
Item active: color --ink-1
  + barre 2px --ink-1 débordante à gauche (position:absolute left:-10, top:8, bottom:8)
Tooltip au hover: background --ink-1, text white, padding 5 9, radius 4
User (bas): 28×28, background --ink-1, text white, JetBrains Mono 10 px 600
Logo (haut): "S" en Fraunces 16 px 600, letter-spacing -0.04em
  + filet 14×1 --brand en dessous
```

### Cadre de page
```
Border-top: 2px solid --brand (#2563EB) — signature de marque
Border-left/right/bottom: 1px solid --line
Border-radius: 2 px
Background: --paper
```

---

## 6. Ornements éditoriaux (signatures v4)

### Filet-kicker
```
::before {
  content: "";
  display: inline-block;
  width: 16-32 px;
  height: 1px;
  background: --ink-1;
}
```
Placé avant les eyebrows / kickers de section.

### Filet-page top
Bord supérieur 2px `--brand` sur chaque frame de page.

### Blueprint dots (optionnel, non utilisé mais dispo)
```
background-image: radial-gradient(circle at 1px 1px, --line-strong 0.7px, transparent 0.7px);
background-size: 8px 1px;
background-repeat: repeat-x;
```

### Cadratins pour "non renseigné"
Toujours écrit `— non renseigné —` (avec cadratins Unicode, pas des tirets simples).

---

## 7. Iconographie

**Bibliothèque** : Lucide Icons (https://lucide.dev)
**Stroke-width** : 1.5 à 2 (en règle générale 1.75 pour UI, 1.5 pour décoratif)
**Tailles** : 11 (statusbar), 14 (boutons), 16 (nav mobile), 18 (rail), 20 (larges)

## 8. Statusbar mobile

```
Height: 24 px
Padding: 0 16 px
Background: --paper (transparent sur fond page)
Text color: --ink-1
Font: Inter 11 px / 600
Heure gauche: JetBrains Mono
Icones droite: 11×11, stroke 2, color --ink-1
Batterie: JetBrains Mono 10 px + icon lucide battery-medium
```

## 9. Gesture bar Android

```
Height: 20 px, padding-bottom 8 px
Bar: 112×4 px, border-radius 999, background --text-weak, opacity 0.4
```

---

## 10. Ton de langue

- Termes exacts du brief : "Planifiée", "Réalisée", "Annulée"
- "Problème constaté", "Travaux réalisés"
- "— non renseigné —" (avec cadratins)
- Titres avec italique accent sur mot clé : "Nouvelle *intervention*."
- Kickers : "Rendez-vous · 14/09/2026 · 09:00"
- Format date : `14/09/2026 · 09:00` (JetBrains Mono, séparateur ·)
- Références : `#0142` (mono, hash gris, numéro noir)
