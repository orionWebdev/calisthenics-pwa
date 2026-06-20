# ATEM Hybrid — Redesign-Konzept („Großer Wurf")

> Ziel: Neue Informationsarchitektur **und** neue visuelle Sprache, aufbauend auf
> der Marke ATEM (dark premium, WHOOP/Oura-Liga). Grundlage: `REDESIGN_INVENTORY.md`.

---

## 1. Designprinzipien (Leitplanken)

1. **Datengetrieben & ruhig** — Zahlen sind die Helden, Chrome verschwindet. Viel Schwarz, ein Akzent.
2. **Ein Akzent, klar gesetzt** — Pink nur für Aktion/Status, nie als Deko-Flut.
3. **Form-Status als rote Linie** — die Form-Zone (`exhausted → peak_form`) ist das Herz und zieht sich durch Dashboard, Progress, Recommendation.
4. **Mobile-first, daumenfreundlich** — Primäraktionen unten erreichbar, große Touch-Targets, Bottom-Sheets statt Center-Modals.
5. **Progressive Disclosure** — Einfach starten (Quick-Log), Tiefe auf Abruf (Advanced-Sektionen, Detail-Charts).
6. **Eine Quelle der Wahrheit** — alle Farben/Abstände/Komponenten aus dem Design-System, kein Hardcoding mehr.

---

## 2. Markenentscheidung (Drift auflösen)

**Verbindlich festlegen (Empfehlung):**

| Token | Entscheidung | Begründung |
| --- | --- | --- |
| **Primär** | `#C01963` | Offizielle Markenfarbe (Memory). `#F02277` wird zum helleren Gradient-/Hover-Stop. |
| **Hintergrund** | `#000000` (Dark, default) | IST-Zustand, wirkt am premiumsten; Navy verworfen. |
| **Akzent-Gradient** | `#C01963 → #F02277` | Für CTAs („Log Workout"), aktive Zustände. |
| **Font** | Zalando Sans Expanded | IST-Zustand, distinct & sportlich. |
| **Theme** | Dark default, Light als Option | beibehalten. |

> Diese Tabelle ist der einzige Ort, an dem die Markenfarbe definiert wird. README,
> PROJECT_CONTEXT.md, Memory und `tokens.css` werden danach angeglichen.

---

## 3. Neue Informationsarchitektur

### 3.1 Primärnavigation (vereinheitlicht)
4 feste Bereiche, identisch auf Mobile (Bottom-Nav) & Desktop:

```
[ Heute ]   [ Training ]   [ Fortschritt ]   [ Profil ]
  home       fitness_center    insights        account
```

- **FAB als zentrale Aktion** (statt redundantem Radial-Menü): „**+ Workout loggen**" — der eine, immer sichtbare Haupt-CTA. Öffnet ein Bottom-Sheet (Strength / Cardio / Recovery).
- Radial-Menü entfällt (war Duplikat der Bottom-Nav).
- Profil bekommt einen festen Nav-Slot statt verstecktem `more_horiz`.

### 3.2 Die vier Bereiche
| Bereich | Kern-Job | Inhalt |
| --- | --- | --- |
| **Heute** | „Was mache ich jetzt?" | Form-Status-Hero, Empfehlung, geplante Session, Quick-Stats, Plan-Kalender |
| **Training** | „Womit trainiere ich?" | Tabs Pläne / Übungen (Builder, DB, Filter, Picker) |
| **Fortschritt** | „Wie entwickle ich mich?" | **eine** konsolidierte Progress-Ansicht (v2/v3/v4 → v-final): Form-Kurve, Volumen, Aktivitäts-Kalender, Exercise-Detail |
| **Profil** | „Einstellungen & Account" | Theme, Sprache, Account, Legal, Vorlagen |

---

## 4. Visuelle Sprache (Komponenten-Stil)

- **Cards:** `#161618`, Radius 1–1.5rem, 1px subtile weiße Border (`rgba(255,255,255,.1)`), weicher Schatten. Hover = Border heller.
- **Status-Pills/Badges:** Form-Zonen-Farben als Tints (8 % Opazität) + farbiger Text/Dot — nie vollflächig grell.
- **Hero-Element (Form-Status):** großer Ring/Gauge mit Zonen-Farbverlauf, zentrale Kennzahl, ein Satz Klartext.
- **Buttons:** Primär = Gradient-Fill; Sekundär = 1px-Border transparent; Ghost = nur Text. Große Touch-Targets (≥44 px).
- **Bottom-Sheets:** Standard für Auswahl/Eingabe (Picker, Number-Picker, Quick-Log). Center-Modals nur für kurze Bestätigungen.
- **Icons:** Material Symbols Rounded, konsistente Größe/Strichstärke.
- **Charts:** dünne Linien, Zonen-Banding im Hintergrund, ein Akzent — kein Gitter-Lärm.

---

## 5. Design-System-Struktur (was wir in Claude Design bauen)

Komponenten-Bibliothek, hierarchisch — von Foundations zu Patterns:

```
Foundations
  ├─ Colors      (Brand, Background, Text, Border, Zonen, Kategorien, Sport)
  ├─ Typography  (Zalando Sans Expanded, Scale xs→4xl, Weights)
  ├─ Spacing     (xs→2xl) & Radius
  └─ Elevation   (Schatten, Surfaces)
Components
  ├─ Buttons     (Primär/Sekundär/Ghost/Icon, Größen, States)
  ├─ Cards       (Standard, Elevated, CTA-Gradient, Stat-Card)
  ├─ Badges/Pills (Difficulty, Form-Zone, Kategorie)
  ├─ Inputs      (Text, Number-Picker, Range-Slider, Pills/Chips)
  ├─ Navigation  (Bottom-Nav, Desktop-Nav, Segmented Control, FAB)
  ├─ Sheets/Modals (Bottom-Sheet, Center-Modal, Confirm)
  └─ Data Viz    (Form-Gauge, Sparkline, Weekly-Chart, Kalender-Cell)
Patterns
  ├─ Dashboard-Hero (Form-Status)
  ├─ Exercise-Card & Plan-Card
  ├─ Workout-Logger-Row (Set-Logging)
  └─ Quick-Log-Flow (Strength/Cardio/Recovery)
```

Jede Komponente lebt als HTML-Preview-Datei mit `@dsCard`-Marker → erscheint als Karte im Claude-Design-Panel.

---

## 6. Migration in Phasen (risikoarm, inkrementell)

| Phase | Inhalt | Ergebnis |
| --- | --- | --- |
| **0. Konsolidierung** | Markenentscheidung in `tokens.css` festschreiben, Doku/Memory angleichen, Progress auf eine Version | Sauberer IST-Stand |
| **1. Foundations** | Colors/Typo/Spacing/Radius als Komponenten → Claude Design hochladen | Token-Basis steht remote |
| **2. Core Components** | Buttons, Cards, Badges, Inputs, Nav | Bibliothek nutzbar |
| **3. Patterns** | Hero, Exercise/Plan-Card, Logger-Row, Quick-Log | App-spezifische Bausteine |
| **4. View-Umbau** | View für View gegen das System (Heute → Training → Fortschritt → Profil) | Redesign sichtbar |
| **5. Cleanup** | Tote CSS-Partials/Progress-Altlasten entfernen | Schlanke Codebasis |

**Wichtig:** Nie „alles auf einmal ersetzen". Jede Komponente einzeln, mit sichtbarem Vorher/Nachher.

---

## 7. Offene Entscheidungen (vor Phase 1 zu klären)

1. **Primärfarbe** final `#C01963`? (Empfehlung ja.)
2. **Navigation:** 4 Bereiche inkl. Profil-Slot + FAB als „Workout loggen" — ok?
3. **Progress-Konsolidierung:** auf welcher Version aufsetzen (v3 hat die meiste Logik)?
4. **Scope Phase 1:** nur Foundations zuerst, oder direkt Foundations + Core Components?
