# ATEM Hybrid — Vollständige Bestandsaufnahme (Redesign-Grundlage)

> Stand: Audit aus dem echten Code (nicht aus Doku/Memory). Diese Datei ist die
> Wahrheits-Quelle für das Redesign. README & PROJECT_CONTEXT.md sind teilweise
> veraltet — siehe Abschnitt „Design-Drift".

---

## 0. Kurzprofil

- **Typ:** Mobile-first PWA, Vanilla JS (kein Framework, kein Bundler), Firebase-Backend.
- **Umfang:** ~31.000 Zeilen JS, ~70 CSS-Partials, ~87 KB `index.html`.
- **Domäne:** Hybrid-Training (Kraft/Calisthenics + Cardio + Recovery) mit Belastungs- & Form-Analyse.
- **Vorbild-Ästhetik:** WHOOP / Oura — dark premium, datengetrieben, ohne Wearable.

---

## 1. Navigation & App-Shell

| Element | Inhalt |
| --- | --- |
| **Desktop-Nav** (floating, oben) | Dashboard · Training · Progress · Profil (Icon + Text) |
| **Mobile-Header** | View-Titel links · `more_horiz`-Button (→ Profil/Settings) rechts |
| **Bottom-Nav (Mobile)** | Home (Dashboard) · Progress · Training (3 Items + Indicator) |
| **FAB + Radial-Menü** | FAB (`fitness_center`); Radial öffnet Progress + Training |
| **Routing** | `showView('dashboard'|'training'|'progress'|'profile'|'workout')` in `app.js` |

> ⚠️ **Redundanz-Befund:** FAB-Radial (Progress/Training) dupliziert die Bottom-Nav.
> Profil ist mobil nur über ein `more_horiz`-Icon erreichbar. Kandidat für IA-Cleanup.

---

## 2. Views (Top-Level)

### 2.1 Auth
- **Splash** (`#auth-splash`) — Lade-/Init-Zustand
- **Login/Signup** (`#login-screen`) — E-Mail+Passwort, Name (Signup), Google Sign-In, Passwort-Reset, Sign-in/Sign-up-Umschalter, Footer/Legal
- **Auth-Error-Toast** (`#auth-error`)
- **Onboarding** (`onboarding.js`) — Erst-Setup, Profil-Defaults

### 2.2 Dashboard (`#view-dashboard`)
- Today-Header (Titel + Datum)
- Quick-Stats (Diese Woche / Bewegungsminuten)
- „Log Workout"-CTA-Card (Pink-Gradient)
- Today's Recommendation
- Scheduled Workouts Today
- Plan-Kalender-Widget (vorausschauend)

### 2.3 Training (`#view-training`) — Segmented Control, 2 Tabs
- **Tab Plans:** Header + Add-Button · Filter (Typ / Muskel / Equipment) · Plans-Grid
- **Tab Exercises:** Sticky-Suche · Filter-Chips (Muskel / Schwierigkeit / Equipment) · Active-Filter-Pills · Exercises-Grid

### 2.4 Progress (`#view-progress`) — Segmented Control + Tab-Content
- Mehrere Generationen koexistieren: `progressv2.js` (106 Fn), `progressv3.js` (158 Fn), CSS bis `progress-v4`
- Inhalte: Übersichts-Stats, Belastungs-/Form-Charts, Exercise-Detail-Charts, Aktivitäts-Kalender, Voll-Historie, Trainings-Charakter/Zonen

### 2.5 Workout (`#view-workout`) — Vollbild-Execution
- Container `#workout-screen-container`, gerendert aus `js/views/workout/*`
- Modi: Logger (normal), EMOM, Superset/Circuit, Timer/Rest
- Live-Set-Logging, Auto-Advance zwischen Blöcken, aktiver-Workout-Banner

### 2.6 Profile & Settings (`#view-profile`)
- Gerendert aus `settings.js` (62 Fn): Theme (Dark/Light), Sprache, Account löschen, Daten löschen, Acknowledgments/Legal

---

## 3. Modals & Bottom-Sheets (vollständig)

| Modal/Sheet | Zweck & Content-Elemente |
| --- | --- |
| `generic-modal` | Wiederverwendbarer Container (Titel + Body) |
| `exercise-modal` | Übung anlegen/bearbeiten. **S1:** Name, Typ-Pills, Muskelgruppen, Equipment, Schwierigkeit. **S2 (aufklappbar):** Instruktions-Schritte, Varianten, Advanced (Cues, häufige Fehler, Progressionen) |
| `quick-exercise-modal` | Schnell-Anlage: Name, Muskeln, Schwierigkeit |
| `plan-modal` | Plan anlegen. Basics (Name, Typ) · Strength-Übungen · Cardio (Aktivität, Distanz, Dauer, Ziel) · Recovery (Dauer) |
| `exercise-picker-modal` / `-sheet` | Multi-Select Übungsauswahl: Suche, Muskel-Filter-Chips, Add-Footer |
| `exercise-config-modal` | Konfiguration je Übung: Sets, Reps **oder** Hold, Rest (Range-Slider) |
| `block-type-sheet` | Blocktyp wählen: Normal / Superset / EMOM |
| `emom-config-modal` | EMOM: Intervall, Gesamtdauer, Übungen, Reps |
| `superset-config-modal` | Superset: Übungen, Rest |
| `multi-select bottom sheet` | Generische Mehrfachauswahl |
| `add-strength-modal` | Strength-Session loggen: Datum, Typ (Body/Weights), Name, Schwierigkeit, Dauer, Übungen |
| `add-cardio-modal` | Cardio loggen: Datum, Aktivität, Name, Dauer, Distanz, berechnetes Pace, Notizen |
| `add-recovery-modal` | Recovery loggen: Aktivität, Name, Dauer, Notizen |
| `session-template-modal` | Session-Vorlagen: Name, Typ, Trainingstyp, Fokus, Dauer, Distanz, Schwierigkeit, Notizen |
| `post-workout-summary-modal` | Zusammenfassung nach dem Workout |
| `activity-picker-sheet` | Aktivitätsauswahl |
| `plan-picker-sheet` | Plan einem Tag zuweisen |
| `bottom-sheet` (generisch) | Such-/Auswahl-Sheet mit Suchfeld |
| Number-Picker-Sheet | Numerische Eingabe (Sets/Reps/Gewicht/Zeit) |
| Workout-End-Confirm | Workout beenden/verwerfen bestätigen |

---

## 4. Wiederverwendbare UI-Primitive (`js/ui/`)

| Modul | Funktion |
| --- | --- |
| `bottomSheet.js` | Bottom-Sheet-Mechanik (öffnen/schließen, Suche, Auswahl) |
| `numberPickerSheet.js` | Zahlen-Picker (690 Z.) — Steps, Gewichts-Step-Modus |
| `swipeGesture.js` | Swipe-Gesten (Tabs/Karten) |
| `modalSwipe.js` | Modals per Swipe schließen |
| `ripple.js` | Material-Ripple-Effekt |
| `edgeFeedback.js` | Screen-Edge-Glow als haptisches Feedback |
| `keyboardInset.js` | Keyboard-Avoidance (mobile Inputs) |
| `muscleIcons.js` | Muskel-Icons |

---

## 5. Datenmodell (Firestore-Collections)

`exercises` · `plans` · `progress` · `schedule` · `sessions` · `sessionTemplates` · `userProfiles` · `workouts` · `allowedUsers` (Allowlist-Gate)

**Kern-Entities (aus `types.js`):**
- **Exercise** — `name`, `muscleGroups[]`, `difficulty`, `type`, `equipment[]`, `instructionsSteps[]`, `cues[]`, `commonMistakes[]`, `i18n.de`, `source: 'curated'`
- **Plan** — `name`, `type`, `items: PlanItem[]`
- **PlanItem** — `exerciseId`, `target{sets,reps,holdSec}`, `restSec`, `executionType`, Gruppen-/EMOM-/Interval-Felder
- **ExecutionType** — `normal | superset | circuit | emom | amrap | interval`
- **Session** — `type: strength|cardio|recovery`, `date`, `exercises[]`, `duration`, `planId`, `scheduleId`
- **ProgressEntry** — `exerciseId`, `date`, `sets[]`
- **ScheduleEntry** — `date (YYYY-MM-DD)`, `planId`, `planName`, `completed`, `sessionId`
- Alle Entities tragen `userId` (Multi-User-ready).

---

## 6. Funktionale Domänen (aus dem Funktions-Audit)

- **Aggregationen:** Cardio/Strength/Bodyweight/Dual — täglich, wöchentlich, monatlich, nach Periode (`aggregations-*.js`)
- **Scoring/Analytik:** Weekly-Score, Form-Score, Weighted-Load-Index, Trainings-Varianz, Hybrid-Balance, Session-Load (`scoring.js`, `training-character.js`)
- **Charts (Chart.js):** Sparklines, Weekly-Chart, Load-Index-Chart, Exercise-Detail-Chart, Bodyweight-Effort-Chart
- **Statistiken:** Streak, Consistency, Overview, Best-Set, Volumen (Sets×Reps×Gewicht)
- **Workout-Execution:** Set-Logging, EMOM-Runden, Superset-Runner, Rest-Timer, Block-Auto-Advance, Post-Summary
- **Trainings-Charakter/Zonen:** Intensitäts-Klassifikation, Form-Phasen `exhausted → fatigued → loaded → ready → fresh → peak_form` (+ `form_loss`)

---

## 7. IST-Design-Tokens (aus `tokens.css`)

| Token | Wert |
| --- | --- |
| Primär | `#F02277` (Pink) |
| Primär-dunkel | `#C01963` (= offizielle Markenfarbe lt. Memory) |
| Hintergrund | `#000000` (pures Schwarz) |
| Card / Elevated | `#161618` / `#1c1c1e` |
| Text | `#FFFFFF` / `#9ca3af` / `#6b7280` / `#4b5563` |
| Font | **Zalando Sans Expanded** |
| Radius | `1rem` / `1.25rem` / `1.5rem` |
| Icons | Material Symbols Rounded |
| CSS-Util | Tailwind (CDN) + Custom Component-System |
| Theme | Dark (default) + Light (`[data-theme="light"]`) |

**Zonen-Farben (Form-Phase):** rot `#ef4444` · orange `#f97316` · gelb `#eab308` · grün `#22c55e` · blau `#3b82f6` · lila `#8b5cf6` · grau `#8e8e93`
**Kategorie-Farben:** strength `#e35745` · bodyweight `#f59e0b` · cardio `#3b82f6` · recovery `#22c55e`
**Sport-Farben:** run navy · bike blau · swim teal

---

## 8. ⚠️ Design-Drift (zu bereinigen)

| Quelle | Hintergrund | Primärfarbe | Font |
| --- | --- | --- | --- |
| README.md | `#060A30` (Navy) | `#C01963` | Zalando Sans Expanded |
| PROJECT_CONTEXT.md | `#060A30` | `#F02277` | Radio Canada Big |
| **tokens.css (REAL)** | **`#000000`** | **`#F02277`** (+`#C01963` als „dark") | **Zalando Sans Expanded** |
| Memory | — | `#C01963` | — |

**Folge:** Es gibt keine eindeutige Primärfarbe und keinen eindeutigen Hintergrund.
Das Redesign muss hier **eine** verbindliche Entscheidung festschreiben (Vorschlag im
Konzept-Dokument). Außerdem koexistieren mehrere Progress-Generationen (v2/v3/v4) — ein
Aufräum-Kandidat.

---

## 9. Tech-Schulden / Cleanup-Kandidaten fürs Redesign

1. **Primärfarbe & Hintergrund** uneinheitlich (s. o.).
2. **Progress v2/v3/v4** parallel — auf eine Version konsolidieren.
3. **FAB-Radial** redundant zur Bottom-Nav.
4. **Doku veraltet** (README/PROJECT_CONTEXT ≠ Code).
5. **Globales JS-Pattern** (Funktionen am `window`, `onclick`-Attribute) — beim Redesign ggf. modularer kapseln.
6. **~70 CSS-Partials** ohne zentrales Token-/Komponenten-System → idealer Kandidat für das Claude-Design-System.
