# Design-Gespräch 03 — Statusträger und Fortschritt

**Stufe 4** · Kopiere ab der Trennlinie in Claude Design.

---

## Kontext

ATEM Hybrid — Android-App für hybrides Training. Dark Cyber-Athlete, Neon-HUD.
Dies ist Modul 3. **Modul 1 (Typenskala, Tap-Ziele, Bewegung) ist abgenommen
und umgesetzt.** Die Ergebnisse sind verbindlich:

```
FARBEN
Canvas #050507 · Surface #0B0B0E · Card #14141D · SurfaceRaised #1A1A26
Border #232334 · Track #16161F
Magenta #F02277 (Marke, CTA, Strain) · Cyan #00F2FE (Daten, HF, aktiv)
Lime #00FF87 (Erfolg, Recovery, Live) · Violet #7A2BDB (nur Fläche, NIE Text)
Amber #FFB020 (Warnstufe) · Text #FFFFFF / #94A3B8 / #CDD3EA

TYPENSKALA (aus Modul 1)
display 48 · valueLarge 24 mono · titleLarge 20 · titleMedium 16
valueMedium 16 mono · labelMedium 14 · labelSmall 12
labelMicro 12 mono (+0,16em) · labelDeco 10 — nur 5 dekorative Ausnahmen
Alle Sperrungen relativ in em.

BEREITS GEBAUT — wiederverwenden
AtemTappable · AtemButton · AtemNumberField
```

## Auftrag

### Teil A — Statusträger

Heute existieren **sechs fast identische Pill-Rezepte** nebeneinander, die sich
nur in Polsterung und Randfarbe unterscheiden. Sie sollen ein System werden.

Die realen Fälle:

| Fall | Heute |
|---|---|
| Marken-Badge „ATEM HYBRID" | Pille mit grünem Punkt, Rand, Kartenfläche |
| Benachrichtigungszähler | magenta gefüllt, Zahl, Rand in Canvas-Farbe |
| Empfehlungs-Pille unter dem Gauge | langer Text, gedämpfte Fläche |
| LIVE-Anzeige | pulsierender Punkt, grüner Rand, kein Hintergrund |
| Session-Badges „48 Min", „High Intensity" | neutral bzw. akzentuiert |
| Muskel- und PR-Chips im Runner | akzentumrandet, teils antippbar |

Zu klären:

- Welche **Achsen** hat das System? Vorschlag: Füllung (leer / getönt / voll),
  Akzent, führendes Element (nichts / Punkt / Symbol), antippbar ja/nein
- Wie unterscheidet sich ein **Statusträger** (zeigt an) von einem **Chip**
  (lässt sich antippen)? Sichtbar oder nur im Verhalten?
- **Statuspunkte** gibt es in vier Größen zwischen 4 und 6 dp. Wie viele braucht
  es wirklich, und wovon hängt die Größe ab?
- **Sektionslabels** stehen an achtzehn Stellen in zehn Ausprägungen. Sie sind
  jetzt alle `labelMicro` — aber manche tragen einen Akzent, manche nicht.
  Wann welcher?

Wichtig: **Farbe darf nie der einzige Träger sein.** Das Badge „High Intensity"
unterscheidet sich heute nur durch Rand- und Textfarbe von „48 Min". Ein
Farbenblinder sieht denselben Chip zweimal.

### Teil B — Fortschritt

Vier unverbundene Implementierungen desselben Gedankens:

**Arc-Gauge** — der Readiness-Bogen. 260°, Lücke unten zentriert, Verlauf
cyan → violet → magenta, geblurrte Glow-Kopie darunter, Zahl in der Mitte.
Modul 1 hat festgelegt: Die Zahl darf bei 1,3× begrenzt werden, weil Statuszeile
und Empfehlung darunter voll mitskalieren.

**Ring** — kleiner Kreis, 38 dp, für Anteile wie „87 % des Proteinziels".

**Balken** — 3 dp hoch, für den Fortschritt einer Trainingsphase.

**Pausen-Fortschritt** — der Countdown in der Rest-Leiste, heute ein
Standard-Balken.

Zu klären:

- Ist das **eine Familie** mit gemeinsamen Achsen, oder sind es zwei Dinge
  (Anteil zeigen vs. Ablauf zeigen)?
- Wie viel **Glow** verträgt ein Fortschrittselement, bevor der Wert schlechter
  ablesbar wird als ohne?
- Was passiert bei **0 % und 100 %**? Ein Bogen mit runden Kappen zeigt bei 0
  einen Punkt, der wie 2 % aussieht.
- Der **unbestimmte** Zustand — Wert noch unbekannt. Wie sieht der aus, ohne wie
  ein Ladekreisel zu wirken?

### Teil C — Diagramm-Grundlage

Das Wochendiagramm zeigt drei Reihen: Load (Verlauf), Strain (gestrichelt),
Recovery (durchgezogen). Es soll später auch auf anderen Screens auftauchen.

- Welche **Grundelemente** braucht eine Diagrammkarte: Kopfzeile, Legende,
  Zeichenfläche, Achsenbeschriftung, Hervorhebung „heute", Tooltip?
- Wie unterscheiden sich drei Reihen **ohne Farbe**? Strain ist gestrichelt,
  Load und Recovery sind heute beide durchgezogen.
- Die Legende ist eine der fünf dekorativen Ausnahmen bei 10 sp. Wie bleibt sie
  trotzdem zuordenbar?

## Bewegung

Je Element: Was, Auslöser, Dauer, Kurve, Ruhelage, Verhalten bei reduzierter
Bewegung.

Bestehende Vorgaben aus Modul 1, die erhalten bleiben: Score-Count-up 1400 ms
ease-out-cubic mit gemeinsam laufendem Bogen; LIVE-Puls 1800 ms; der
Pausen-Fortschritt läuft linear im Sekundentakt und **bleibt auch bei
reduzierter Bewegung**, weil er informationstragend ist.

Offen: Wie animiert ein Wert, der sich ändert, ohne dass es nach Ladebalken
aussieht? Und was passiert am Ende eines Countdowns — die Rest-Leiste löst
dreifache Vibration plus Systemton aus, visuell passiert bisher nichts.

## Verbindliche Randbedingungen

- Nur Farben und Rollen aus dem Kasten oben
- Informationstragender Text ≥ 12 sp, Kontrast ≥ 4,5:1
- Jedes Tap-Ziel ≥ 48 dp Trefferfläche
- Bei 200 % Systemschrift kein Überlauf
- Auf 320 dp Breite funktionsfähig
- **Farbe nie als einziger Statusträger** — gilt hier besonders
- `#7A2BDB` niemals als Textfarbe
- Fortschrittselemente melden ihren Wert an den Screenreader, nicht nur ihre
  Existenz

## Liefergegenstände

1. **Artboards** je Baustein in allen Varianten und Zuständen, inklusive 0 %,
   100 % und unbestimmt
2. **Spezifikationstabelle**: Achsen, Maße, Tokens
3. **Bewegungstabelle**: Auslöser, Eigenschaft, Dauer, Kurve, Ruhelage,
   reduzierte Bewegung
4. **Stringtabelle**: `key | Deutsch | Englisch`
5. **A11y-Notizen**: Label, Rolle, Wert je Element — für Diagramme auch die
   zusammenfassende Beschreibung
6. **Entscheidungsprotokoll**: wo du widersprochen hast und warum
7. **Nicht-Farb-Unterscheidung**: eine Tabelle, die für jeden farbcodierten
   Zustand angibt, woran man ihn sonst erkennt
