# Claude Design — Brief für ATEM Hybrid Design-System

> Dieser Text ist der „Prompt"/Auftrag, den wir Claude Design mitgeben. Er beschreibt,
> **was für ein Design-System** entstehen soll. Die technische Synchronisation läuft
> über das `DesignSync`-Tool (siehe Abschnitt „Workflow" unten).

---

## Der Prompt (zum Kopieren)

> **Baue ein Design-System für „ATEM Hybrid", eine dark-premium Hybrid-Fitness-PWA
> (Strength · Cardio · Recovery), inspiriert von WHOOP und Oura.**
>
> **Marke & Stimmung:** Dunkel, ruhig, datengetrieben, premium. Viel Schwarz, ein
> klarer Magenta-Akzent. Zahlen und Status sind die Helden, UI-Chrome tritt zurück.
>
> **Foundations (verbindlich):**
> - Primärfarbe `#C01963`, heller Stop `#F02277`, Gradient `#C01963 → #F02277` für CTAs.
> - Hintergrund `#000000`; Card `#161618`; Elevated `#1c1c1e`; Borders `rgba(255,255,255,.1)`.
> - Text `#FFFFFF / #9ca3af / #6b7280 / #4b5563`.
> - Font **Zalando Sans Expanded**; Scale 12 → 40 px; Weights 400/500/600/700.
> - Radius 16/20/24 px; Spacing 4/8/16/24/32/48 px.
> - Dark als Default, Light-Variante (`[data-theme="light"]`) unterstützen.
> - **Form-Zonen-Farben** (Trainings-Status): exhausted `#ef4444`, fatigued `#f97316`,
>   loaded `#eab308`, ready `#22c55e`, fresh `#3b82f6`, peak_form `#8b5cf6`, form_loss `#8e8e93`
>   — jeweils als 8 %-Tint-Hintergrund + farbiger Text/Dot.
> - **Kategorie-Farben:** strength `#e35745`, bodyweight `#f59e0b`, cardio `#3b82f6`, recovery `#22c55e`.
>
> **Komponenten (in dieser Reihenfolge):**
> 1. Foundations: Colors, Typography, Spacing/Radius, Elevation.
> 2. Buttons (Primär/Sekundär/Ghost/Icon · Größen · States), Cards (Standard/Elevated/CTA-Gradient/Stat),
>    Badges & Pills (Difficulty 1–5, Form-Zone, Kategorie), Inputs (Text, Number-Picker, Range-Slider, Filter-Chips).
> 3. Navigation: Bottom-Nav (4 Items), Desktop-Nav, Segmented Control, FAB (zentraler „Workout loggen"-CTA).
> 4. Sheets & Modals: Bottom-Sheet (Standard für Auswahl/Eingabe), Center-Modal, Confirm-Dialog.
> 5. Data-Viz: Form-Status-Gauge (Ring mit Zonen-Gradient), Sparkline, Weekly-Chart, Kalender-Cell.
> 6. Patterns: Dashboard-Form-Hero, Exercise-Card, Plan-Card, Workout-Logger-Row, Quick-Log-Flow.
>
> **Stil-Regeln:** Ein Akzent, sparsam gesetzt. Touch-Targets ≥ 44 px. Mobile-first.
> Bottom-Sheets statt Center-Modals für Eingaben. Charts mit dünnen Linien + Zonen-Banding,
> kein Gitter-Lärm. Material Symbols Rounded als Icon-Set.

---

## Workflow: Wie wir das technisch anbinden

Die Verbindung läuft über das **`DesignSync`-Tool** (Zugriff auf deine claude.ai/design-Projekte).
Ablauf — **lesen → Plan festzurren → schreiben**, immer inkrementell:

1. **Verbinden & prüfen:** `list_projects` → beim ersten Mal fragt dein claude.ai-Login
   einmalig nach Freigabe für Design-System-Zugriff.
2. **Projekt wählen/anlegen:** existierendes ATEM-Design-System nutzen oder `create_project`
   („ATEM Hybrid Design System"). Muss Typ `PROJECT_TYPE_DESIGN_SYSTEM` sein.
3. **Plan festzurren:** `finalize_plan` mit der exakten Datei-/Pfadliste + lokalem Quellordner
   (z. B. `design-system/`). Du genehmigst die Liste.
4. **Hochladen:** `write_files` lädt die Komponenten-HTML hoch. Jede Datei trägt oben einen
   `<!-- @dsCard group="..." -->`-Marker → erscheint als Karte im Design-System-Panel.
5. **Iterieren:** Komponente für Komponente erweitern/verfeinern — **nie** alles auf einmal ersetzen.

Geplante lokale Struktur:
```
design-system/
  foundations/   colors.html, typography.html, spacing.html, elevation.html
  components/     buttons.html, cards.html, badges.html, inputs.html, nav.html, sheets.html, dataviz.html
  patterns/       dashboard-hero.html, exercise-card.html, plan-card.html, logger-row.html, quick-log.html
```

---

## Nächster Schritt

Sobald die offenen Entscheidungen aus `REDESIGN_CONCEPT.md` (§7) bestätigt sind:
→ Verbindung herstellen (`list_projects`), Projekt anlegen, Phase 1 (Foundations) hochladen.
