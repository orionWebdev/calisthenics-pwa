# Design-Gespräch 14 — Gewichtsverlauf im Hybrid-Tab

**Stand:** 20.09.2026 · Offener Auftrag, bewusst ohne Lösungsvorgabe
Kopiere ab der Trennlinie in Claude Design.

---

## Kontext

ATEM Hybrid — Android-App (Flutter) für hybrides Training, ein Nutzer, ein
Gerät im Blick: Honor VKJ-NX9, 361 dp breit, Systemschrift 1,15. Ästhetik:
Dark Cyber-Athlete. Farbsystem, Typenskala und die Bausteine aus den Modulen
1 bis 3 sind gesetzt und Grundlage, nicht Gegenstand dieses Gesprächs.

Die Bottom-Bar hat drei Plätze: **Kraft · Cardio · Hybrid**. Hier geht es
ausschliesslich um den Platz **Hybrid**, in dem heute Regeneration, die Woche
und der heutige Tag liegen.

## Worum es geht

Ein neuer Block: **das eigene Körpergewicht über die Zeit.**

Heute kennt ATEM genau eine Zahl — den Wert aus den Einstellungen, mit dem die
Trainingslast gerechnet wird. Er wird gelegentlich überschrieben, und was
vorher dastand, ist dann weg. Aus dieser einen Zahl soll eine Reihe werden:
eintragen, wiederfinden, den Verlauf sehen.

Das ist bewusst **kein Abnehm-Werkzeug**. ATEM sagt niemandem, wie viel er
wiegen soll, und kennt kein Ziel- oder Sollgewicht. Der Block zeigt, was war —
mehr nicht. Die schwierige Gestaltungsfrage steckt genau darin: Ein
Gewichtsverlauf sieht in jeder anderen App aus wie eine Bewertung, mit grüner
Linie nach unten. Diese Linie darf hier nicht bewertet werden und muss
trotzdem etwas taugen.

## Was zu gestalten ist

### 1. Der Block im Hybrid-Tab

Was steht sichtbar da, wenn man den Tab öffnet? Ein Wert, eine Veränderung,
eine Kurve — in welcher Reihenfolge, in welcher Dichte? Der Tab trägt schon
andere Blöcke; dieser muss sich einfügen, nicht die Seite an sich reissen.

Bedenke: Ein Körpergewicht ändert sich langsam und schwankt am selben Tag um
mehr, als es in einer Woche wandert. Eine Kurve über zwei Wochen zeigt vor
allem Rauschen, eine über zwei Jahre vor allem eine Gerade. Welcher Zeitraum
sichtbar ist und ob man ihn wechseln kann, ist deine Entscheidung — mit
Begründung.

### 2. Das Eintragen

Ein Gewicht einzutragen dauert drei Sekunden und passiert im Bad, nicht am
Schreibtisch. Der Weg dorthin gehört zum Entwurf: Wo beginnt er, wie sieht die
Eingabe aus, was passiert unmittelbar danach?

Die App hat dafür ein Eingabeblatt mit Zahlenband und Tastatur-Umschalter
(Modul „Eingabeblatt", `AtemStepPad`). Prüfe, ob es passt, statt etwas Neues
zu erfinden — und sag es ausdrücklich, wenn es nicht passt.

Offene Fragen, die der Entwurf beantworten muss:
- Was passiert, wenn für denselben Tag schon ein Wert steht?
- Lässt sich ein Eintrag korrigieren oder löschen, und wo?
- Wird der heutige Tag angeboten oder frei datiert?

### 3. Die Herkunft eines Werts

Später soll ATEM Gewichte aus **Health Connect** lesen, wohin auch Garmin,
Withings und Waagen anderer Hersteller schreiben. Dann stehen zwei Arten von
Werten nebeneinander: getippte und gemessene.

Sie sind nicht gleich viel wert und dürfen nicht gleich aussehen — aber die
Unterscheidung darf die Darstellung auch nicht zerreissen. Wie machst du das
sichtbar, ohne eine zweite Bedeutungsebene aufzumachen?

### 4. Die Beziehung zur Einstellung „Körpergewicht"

In den Einstellungen steht ein Körpergewicht, und jede Lastberechnung der App
hängt daran. Sobald es eine Reihe gibt, gibt es zwei Orte für dieselbe Sache.

Das muss aufgelöst werden — als Entwurf, nicht als Fussnote: Was zeigt die
Einstellung dann? Ändert ein neuer Eintrag im Verlauf sie mit? Und was sieht
jemand, der das Gewicht bisher nur dort gepflegt hat?

### 5. Zustände

Pflicht, jeder als eigenes Artboard:

- **Noch kein Wert.** Hier liegt ein Widerspruch, den du auflösen musst: In
  ATEM rendert ausserhalb der Auswertung ein Block ohne Daten **nicht** — der
  Bildschirm hört einfach früher auf, keine Platzhalterkarte, kein „Leg los!".
  Ein Verlauf ohne einen einzigen Eintrag wäre danach unsichtbar, und niemand
  fände je den Weg zum ersten Eintrag. Wo liegt dieser Weg stattdessen?
- **Ein einziger Wert.** Kein Verlauf, keine Veränderung, keine Kurve — und
  trotzdem etwas Sinnvolles.
- **Dünne Daten.** Drei Werte über vier Monate. Sichtbar dünn, nicht glatt
  gerechnet.
- **Lücken.** Zwischen zwei Einträgen liegen sechs Wochen. **Über Tage ohne
  Ereignis wird nicht interpoliert** — die Linie darf nicht behaupten, was
  dazwischen war.
- **Laden** und **Fehler.**

## Bewegung

Bewegung ist bei ATEM kein Beiwerk. Messlatte ist GSAP-Qualität: orchestriert
statt verstreut, und jede Bewegung sagt etwas.

Interessant hier: der Moment nach dem Eintragen — ein neuer Punkt betritt eine
Kurve, die es vorher schon gab. Und der Wechsel des Zeitraums, falls dein
Entwurf einen vorsieht. Für jede Bewegung: Auslöser, Eigenschaft, Dauer, Kurve,
Ruhelage — und was davon bleibt, wenn im System „Animationen reduzieren"
gesetzt ist.

## Verbindliche Randbedingungen

Das ist alles, was feststeht. Der Rest ist deine Entscheidung.

- Nur Tokens aus `atem_theme.dart`. Keine erfundenen Zwischentöne, keine
  vierte Flächenebene, keine zehnte Muskelfarbe.
- `#94A3B8` ist die dunkelste erlaubte Textfarbe. `#7A2BDB` ist nur Fläche,
  nie Text.
- Drei Textstufen: Weiss für Titel und die Hauptzahl, `#CDD3EA` für Sätze, die
  gelesen werden, `#94A3B8` für Metazeilen und Beschriftungen.
- Jedes Tap-Ziel ≥ 48 dp. Informationstragender Text ≥ 12 sp, Kontrast
  ≥ 4,5:1.
- Muss bei 200 % Systemschrift auf 320 dp Breite ohne Überlauf funktionieren.
- Farbe ist nie der einzige Statusträger — immer Wort, Glyph oder Form daneben.
- Kein Material-Ripple. Gedrückt = `scale 0.97` + Akzent-Glow, 200 ms.
- **Kein Soll, kein Urteil, keine Ampelfarben.** Eine Veränderung ist eine
  Tatsache in `#CDD3EA` mit Richtungsglyph. „Weniger" ist nicht „besser".
- Jede Zahl nennt ihre Grundlage mit Nenner — „12 Einträge seit dem 3. Juli",
  nicht „−2,4 kg".
- Keine Interpolation über Tage ohne Ereignis.
- Erklärungen sind versteckt: Sichtbar bleiben Titel, Wert und eine kurze
  Grundlage; was der Block zeigt und wie gerechnet wird, steht hinter dem ⓘ
  neben dem Titel (`AtemExplainHeader`). Höchstens **eine** sichtbare
  Hinweiszeile ausser der Grundlage.
- Prüfe die Bausteine aus den Modulen 2, 3, 5, 6 und 9, bevor du etwas Neues
  erfindest — besonders Karte, Chart, Eingabeblatt und Erklärungskopf. Was
  wirklich neu ist, benenne ausdrücklich als neu.

## Liefergegenstände

1. **Artboards** — der Block im Normalfall, mit einem einzigen Wert, mit dünnen
   Daten, mit Lücke, beim Laden, im Fehlerfall und bei 200 % auf 320 dp; dazu
   der Weg zum Eintragen in jedem seiner Schritte
2. **Spezifikationstabelle** — je Element: Höhe, Innenpolster, Fläche,
   Typ-Rolle, Tap-Ziel
3. **Bewegungstabelle** — je Übergang: Auslöser, Eigenschaft, Dauer, Kurve,
   Ruhelage, Verhalten bei reduzierter Bewegung
4. **Stringtabelle** — `key | Deutsch | Englisch`, Zählformen mit Einzahlform,
   Platzhalter in geschweiften Klammern
5. **A11y-Notizen** — wie ein Datenpunkt vorgelesen wird (eine Zeile, ein
   Knoten), wie eine Lücke klingt, was stumm bleibt, wie die Kurve als Ganzes
   angesagt wird
6. **Wiederverwendungsliste** — was aus bestehenden Modulen kommt, was neu ist
7. **Entscheidungsprotokoll** — jede verworfene Idee mit dem Grund gegen sie
