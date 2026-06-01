<img width="348" height="1000" alt="Screenshot 2026-06-01 165237" src="https://github.com/user-attachments/assets/61fcd2aa-a16d-456a-baa7-4dd899a9295b" />

<img width="352" height="996" alt="Screenshot 2026-06-01 165335" src="https://github.com/user-attachments/assets/a2385c64-7118-415c-b912-7eac45a1be6d" />

# ATEM Hybrid

> **Strength · Cardio · Recovery** — Hybrid Fitness & Recovery System als Progressive Web App.

ATEM Hybrid ist eine dunkel-minimalistische, mobile-first PWA für hybrides Training (Calisthenics, Cardio, Mobility). Statt eines klassischen Workout-Trackers entsteht hier ein intelligentes Performance-System mit Plänen, Kalender, Live-Workout-Tracking und Belastungsanalyse — inspiriert von Premium-Brands wie WHOOP und Oura, aber ganz ohne Wearable.

**Status:** 🚧 In aktiver Entwicklung (MVP-Phase) — geplante Auslieferung als Play-Store-App via Capacitor.

---

## ✨ Features

### Implementiert
- 🔐 **Authentifizierung** — Firebase Auth (E-Mail/Passwort, Google Sign-In)
- 🏋️ **Übungs-Datenbank** — Calisthenics-Übungen mit Haupt-/Hilfsmuskel-System, Schwierigkeitsgraden, Filter & Suche
- 📅 **Trainingskalender** — Monats- und Wochenansicht mit Plan-Scheduling, Echtzeit-Sync via Firestore
- 📋 **Trainingsplan-Builder** — Pläne aus Übungen zusammenstellen, Sets/Reps/Holds konfigurieren
- ⏱️ **Workout-Execution** — Live-Tracking während des Trainings, Sets abhaken, Session-Templates
- 📊 **Progress-Tracking** — Historie pro Übung, Trainings-Statistiken
- 🌍 **Mehrsprachigkeit** — i18n-System (Deutsch, weitere Sprachen vorbereitet)
- 📱 **Mobile-First UX** — Floating Action Button mit Radial Menu, Swipe-Gesten, Bottom Sheets, Haptic Feedback
- ♿ **Barrierefreiheit (WCAG)** — Hoher Kontrast, große Touch-Targets, ARIA-Attribute, Screenreader-Support
- 📲 **PWA-fähig** — Installierbar, Offline-fähig, Service Worker, App-Shortcuts

### Geplant
- 💪 Erweiterte Belastungsanalyse & Recovery-Empfehlungen
- 💳 Freemium-Monetarisierung (Stripe)
- 📦 Native Apps via Capacitor (Google Play Store, App Store)

---

## 🛠️ Tech-Stack

| Bereich      | Technologie                                                |
| ------------ | ---------------------------------------------------------- |
| Frontend     | Vanilla JavaScript (ES Modules), HTML5, CSS3               |
| Styling      | Tailwind CSS (CDN) + Custom Component-System               |
| Backend      | Firebase Firestore (Echtzeit-DB), Firebase Authentication  |
| PWA          | Web App Manifest, Service Worker, iOS Safe Area Support    |
| Icons & Font | Material Symbols Rounded, Zalando Sans Expanded            |
| Dev-Workflow | KI-gestützte Entwicklung mit Claude Code (Sonnet & Opus)   |

**Bewusste Entscheidungen:**
- **Kein Framework (Vue/React)** — Fokus auf JavaScript-Fundamentals, schlanke Bundles, keine Build-Tools nötig.
- **Kein Bundler** — Direkte ES-Module-Imports, CDN-basierte Abhängigkeiten.
- **Multi-User-ready von Tag 1** — Alle Firestore-Collections enthalten `userId`, auch wenn Auth später kommt.

---

## 🎨 Design-System

| Token              | Wert                                            |
| ------------------ | ----------------------------------------------- |
| Primärfarbe        | `#C01963` (Magenta/Pink)                        |
| Hintergrund        | `#060A30` (Dark Navy)                           |
| Sekundär (Cards)   | `#091E4D`                                       |
| Typografie         | Zalando Sans Expanded                           |
| Stil               | Dark Premium, minimalistisch, WHOOP/Oura-inspiriert |

---

## 📁 Projekt-Struktur

```
calisthenics-pwa/
├── index.html              # Single-Page-App Entry
├── manifest.json           # PWA-Manifest
├── css/
│   ├── style.css           # Globale Styles
│   └── components.css      # Wiederverwendbare Components
├── js/
│   ├── app.js              # Haupt-App-Logik & Router
│   ├── firebase.js         # Firebase-Config & Helpers
│   ├── auth.js             # Authentifizierung
│   ├── exercises.js        # Übungs-Datenbank
│   ├── plans.js            # Trainingspläne
│   ├── calendar.js         # Kalender-Logik
│   ├── workout.js          # Workout-Execution
│   ├── progress.js         # Progress-Tracking
│   ├── dashboard.js        # Home-Dashboard
│   ├── settings.js         # Einstellungen
│   ├── onboarding.js       # Onboarding-Flow
│   ├── i18n.js             # Mehrsprachigkeit
│   └── ...                 # Gesten, Bottom Sheets, Ripple etc.
├── assets/
│   └── img/                # Logos, Icons
└── configuration/          # Setup- und Kontext-Docs
```

---

## 🚀 Lokale Entwicklung

**Voraussetzungen:** Aktueller Browser (Chrome/Firefox/Safari), ein lokaler HTTP-Server (z. B. VS-Code-Extension *Live Server*) und ein eigenes Firebase-Projekt.

```bash
# 1. Repository klonen
git clone https://github.com/dein-username/atem-hybrid.git
cd atem-hybrid

# 2. Firebase-Config in js/firebase.js eintragen
#    (Firebase-Projekt erstellen: https://console.firebase.google.com)
#    Firestore + Authentication (E-Mail + Google) aktivieren

# 3. Lokalen Server starten (z. B. mit VS Code Live Server)
#    oder mit Python:
python -m http.server 8080
```

Detaillierte Setup-Anleitungen liegen unter [`configuration/`](configuration/):
- [`DEV-SETUP.md`](configuration/DEV-SETUP.md) — Entwicklungsumgebung
- [`AUTH_SETUP.md`](configuration/AUTH_SETUP.md) — Firebase-Auth konfigurieren
- [`PROJECT_CONTEXT.md`](configuration/PROJECT_CONTEXT.md) — Architektur-Übersicht
- [`SETUP_CLAUDE.md`](configuration/SETUP_CLAUDE.md) — KI-gestütztes Coding mit Claude

---

## 🤖 Entwickelt mit Claude Code

Dieses Projekt entsteht im "Vibe-Coding"-Workflow gemeinsam mit **Claude Sonnet & Opus** über [Claude Code](https://claude.com/claude-code). Die Konfiguration und Coding-Guidelines für die KI liegen in [`configuration/CLAUDE_INSTUACTIONS.md`](configuration/CLAUDE_INSTUACTIONS.md).

---

## 📄 Lizenz

Dieses Projekt ist aktuell **proprietär** und nicht zur Weiterverwendung freigegeben. Bei Interesse oder Fragen gerne Kontakt aufnehmen.

---

**Branding:** ATEM Hybrid · Strength · Cardio · Recovery
