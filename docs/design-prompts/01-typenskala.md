# Design-Gespräch 01 — Typenskala und Tap-Ziele

**Stufe 3b** · Alles darunter baut hierauf auf.
Kopiere ab der Trennlinie in Claude Design.

---

## Kontext

ATEM Hybrid — Android-App für hybrides Training (Kraft, Ausdauer, Regeneration).
Ästhetik: Dark Cyber-Athlete, Neon-HUD. Zwei Screens existieren bereits und sind
der gestalterische Anker: ein Dashboard mit Readiness-Gauge und Wochenchart, und
ein Workout Runner mit Satz-Tabelle und Pausen-Timer.

**Das Farbsystem ist verbindlich und nicht Gegenstand dieses Gesprächs:**

```
Canvas          #050507      Surface        #0B0B0E
Card            #14141D      SurfaceRaised  #1A1A26
Border          #232334      Track          #16161F

Magenta         #F02277      Marke, CTA, Intensität
Deep Rose       #C01963      dunkler CTA-Verlaufsstop
Cyan            #00F2FE      Daten, Herzfrequenz, aktive Navigation
Lime            #00FF87      Erfolg, Regeneration, Live-Status
Violet          #7A2BDB      NUR Fläche und Verlauf, NIEMALS Text (2,8:1)

Text            #FFFFFF / #94A3B8 / #CDD3EA
Radien          Card 20 · Pill 30 · StatBox 14 · IconBox 10
Schriften       Poppins (UI) · JetBrains Mono (Messwerte, HUD-Labels)
Kein Material-Ripple — Skalierung und Glow statt Welle
```

---

## Das Problem

Das Design arbeitet mit sehr kleinen, weit gesperrten Mono-Labels. Das ist ein
Kernmerkmal der Optik — es lässt die App wie ein Messinstrument wirken, nicht wie
eine Formular-App.

Nur: **41 Schriftgrößen liegen unter 12 sp.** Verteilung im Bestand:

| Größe | Vorkommen | Wofür |
|---|---|---|
| 7,5 | 3 | Navigationslabels, Tabellenkopf der Satz-Tabelle |
| 8 | 4 | Micro-Stat-Beschriftung, Chart-Legende |
| 8,5 | 9 | Sektionslabels („ATEM READINESS", „HEUTIGE SESSION"), LIVE-Pill |
| 9 / 9,5 | 11 | Badges, Unterzeilen der Quick-Actions |
| 10 / 10,5 | 4 | Statuszeilen |
| 11 / 11,5 | 10 | Buttons, Dialogaktionen |

Zehn verschiedene Größen für im Grunde drei Rollen. Und Android skaliert Schrift
bis 200 % — bei 7,5 sp beginnt man weit unter dem, was das System als Minimum
annimmt.

**Zweites Problem:** Kein einziges interaktives Element erreicht 48 dp. Gemessen:
Icon-Buttons 40×40, Satz-Typ-Chips 34×32, Eingabefelder 66×44 und 54×44,
Navigationseinträge 43 dp hoch.

---

## Auftrag

Entwirf eine Typenskala und eine Tap-Ziel-Strategie, die den HUD-Charakter
erhalten und trotzdem lesbar und bedienbar sind.

### 1. Typenskala

Kollabiere die zehn Größen auf eine kleine, benannte Skala. Vorschlag als
Ausgangspunkt, gern widersprechen:

- **labelMicro** — die gesperrten Mono-Labels, heute 7,5–8,5
- **labelSmall** — Badges und Unterzeilen, heute 9–10,5
- **labelMedium** — Buttons und Aktionen, heute 11–11,5
- dazu die vorhandenen größeren Rollen (Messwerte, Titel, Fließtext)

Für jede Stufe: Größe, Gewicht, Laufweite, Schriftart, Verwendung.

**Die Kernfrage:** Wenn `labelMicro` auf 12 sp wächst, verliert das HUD dann seinen
Charakter — und was kompensiert das? Mehr Laufweite? Geringere Deckkraft? Andere
Gewichtung? Zeig mir den Unterschied, statt ihn zu behaupten.

### 2. Die Ausnahme für dekoratives

Höchstens **sechs** Beschriftungen dürfen unter 12 sp bleiben. Sie müssen rein
dekorativ sein, das heißt: ihre Information steht zusätzlich woanders in lesbarer
Größe. Kandidaten aus meiner Sicht — die drei Chart-Legenden (LOAD / STRAIN /
RECOVERY) und die Prozentzahl im Mini-Ring, deren Wert die Kartenunterzeile
ohnehin nennt.

Schlag vor, welche es sein sollen, und begründe je Fall, wo die Information sonst
noch steht.

### 3. Tap-Ziele

Jedes interaktive Element braucht 48 dp Trefferfläche. Die sichtbare Größe darf
kleiner bleiben — die Fläche wächst unsichtbar.

Zeig für diese Fälle, wie sich das auf die Komposition auswirkt:

- **Drei Icon-Buttons oben im Runner**, heute 40×40 mit 8 dp Abstand
- **Satz-Typ-Chip** W/N/D/F, heute 34×32 in einer Tabellenzeile
- **Fünf Navigationseinträge** in einer schwebenden Pill-Leiste
- **Eingabefelder KG und WDH**, heute 44 dp hoch — hier hilft unsichtbares
  Vergrößern nicht, das Feld selbst muss wachsen

### 4. Verhalten bei 200 % Schrift

Wo bricht das Layout um, wo begrenzt es? Konkret:

- Die **Satz-Tabelle** hat fünf Spalten (34 / flexibel / 66 / 54 / 46 dp). Bei
  320 dp Breite und Faktor 2 ist das nicht zu halten. Wie sieht die kompakte
  Variante aus?
- Die **Navigationsleiste** mit fünf Einträgen: Labels ausblenden, umbrechen,
  oder etwas Drittes?
- Der **Readiness-Gauge** ist eine Grafik. Darf die Zahl darin begrenzt werden,
  weil Stufenlabel und Empfehlungstext direkt darunter voll mitskalieren?

---

## Bewegung

Animation ist bei diesem Design kein Beiwerk. Messlatte ist die Qualität, die man
im Web mit GSAP erreicht — orchestrierte Abläufe, nicht verstreute Einzeleffekte.

Spezifiziere zu jeder Skalenstufe und jedem Zustandswechsel:

- **Was** bewegt sich (Deckkraft, Position, Skalierung, Glow, Farbe)
- **Wodurch** ausgelöst (Erscheinen, Antippen, Wertänderung, Dauerschleife)
- **Wie lange** und mit welcher Kurve
- **Welcher Zustand ist die Ruhelage**, wenn die Animation nicht läuft

Bestehende Bewegungen, die erhalten bleiben sollen: Score-Count-up über 1400 ms
mit ease-out-cubic, Flackern des Marken-Punkts über 2600 ms, LIVE-Puls über
1800 ms, Puls-Glow des Primärbuttons über 2200 ms.

**Randbedingung:** Dekorative Dauerschleifen müssen stillstehen können, wenn der
Nutzer „Animationen reduzieren" aktiviert hat. Gib für jede Schleife an, welcher
Zustand dann eingefroren wird.

---

## Verbindliche Randbedingungen

- Nur Farben aus der Liste oben
- Informationstragender Text ≥ 12 sp, Kontrast ≥ 4,5:1
- Dekorative Labels dürfen kleiner sein, brauchen dann eine Vorlese-Alternative
- Jedes Tap-Ziel ≥ 48 dp Trefferfläche
- Muss bei 200 % Systemschrift ohne Überlauf funktionieren — keine festen Höhen
  um Text
- Muss auf 320 dp Breite funktionieren
- Farbe nie als einziger Statusträger — immer Form, Text oder Symbol dazu
- `#7A2BDB` niemals als Textfarbe

---

## Liefergegenstände

1. **Artboards** — die Skala als Musterblatt, dazu die vier Tap-Ziel-Fälle jeweils
   vorher/nachher, und die drei Umbruchszenarien bei 200 %
2. **Spezifikationstabelle** — je Skalenstufe: Name, Größe, Gewicht, Laufweite,
   Schriftart, Verwendung, Mindestkontrast
3. **Bewegungstabelle** — je Element: Auslöser, Eigenschaft, Dauer, Kurve, Ruhelage
4. **Stringtabelle** — `key | Deutsch | Englisch` für jeden sichtbaren Text in den
   Artboards
5. **A11y-Notizen** — je interaktivem Element: Semantics-Label, Rolle, Zustand
6. **Entscheidungsprotokoll** — wo du meinem Vorschlag widersprochen hast und warum
