# Design-Gespräch 02 — Flächen und Zustände

**Stufe 4** · Kopiere ab der Trennlinie in Claude Design.

---

## Kontext

ATEM Hybrid — Android-App für hybrides Training. Dark Cyber-Athlete, Neon-HUD.
Dies ist Modul 2. **Modul 1 (Typenskala, Tap-Ziele, Bewegung) ist abgenommen
und umgesetzt** — die Ergebnisse sind verbindlich und werden hier vorausgesetzt:

```
FARBEN
Canvas #050507 · Surface #0B0B0E · Card #14141D · SurfaceRaised #1A1A26
Border #232334 · Track #16161F
Magenta #F02277 (Marke, CTA) · Deep Rose #C01963 · Cyan #00F2FE (Daten, aktiv)
Lime #00FF87 (Erfolg, Recovery) · Violet #7A2BDB (nur Fläche, NIE Text)
Text #FFFFFF / #94A3B8 / #CDD3EA

TYPENSKALA (aus Modul 1)
display 48 · valueLarge 24 mono · titleLarge 20 · titleMedium 16
valueMedium 16 mono · labelMedium 14 (+0,10em) · labelSmall 12
labelMicro 12 mono (+0,16em) · labelDeco 10 — nur 5 dekorative Ausnahmen
Alle Sperrungen relativ in em, nie in Pixeln.

GEOMETRIE
Card 20 · Pill 30 · StatBox 14 · IconBox 10 · Sheet 28
Glas: Blur 14 (Karten) / 22 (schwebende Leisten), Fläche Card @ 0,80,
1 px Hairline, optionaler Neon-Halo

BEREITS GEBAUT — wiederverwenden, nicht neu erfinden
AtemTappable   Trefferfläche ≥ 48 dp, semanticLabel Pflicht
AtemButton     gradient / outline / ghost, Höhe 52 bzw. 48
AtemNumberField 48 dp hoch, 72 bzw. 60 dp breit
```

## Auftrag

Zwei Gruppen, die bisher nie gestaltet wurden.

### Teil A — Flächen

**Bottom Sheet.** Die App braucht es für Notizen, Filter, Auswahllisten und
Zahlenpicker. Zu klären:

- Aufbau: Griff, Titelzeile, Inhalt, Fußzeile mit Aktion
- Wie unterscheidet sich ein Sheet mit fester Höhe von einem, das mit dem
  Inhalt wächst
- Verhalten, wenn die Tastatur aufgeht — der Inhalt darf nicht verdeckt werden
- Wie sieht ein Sheet aus, das über die halbe Bildschirmhöhe hinauswächst

**Dialog.** Heute gibt es genau einen: „Workout beenden?" mit Statistik, einer
Marken-CTA und einer Abbrechen-Aktion. Zu klären:

- Aufbau für die drei Fälle: bestätigen, zerstörend bestätigen, informieren
- Wann Dialog, wann Sheet — die Grenze soll benennbar sein, nicht Gefühl
- Der Verdunkler dahinter: Farbe, Deckkraft, ob unscharf

**Karten-Varianten.** Es existieren drei Rezepte, die vereinheitlicht gehören:
Glaskarte mit Blur, Karte mit Neon-Gradient-Rand (die Session-Card), und eine
blurfreie Variante für lange Listen. Zu klären: Wann welche, und ob es eine
vierte braucht.

### Teil B — Zustände

Diese drei existieren heute als Zufallsergebnis und sollen ein System werden.

**Leer.** Beispiele: keine Session für heute geplant, keine Übung gefunden,
noch kein Trainingsverlauf. Was gehört hinein — Symbol, Text, Handlung? Wann ist
ein leerer Zustand eine Einladung, wann nur eine Feststellung?

**Fehler.** Beispiele: keine Verbindung, Speichern fehlgeschlagen, Workout nicht
ladbar. Zu klären: Wie unterscheiden sich behebbar und endgültig? Wo steht der
Wiederholen-Knopf? Was passiert mit einem Fehler, der nur einen Teil des Screens
betrifft?

**Laden.** Heute zeigt das Dashboard fünf graue Blöcke, der Runner einen
Kreisel — beides zufällig gewachsen. Zu klären: Wann Platzhalter in Inhaltsform,
wann Kreisel, wann gar nichts. Und ob die Platzhalter schimmern.

## Bewegung

Für jede Fläche und jeden Zustand:

- **Was** bewegt sich (Deckkraft, Position, Skalierung, Glow)
- **Wodurch** ausgelöst
- **Wie lange** und mit welcher Kurve
- **Ruhelage**, wenn die Animation nicht läuft

Besonders interessiert mich der Übergang **Laden → Inhalt**. Ein harter
Austausch wirkt billig; ein zu langsamer lässt die App träge wirken.

**Randbedingung:** Dekorative Dauerschleifen frieren bei „Bewegung reduzieren"
in ihrer Ruhelage ein. Funktionale Zustandswechsel bleiben erhalten, verlieren
aber Überschwingen und Wege — nur Überblendung.

## Verbindliche Randbedingungen

- Nur Farben und Rollen aus dem Kasten oben
- Informationstragender Text ≥ 12 sp, Kontrast ≥ 4,5:1
- Jedes Tap-Ziel ≥ 48 dp Trefferfläche
- Bei 200 % Systemschrift kein Überlauf — keine festen Höhen um Text
- Auf 320 dp Breite funktionsfähig
- Farbe nie als einziger Statusträger
- `#7A2BDB` niemals als Textfarbe
- Sheets und Dialoge brauchen ein `barrierLabel` — heute sagt ein Screenreader
  am Verdunkler nichts

## Liefergegenstände

1. **Artboards** je Fläche und Zustand, jeweils in allen Zuständen
2. **Spezifikationstabelle**: Varianten, Maße, verwendete Tokens
3. **Bewegungstabelle**: Auslöser, Eigenschaft, Dauer, Kurve, Ruhelage,
   Verhalten bei reduzierter Bewegung
4. **Stringtabelle**: `key | Deutsch | Englisch` für jeden sichtbaren Text
5. **A11y-Notizen**: Label, Rolle, Zustand je Element; für Fehler und Ladezustände
   auch, was als Live-Region angesagt wird
6. **Entscheidungsprotokoll**: wo du meinem Vorschlag widersprochen hast und warum
7. **Abgrenzungsregel** Dialog gegen Sheet, in einem Satz
