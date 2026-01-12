# Calisthenics Pro - Projekt-Kontext

## 🎯 Projekt-Übersicht

**Name:** Calisthenics Pro  
**Typ:** Progressive Web App (PWA) für Calisthenics-Training  
**Zielgruppe:** Einzelner User (später Multi-User mit Firebase Auth)  
**Tech Stack:** Vanilla JavaScript, Firebase Firestore, Tailwind CSS, Radio Canada Big Font

## 📋 Projekt-Ziele

### Kurzfristig (MVP)
- Übungen-Datenbank mit Haupt- und Hilfsmuskeln
- Trainingspläne erstellen
- Kalender mit Plan-Scheduling
- Progress-Tracking

### Mittelfristig
- Multi-User Support (Firebase Authentication)
- Freemium-Monetarisierung (Stripe Integration)
- Kalender-Features als Premium

### Langfristig
- Native Apps via Capacitor (iOS & Android App Stores)
- Abo-Modell: 2,99€/Monat für Premium-Features

---

## 🏗️ Projekt-Struktur

```
calisthenics-pro/
├── index.html
├── logo.svg
├── css/
│   ├── style.css           # Main Styles
│   └── components.css      # Reusable Components
├── js/
│   ├── app.js              # Main App Logic
│   ├── firebase.js         # Firebase Config & Helpers
│   ├── data.js             # Default Exercise Data
│   ├── exercises.js        # Exercise Management
│   └── calendar.js         # Calendar Logic
└── assets/
    └── images/
```

---

## 🎨 Design-System

### Farben
```css
--color-primary: #F02277        /* Pink - Aktive Elemente, Buttons */
--color-bg: #060A30             /* Dunkelblau - Background */
--color-secondary-dark: #091E4D /* Cards, Modals */
--color-secondary-light: #0F2481 /* Borders, Inputs */
```

### Typografie
- **Font:** Radio Canada Big (Google Fonts)
- **Fallback:** Inter, system-ui, sans-serif

### Button-System
- **Standard:** 2px Pink Outline, transparent Background
- **Hover:** Pink gefüllt
- **Klassen:** `.btn`, `.btn-primary`, `.btn-sm`, `.btn-icon`, `.btn-full`

### Components
Alle in `css/components.css`:
- `.btn` - Buttons
- `.input` - Input-Felder
- `.label` - Labels
- `.card` - Cards
- `.heading-1/2/3` - Typografie
- `.badge` - Badges
- `.modal-overlay/.modal-box` - Modals

---

## 🔥 Firebase Setup

### Collections
```javascript
// exercises Collection
{
  id: "auto-generated",
  name: "Pull-ups",
  description: "Anleitung...",
  muscleGroups: ["back", "arms"],  // Erste = Hauptmuskel
  difficulty: 3,                    // 1-5
  imageUrl: "https://...",
  createdAt: timestamp
}

// schedule Collection (Multi-User-ready)
{
  id: "auto-generated",
  userId: "demo-user-123",  // Später echte User ID
  planId: "plan-id",
  planName: "Push Day",      // Denormalisiert
  date: "2026-01-15",        // ISO Format
  completed: false,
  createdAt: timestamp
}

// plans Collection (noch nicht implementiert)
{
  id: "auto-generated",
  userId: "demo-user-123",
  name: "Push Day",
  exercises: [
    {
      exerciseId: "exercise-id",
      sets: 3,
      reps: 10,
      hold: null,           // Alternativ zu reps
      notes: "Langsam ausführen"
    }
  ],
  createdAt: timestamp
}
```

### Firebase Config
In `js/firebase.js` - User muss eigene Config einfügen!

---

## 📱 Navigation & UI

### Desktop
- **Floating Navigation:** Schwebend, sticky, Backdrop-Blur
- **Nur Text:** Keine Icons
- **Font-Weight:** 700 (dick)
- **Hover:** Pink Border + Glow
- **Active:** Pink Background mit Shadow

### Mobile
- **FAB (Floating Action Button):** Unten mittig, Pink Gradient
- **Radial Menu:** Öffnet sich wie Blume (4 Icons)
- **Nur Icons:** Kein Text im Radial Menu
- **Header:** Logo + Titel zentriert

---

## 📚 Features - Aktueller Stand

### ✅ Implementiert

**Übungen-Datenbank:**
- 15 vordefinierte Calisthenics-Übungen
- Eigene Übungen hinzufügen
- Filter: Suche, Muskelgruppe, Schwierigkeit
- Kompakte Cards: Bild, Name, Hauptmuskel, "+X" Badge für Hilfsmuskeln
- Detail-Modal mit allen Infos
- Edit-Funktion

**Kalender:**
- Monatsansicht (7×6 Grid)
- Wochenansicht (7 Tage detailliert)
- Navigation (Vorheriger/Nächster Monat/Woche, Heute)
- Demo-Pläne zu Tagen hinzufügen/entfernen
- Real-time Sync mit Firebase

**Design & Components:**
- Reusable Component System
- Mobile-optimiert (FAB + Radial Menu)
- Desktop-optimiert (Floating Nav)
- Consistent Button-System

### 🚧 Noch zu implementieren

**Trainingspläne (Session 2):**
- Pläne aus Übungen zusammenstellen
- Sets/Reps/Holds konfigurieren
- Notizen pro Übung
- Pläne bearbeiten/löschen

**Workout-Execution (Session 4):**
- Workout starten
- Live-Tracking während Training
- Sets abhaken
- Workout als "completed" markieren

**Progress-Tracking (Session 5):**
- History-Ansicht pro Übung
- Charts (Wiederholungen/Gewicht über Zeit)
- Stats (Letzte 7/30/90 Tage)

**Multi-User (später):**
- Firebase Authentication
- User-spezifische Daten
- Security Rules

**Monetarisierung (später):**
- Stripe Integration
- Freemium-Modell
- Feature-Gates

---

## 🎯 Wichtige Design-Entscheidungen

### Warum Vanilla JS statt React?
- Lernfokus auf JavaScript-Basics
- Später leicht zu React migrierbar
- Keine Build-Tools nötig
- Einfacher zu verstehen

### Warum Firebase?
- Kein eigener Backend-Server nötig
- Real-time Sync out-of-the-box
- Einfache Authentication später
- Kostenlos für kleine Projekte

### Multi-User Design von Anfang an
Auch ohne Auth haben wir `userId` in allen Collections:
```javascript
const CURRENT_USER_ID = 'demo-user-123'; // Später durch Auth ersetzt
```
So müssen wir später nichts umbauen!

### PWA statt Native App (jetzt)
- Funktioniert auf allen Geräten
- Kein App Store Review
- Schneller zu entwickeln
- Später mit Capacitor zu Native Apps wrappen

---

## 🐛 Bekannte Einschränkungen

1. **LocalStorage NICHT verwendet** - Artifacts unterstützen das nicht
2. **Keine Browser Storage APIs** - Alles geht über Firebase
3. **Nur CDN-Imports** - Keine npm-Packages
4. **Tailwind Core Only** - Keine Custom Tailwind-Compiler-Features

---

## 📝 Code-Konventionen

### JavaScript
- Camel Case: `getUserData()`, `currentUserId`
- Klare Funktionsnamen: `loadExercises()`, `renderCalendar()`
- Kommentare für Sections
- Async/Await statt Promises

### CSS
- BEM-ähnlich: `.exercise-card-title`, `.modal-box`
- CSS Variables für Farben
- Mobile-first Responsive Design
- Component-basiert (components.css)

### HTML
- Semantic HTML wo möglich
- Data-Attributes für Interaktionen: `data-view="exercises"`
- Klare IDs: `exercise-modal`, `calendar-grid`

---

## 🚀 Nächste Schritte

**Priorität 1:** Trainingspläne implementieren (Session 2)
- Plan-Creator UI
- Übungen zu Plan hinzufügen
- Sets/Reps/Holds konfigurieren
- Pläne im Kalender verfügbar machen

**Priorität 2:** Haupt-/Hilfsmuskel-System verfeinern
- UI für Hauptmuskel-Auswahl
- Untergruppen definieren
- In Exercise-Daten integrieren

**Priorität 3:** Workout-Execution
- Workout-Flow
- Live-Tracking
- Progress speichern

---

## 💡 Lern-Fokus

Der User möchte lernen:
- ✅ JavaScript Basics (Arrays, Objects, Functions)
- ✅ DOM-Manipulation
- ✅ Async/Await
- ✅ Firebase Integration
- ✅ "Vibe Coding" mit KI
- 🎯 Später: Wie man daraus eine verkaufbare App macht

---

## 📞 Wichtige Hinweise für Claude Agent

1. **Immer auf Deutsch kommunizieren** (außer Code-Kommentare)
2. **Code erklären:** Was macht der Code und warum?
3. **Best Practices:** Hinweise auf bessere Lösungen geben
4. **Keine Breaking Changes:** Bestehenden Code respektieren
5. **Component-System nutzen:** Neue Features mit Components bauen
6. **Multi-User-ready:** Immer `userId` berücksichtigen
7. **Mobile-first:** Immer responsive denken

---

**Letztes Update:** Januar 2026  
**Version:** MVP Phase (Session 1 abgeschlossen)