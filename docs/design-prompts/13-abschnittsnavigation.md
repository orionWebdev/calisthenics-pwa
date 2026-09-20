# Design-Gespräch 13 — Der Kraft-Tab als eine Seite

**Stand:** 20.09.2026 · Offener Auftrag, bewusst ohne Lösungsvorgabe
Kopiere ab der Trennlinie in Claude Design.

---

## Kontext

ATEM Hybrid — Android-App (Flutter) für hybrides Training, ein Nutzer, ein
Gerät im Blick: Honor VKJ-NX9, 361 dp breit, Systemschrift 1,15. Ästhetik:
Dark Cyber-Athlete. Farbsystem, Typenskala und die Bausteine aus den Modulen
1 bis 3 sind gesetzt und Grundlage, nicht Gegenstand dieses Gesprächs.

Die Bottom-Bar hat drei Plätze; hier geht es ausschliesslich um den Platz
**Kraft**.

## Worum es geht

Der Kraft-Tab trägt vier Themen:

| Thema | Die Frage, die es beantwortet |
|---|---|
| **Trainieren** | Wie fange ich jetzt an? |
| **Verlauf** | Was habe ich gemacht? |
| **Auswertung** | Was ist daraus geworden? |
| **Pläne** | Wonach kann ich trainieren? |

Bisher waren das vier getrennte Bildschirme, die man seitlich wischt — vier
Räume, von denen immer genau einer sichtbar ist. Wer den Verlauf sehen wollte,
musste wissen, dass es ihn gibt und in welcher Richtung er liegt.

**Das soll eine einzige, durchgehende Seite werden.** Man scrollt von oben nach
unten durch alle vier Themen hindurch, so wie man in einer Lieferapp von den
Vorspeisen in die Hauptgänge scrollt. Die Navigation zwischen den Themen bleibt
dabei die ganze Zeit erreichbar und sagt jederzeit, wo man gerade ist; ein Tipp
darauf bringt einen direkt hin.

## Was zu gestalten ist

### 1. Die Navigation — ein Modul, nicht ein Einzelstück

Sie wird später auch andere Bereiche tragen (Cardio, Hybrid), mit anderer Zahl
an Themen und anderem Bereichston. Gestalte sie als **wiederverwendbaren
Baustein**, nicht als Dekoration dieses einen Tabs.

Sie muss vier Dinge können, und wie sie das tut, ist offen:

- sagen, in welchem Thema man gerade steht
- sagen, dass es weitere gibt — auch die, die gerade nicht sichtbar sind
- sich antippen lassen, um direkt zu springen
- dauerhaft erreichbar bleiben, während man durch die ganze Seite scrollt

Ungelöst und interessant: Vier Wörter passen auf 361 dp nicht nebeneinander,
bei 200 % Systemschrift nicht einmal zwei. Wie löst du das, ohne die Wörter zu
verstümmeln oder zu Symbolen zu degradieren?

### 2. Die Gliederung der Seite

Ein durchgehender Scroll über vier Themen läuft Gefahr, ein Brei zu werden.
Beim Vorbeiscrollen muss erkennbar sein, dass gerade ein Thema endet und ein
neues beginnt — auch für jemanden, der schnell wischt und nicht liest.

Dazu gehört die Frage, ob ein Thema **im Inhalt** eine eigene Überschrift
trägt oder ob die Navigation diese Rolle übernimmt. Beides gleichzeitig hiesse,
denselben Namen zweimal auf dem Schirm zu haben.

### 3. Die vier Themen selbst

Der Inhalt steht fest, die Form nicht:

- **Trainieren** — vier Wege: die für heute geplante Einheit starten, frei
  starten, einen Plan wählen, eine Einheit ohne Sätze nachtragen. Dazu ein Weg
  in den Übungskatalog, der eine eigene Unterseite ist. Die Wege sind
  verschieden häufig; „nachtragen" ist selten, „starten" ist der Grund, warum
  jemand die App öffnet. Das soll man sehen, ohne es zu lesen.
- **Verlauf** — Einheiten je Monat, Muskelbalance, die letzten Einheiten, und
  die Zahl der erfassten Einheiten insgesamt.
- **Auswertung** — sieben Blöcke, die aus den Daten eine überprüfbare Aussage
  machen. Jeder trägt eine eigene Mindestdatenmenge und ist unterhalb davon
  gesperrt. Ein gesperrter Block **verschwindet nicht** — sonst sieht nach
  einem Neubeginn niemand, was die App kann. Er zeigt stattdessen, was kommen
  wird und ab wann, ohne eine Zahl zu behaupten, die er nicht hat. Wie das
  aussieht, ist die eigentliche Aufgabe an dieser Stelle.
- **Pläne** — die eigenen Pläne, der Weg zu einem neuen, und ein Platz für
  Pläne, die ATEM später anbietet (frei und als Premium). Letzteres ist heute
  leer und soll trotzdem sichtbar sein.

### 4. Die Zustände einer Seite mit vier Themen

Vier Themen laden gleichzeitig, werden gleichzeitig leer und scheitern
unabhängig voneinander. Eine Seite, die an vier Stellen gleichzeitig lädt, ist
etwas anderes als vier Seiten, die je einmal laden. Das braucht eine Haltung,
nicht vier einzelne Lösungen.

Besonders: der **Neubeginn** — jemand hat gerade angefangen, „Trainieren" ist
voll, „Verlauf" und „Auswertung" haben nichts, „Pläne" hat nur die
Ankündigung. Dieser Zustand ist der erste Eindruck der App und darf nicht wie
ein Defekt aussehen.

## Bewegung

Bewegung ist bei ATEM kein Beiwerk. Messlatte ist GSAP-Qualität: orchestriert
statt verstreut, und jede Bewegung sagt etwas.

Gestalte die Übergänge mit, nicht nur die Zustände — insbesondere, was
passiert, während man von einem Thema ins nächste scrollt, und was ein Tipp auf
die Navigation auslöst. Für jede Bewegung: Auslöser, Eigenschaft, Dauer, Kurve,
Ruhelage — und was davon bleibt, wenn im System „Animationen reduzieren"
gesetzt ist. Eine dekorative Dauerschleife muss dann stillstehen können, ohne
dass es wie ein Renderfehler aussieht.

## Verbindliche Randbedingungen

Das ist alles, was feststeht. Der Rest ist deine Entscheidung.

- Nur Tokens aus `atem_theme.dart`. Keine erfundenen Zwischentöne, keine
  vierte Flächenebene, keine zehnte Muskelfarbe.
- `#94A3B8` ist die dunkelste erlaubte Textfarbe. `#7A2BDB` ist nur Fläche,
  nie Text.
- Drei Textstufen: Weiss für Titel und die Hauptzahl eines Blocks, `#CDD3EA`
  für Sätze, die gelesen werden, `#94A3B8` für Metazeilen und Beschriftungen.
- Jedes Tap-Ziel ≥ 48 dp. Informationstragender Text ≥ 12 sp, Kontrast
  ≥ 4,5:1.
- Muss bei 200 % Systemschrift auf 320 dp Breite ohne Überlauf funktionieren.
- Farbe ist nie der einzige Statusträger — immer Wort, Glyph oder Form daneben.
- Kein Material-Ripple.
- Höchstens ein `BackdropFilter` je scrollender Seite.
- Jede Zahl nennt ihre Grundlage mit Nenner. Kein Sollverhältnis, kein Urteil,
  keine Ampelfarben.
- Ausserhalb der Auswertung gilt: ein Block ohne Daten rendert nicht — der
  Bildschirm hört einfach früher auf.
- Prüfe die Bausteine aus den Modulen 2, 3, 5, 6, 9 und 11, bevor du etwas
  Neues erfindest. Was wirklich neu ist, benenne ausdrücklich als neu.

## Liefergegenstände

1. **Artboards** — die Seite im Normalfall, beim Laden, beim Neubeginn und bei
   200 % auf 320 dp; die Navigation in jedem ihrer Zustände; der Übergang
   zwischen zwei Themen als Bildfolge
2. **Spezifikationstabelle** — je Element: Höhe, Innenpolster, Fläche,
   Typ-Rolle, Tap-Ziel
3. **Bewegungstabelle** — je Übergang: Auslöser, Eigenschaft, Dauer, Kurve,
   Ruhelage, Verhalten bei reduzierter Bewegung
4. **Stringtabelle** — `key | Deutsch | Englisch`
5. **A11y-Notizen** — wie die Navigation angesagt wird, wie ein Screenreader
   einen Themenwechsel erfährt, den niemand ausgelöst hat, und was stumm bleibt
6. **Wiederverwendungsliste** — was aus bestehenden Modulen kommt, was neu ist
7. **Entscheidungsprotokoll** — jede verworfene Idee mit dem Grund gegen sie
