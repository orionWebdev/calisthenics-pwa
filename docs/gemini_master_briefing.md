# 📄 ATEM – Technical Master Briefing & Architecture Specification
**Version:** 1.0.0  
**Target Stack:** Flutter (Dart), Riverpod, Isar/Hive, Supabase, HealthKit / Health Connect  
**Design Aesthetic:** Dark Cyber-Athlete / High-Contrast Neon (`#050507`, `#F02277`, `#00F2FE`, `#00FF87`)

---

## 1. VISION & CORE VALUE PROPOSITION

**ATEM** ist ein High-Performance Hybrid-Fitness-System für Sportler, die Krafttraining, Ausdauer/Hyrox-Einheiten (EMOM, AMRAP, Zirkel) und intelligentes Regenerationstracking vereinen.

* **Hauptproblem bestehender Apps:** Reine Kraft-Apps (z. B. Strong, Hevy) ignorieren Ausdauer und HRV-Erholung. Ausdauer-Apps (z. B. Strava) bieten kein echtes Satz- und RPE-Tracking.
* **Die ATEM-Lösung:** Ein integriertes System mit automatischem Belastungsmanagement via Acute:Chronic Workload Ratio (ACWR), haptischer Live-Session-Engine und nahtlosem Wearable-Sync.

---

## 2. TECHNISCHE ARCHITEKTUR & TECH STACK

### 2.1 Core Framework & Libraries
* **UI & Core:** Flutter (Dart, Strict Null-Safety)
* **State Management:** `flutter_riverpod` (v2.x mit `@riverpod` Annotations & Code Generation)
* **Local Data & Offline-First:** `isar` oder `hive` für latenzfreies lokales Speichern schwacher Netzabdeckung im Gym.
* **Backend & Database:** Supabase (PostgreSQL, Row Level Security, Realtime Auth)
* **Wearable-Integration:** `health` package (Schnittstelle zu Apple HealthKit & Google Health Connect für HRV, Ruhepuls, Schlaf).
* **Audio & Haptics:** `vibration` + `audioplayers` für Timer-Intervall-Signale (3-2-1 Countdowns, Satzende).

### 2.2 System-Architektur Diagramm
```text
+-------------------------------------------------------------------+
|                        ATEM FLUTTER FRONTEND                      |
|                                                                   |
|  [ Presentation Layer ] (Screens, Riverpod Providers, Widgets)    |
|             │                                                     |
|  [ Domain Layer ]       (Use Cases, Entities, ACWR Calculator)    |
|             │                                                     |
|  [ Data Layer ]         (Repositories, Local Isar DB, Remote API)   |
+-------------┬─────────────────────────┬─────────────────────────+
              │                         │
              ▼                         ▼
   ┌────────────────────┐    ┌────────────────────┐
   │    LOCAL STORAGE   │    │   REMOTE BACKEND   │
   │  Isar DB (Cache)   │    │  Supabase (Cloud)  │
   └────────────────────┘    └────────────────────┘
              │                         │
              ▼                         ▼
   ┌────────────────────┐    ┌────────────────────┐
   │  HEALTHKIT / SYNC  │    │  AUTH & PAYMENTS   │
   │ Apple/Google Health│    │ Supabase / Revenue │
   └────────────────────┘    └────────────────────┘

lib/
├── app/
│   ├── app.dart                  # MaterialApp Entrypoint, Router Config
│   └── observer.dart             # Riverpod Logger & Analytics Observer
├── core/
│   ├── constants/                # App-weit genutzte Strings, Keys, Assets
│   ├── services/                 # HealthKit, Audio, LocalStorage, Haptics
│   ├── theme/                    # app_theme.dart, app_colors.dart, typography.dart
│   ├── utils/                    # acwr_calculator.dart, rest_timer_logic.dart
│   └── widgets/                  # neon_button.dart, glass_card.dart, progress_ring.dart
├── features/
│   ├── analytics/                # PR-History, Tonnage, Volume Breakdowns
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── dashboard/                # Main Overview, Hybrid Balance Widget
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── readiness/                # ACWR Engine, HRV Sync, Score Ring
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── workout/                  # Live Session Runner, Set Tracker, Timers
│       ├── data/
│       ├── domain/
│       └── presentation/
└── main.dart                     # App-Initialization (Isar, Env-Variables)
4. DESIGN SYSTEM SPECIFICATIONS (UI/UX)
⚬	Canvas Background: Deep Space Black (#050507)
⚬	Surfaces & Cards: Dark Anthracite (#0B0B0E & #14141D), Subtle Borders (#232334, 1px)
⚬	Primary Brand Accents: Neon Magenta (#F02277) & Deep Rose (#C01963)
⚬	Secondary Color Accents: Electric Cyan (#00F2FE) für Cardio, Acid Lime (#00FF87) für Readiness/Success
⚬	UI Micro-Effects:
⚬	Linear Gradients auf Primär-Buttons und Ringen (#F02277 ➔ #00F2FE).
⚬	CustomPainter für flüssige 60/120fps Ring-Visualisierungen und ACWR-Graphen.
⚬	Haptisches Feedback (Short Haptic Feedback) bei abgehakten Sätzen.
5. FEATURE DEEP-DIVE & LOGIK-MODELLE
5.1 ACWR Readiness Engine (Acute:Chronic Workload Ratio)
Die Belastung wird über das Verhältnis der kurzfristigen Ermüdung zur langfristigen Fitness berechnet:
‭$$ACWR = \frac{\text{Acute Workload (7-Tage-Summe)}}{\text{Chronic Workload (28-Tage-Durchschnitt)}}$$‬‭‬
⚬	Berechnungslogik: Workload = Session RPE × Dauer (Minuten) (oder Tonnage ‭$\times$‬ Intensität).
⚬	Sweet Spot (‭$1.0 - 1.3$‬‭‬): Grüner Glow (#00FF87) – Optimale Trainingsbereitschaft.
⚬	Overreaching (‭$> 1.5$‬): Oranger/Roter Glow – Hohes Verletzungsrisiko, systemische Erholung empfohlen.
5.2 Live Workout Runner & Session Tracker
⚬	Interaktive Satz-Tabelle:
⚬	Satz-Typen: Warmup (W), Normal (N), Drop Set (D), Failure (F).
⚬	Auto-Fill der Zielwerte aus dem letzten absolvierten Training derselben Übung.
⚬	Tap-to-Complete: Zeile sperrt sich, visuelles Aufleuchten in Grün, automatischer Start des Rest-Timers.
⚬	EMOM / Circuit Engine:
⚬	Akustischer und visueller Countdown (3, 2, 1, Intervallwechsel) mit verbleibender Zirkelzeit.
6. MONETARISIERUNG & ABOMODELL (FREEMIUM VS. PRO)
Feature	Free Tier (Basis-Nutzer)	ATEM Pro Tier (Subscription)
Workout Tracking	Unbegrenztes Manuelles Tracking	Unbegrenztes Manuelles Tracking
Eigene Routinen	Max. 3 gespeicherte Pläne	Unbegrenzte Pläne & Hyrox-Zirkel
Rest Timer & Audio	Standard Countdowns	Smart Rest-Timer & Live Activities / Dynamic Island
ACWR & Readiness	Basic Anzeige (7 Tage)	Vollständiger ACWR-Algorithmus & Warnsystem
Wearables Integration	Manuelle Eingabe	Automatischer Sync mit Apple Watch, Oura, Whoop & Garmin
Circuit / EMOM Engine	Einfache Stoppuhr	Erweiterter EMOM / AMRAP / TABATA Voice-Coach
Advanced Analytics	Basic Tonnage-Summe	1RM-Projektionen, Muskel-Heatmaps & CSV-Export
Empfohlenes Pricing-Modell
⚬	Monatsabo: 9,99 € / Monat
⚬	Jahresabo: 69,99 € / Jahr (~5,83 € / Monat)
⚬	Early-Adopter Lifetime: 149,00 € (Einmalig)
7. EXECUTION ROADMAP FÜR CLAUDE CODE
	1.	Phase 1 (Setup): Flutter-Projekt erstelle, app_theme.dart anlegen, Isar DB Schemas definieren (Workout, Exercise, SetData, ReadinessData).
	2.	Phase 2 (Dashboard Integration): Dashboard-UI aus Artifact in lib/features/dashboard übernehmen und mit Riverpod-State verbinden.
	3.	Phase 3 (Workout Runner): Workout Runner UI aus Artifact einbinden, Satz-Logik und Timer-Verhalten lokal speicherbar machen.
	4.	Phase 4 (Readiness & Wearables): ACWR Calculator Engine schreiben, HealthKit Interceptor anhängen, Supabase-Sync aktivieren.