# Nachtrag zu Board 16 — die Herkunft einer gerechneten Zahl, und wie fein ein Pulsverlauf sein muss

**Stand:** 22.09.2026. Zwei Fragen, die Board 16 noch nicht kannte, weil die
Sachen, um die es geht, erst danach entstanden sind. Kein neues Board —
ein Nachtrag zum bestehenden.

Kopiere alles ab der Trennlinie in Claude Design.

---

## Worum es geht

ATEM Hybrid ist eine private Android-App für hybrides Training (Kraft und
Ausdauer), Ästhetik „Dark Cyber-Athlete". **Board 16** hat das
**Einheitendetail** gefasst: einen Kopf mit bis zu vier Kacheln, darunter so
viele Blöcke, wie Daten da sind — Arbeit, Puls & Zonen, Notiz, Herkunft,
Eingriffe.

Seit dem 22.09.2026 stimmen zwei Dinge daran nicht mehr.

## Problem 1 — Die Last ist jetzt teilweise gemessen, und das sieht man nicht

Die Kachel **„Last"** trägt eine Zahl, die die App rechnet: Volumen bzw. Dauer
mal einem Faktor für die Anstrengung. Im Board steht sie ausdrücklich zuletzt
im Kachelkatalog, mit der Begründung „App-Rechnung, keine Messung".

Jede Kachel trägt heute genau **zwei** mögliche Herkünfte:

- **App** — selbst geführt, selbst gerechnet.
- **Uhr** — gemessen, aus Health Connect übernommen.

Seit dem 22.09. gilt für Cardio-Einheiten eine neue Reihenfolge, wenn die Last
gerechnet wird:

1. Was jemand als Anstrengung **eingetragen** hat, gilt.
2. **Fehlt** sie, tritt die aus dem Pulsverlauf **gemessene** Anstrengung an
   ihre Stelle (der zeitgewichtete Schnitt der Zonennummer, gerundet auf 1–5).
3. Sonst wie bisher der neutrale Ersatzwert.

Im zweiten Fall ist die Last **beides**: eine App-Rechnung, deren wichtigste
Eingangsgrösse aus der Uhr stammt. „App" wäre gelogen, „Uhr" auch.

**Das verstösst gegen eine Hausregel**, die über allem steht: *Jede Zahl nennt
ihre Grundlage.* Heute nennt sie ihre nicht.

**Die Frage:** Braucht die Herkunft eine dritte Form — und wenn ja, welche?
Oder gehört diese Auskunft gar nicht an die Kachel, sondern hinter das ⓘ, und
die Herkunft bleibt binär?

**Eine Spur, die schon da liegt — aber vielleicht die falsche.** Für die
**Zeilen im Verlauf** gibt es bereits vier Punktformen (Board 15, B6):
gefüllt = selbst geführt · hohl = aus fremder Quelle · **Ring mit Kern =
beides, zusammengeführt** · gestrichelt = noch ungeprüft. „Ring mit Kern"
sieht aus wie die Antwort. Aber dort heisst es „**diese Einheit** entstand aus
zwei Datensätzen", hier hiesse es „**diese Zahl** ist gerechnet aus einem
gemessenen Wert". Dieselbe Form für zwei verschiedene Aussagen ist billig zu
bauen und teuer zu verstehen. Entscheide das bewusst, in die eine oder die
andere Richtung, und schreib den Grund ins Protokoll.

**Randbedingungen für die Kachel:** Sie ist klein — vier davon liegen
nebeneinander im Kopf, bei 200 % Schrift auf 320 dp bricht das Raster ohnehin
schon um. Was immer dazukommt, muss dort hineinpassen, ohne die Zahl zu
verdrängen. Und es darf **keine neue Farbebene** aufmachen: Die Herkunft wird
heute über Fläche und Glyph getragen, nicht über eine eigene Farbe.

**Der Fall, der auch beantwortet sein will:** Was steht in der Kachel, wenn
die gemessene Anstrengung die eingetragene *nicht* ersetzt hat, weil beide da
waren? Dann ist die Last wieder reine App-Rechnung — aber daneben lag trotzdem
eine Messung. Sagt die Kachel das, oder ist das eine Auskunft für das ⓘ?

## Problem 2 — Der Pulsverlauf ist minutengenau, und Intervalle sind kürzer

Der Block **„Puls & Zonen"** hat seit dem 22.09. einen Verlauf: bpm über die
Zeit, jede Minute ein Punkt, echte Lücken als Lücken. Die Linie trägt die
**Farbe der Zone**, in der ihr Wert liegt; Haarlinien liegen auf den
Zonengrenzen; höchster und niedrigster Wert tragen einen Ring; die Spanne
steht darüber; wer über die Kurve zieht, liest Zeit, Wert und Zone ab.

**Die Auflösung ist eine Minute, und feiner geht es nicht.** Gespeichert wird
je Minute *ein* gemittelter Wert. Zwanzig Sekunden in einer höheren Zone sind
in dieser Minute mitgemittelt; sie erscheinen nicht als eigener Abschnitt.

Für ein ruhiges Ausdauertraining reicht das. Für ein Intervalltraining mit
30/30 oder 40/20 ist es womöglich zu grob: Genau die Struktur, die man sehen
will, verschwindet im Mittel.

**Am Gerät wird daraus ein sichtbarer Widerspruch.** In einer echten Einheit
vom 13.09. steht im selben Block, untereinander:

- die Kacheln **Ø 96 · Max 120 · Min 71** — aus den Rohwerten,
- und über der Kurve **„85–109 bpm"** — aus den Minutenmitteln.

Beides stimmt, beides beschreibt dieselben 24 Minuten, und die Zahlen
widersprechen sich trotzdem. Keine von beiden sagt, worauf sie beruht. Wer das
liest, sucht den Fehler bei sich.

**Auch das gehört entschieden:** Sagt die Spanne über der Kurve, dass sie aus
Minutenmitteln stammt? Verschwindet sie, weil die Kacheln darüber dasselbe
besser beantworten? Oder ist es genau der Beweis, dass die Kurve feiner
aufgezeichnet werden muss, bis beide Zahlen zusammenfallen?

**Die Frage:** Muss der Verlauf feiner sein, damit er seinen Zweck erfüllt?
Eine feinere Ablage (etwa alle zehn Sekunden) ist machbar — sie kostet die
sechsfache Menge Punkte je Einheit und einen Schemawechsel, und sie wirkt
**nur auf künftig gelesene** Einheiten; die vorhandenen bleiben minutengenau.

Wenn die Antwort „ja" lautet, braucht es eine zweite: **Wie sieht eine Kurve
aus, die beides kann** — eine alte Einheit mit Minutenwerten und eine neue mit
Zehn-Sekunden-Werten, nebeneinander im selben Verlauf? Eine Kurve, die je nach
Alter anders aussieht, ohne es zu sagen, behauptet einen Unterschied im
Training, wo nur einer in der Aufzeichnung liegt.

## Nicht verhandelbar

- Nur die Tokens aus `atem_theme.dart`. Keine erfundenen Zwischentöne, keine
  neue Farbebene.
- `#94A3B8` ist die dunkelste erlaubte Textfarbe. Violet `#7A2BDB` ist nur
  Fläche, nie Text.
- Jedes Tap-Ziel ≥ 48 dp Trefferfläche. Kein Material-Ripple.
- Muss bei **200 % Systemschrift auf 320 dp Breite** ohne Überlauf
  funktionieren. Nichts wird ellipsiert, nichts verkleinert.
- **Farbe nie als einziger Statusträger** — immer Wort, Glyph oder Icon
  daneben. Das gilt auch für die Zonenfarben der Kurve.
- Informationstragender Text ≥ 12 sp effektiv, Kontrast ≥ 4,5:1.
- Eine Datenzeile ist **ein** Semantics-Knoten, nicht vier.
- Jede Zahl nennt ihre Grundlage, mit Nenner. Kein Sollverhältnis, kein
  Urteil: Die App weiss nicht, wie viel Zone 4 richtig ist, und sagt es auch
  nicht zwischen den Zeilen.

## Was es schon gibt und was bleibt

- **Die fünf Zonenfarben** stehen fest: Zone 1 Cyan · 2 Grün · 3 Gelb ·
  4 Orange · 5 Rot. Sie unterscheiden, sie bewerten nicht. Kein Text nennt
  eine Zone „hoch", „gut" oder „zu viel".
- **Die vier Punktformen der Herkunft** (gefüllt · hohl · Ring mit Kern ·
  gestrichelt) aus Board 15.
- **Das ⓘ** neben einem Blocktitel: Es klappt *im Block* auf, es öffnet kein
  Blatt. Dort stehen Formeln, Hinweise und das „wie gerechnet wird".
- **Die Kurve selbst** mit Farben, Grenzlinien, Ringen, Spanne, Zeitachse und
  Schieber. Sie steht; hier geht es nur um ihre Auflösung.
- Der Block trägt **höchstens eine** sichtbare Hinweiszeile ausser der
  Grundlage.

## Haltung

Die App beschreibt, sie beurteilt nicht. Sie sagt, was war und woher sie es
weiss — und wenn sie etwas nicht weiss, sagt sie das lieber, als eine glatte
Zahl hinzustellen. Eine Herkunft ist keine Verzierung: Sie ist der Unterschied
zwischen „das hat jemand gemessen" und „das habe ich ausgerechnet".

## Bewegung

Was heute schon läuft, zur Orientierung:

- Die Kurve zeichnet sich **einmal** von links nach rechts, 420 ms,
  `easeOutQuart` — dieselbe Dauer wie die Zonenspuren im selben Block.
- Der Schieber folgt dem Finger ohne eigene Dauer; die Marke springt auf die
  nächstgelegene gemessene Minute.
- Bei „Animationen reduzieren" steht alles sofort fertig da. Keine
  dekorative Dauerschleife, die dann halb eingefroren stehen bliebe.

**Was ich dazu von dir brauche:** Bewegt sich etwas, wenn eine Kachel ihre
Herkunft zeigt — oder ist das ein Zustand, der einfach da ist? Wenn sich etwas
bewegt: wodurch ausgelöst, wie lange, welche Kurve, und welcher Zustand ist
die Ruhelage.

## Was ich von dir brauche

1. **Artboards** für Problem 1: die Kachel „Last" in allen Herkunftsfällen,
   die es geben kann — reine Rechnung, Rechnung über einer Messung, und (falls
   du ihn für nötig hältst) der Fall „eingetragen, aber gemessen lag daneben".
   Jeweils bei 100 % und bei 200 % auf 320 dp.
2. **Artboards** für Problem 2, falls die Antwort „feiner" lautet: dieselbe
   Einheit minutengenau und zehnsekundengenau nebeneinander, plus der
   gemischte Verlauf.
3. **Ein Entscheidungsprotokoll.** Für jede verworfene Idee der Grund gegen
   sie — besonders für „Ring mit Kern wiederverwenden" oder eben nicht.
4. **Eine Stringtabelle** `key | Deutsch | Englisch`, Deutsch primär,
   Platzhalter in geschweiften Klammern. Zählformen brauchen in beiden
   Sprachen eine Einzahlform.
5. **Eine A11y-Sektion**: Was liest ein Screenreader für eine Kachel, deren
   Zahl teils gemessen ist? Welches Wort steht für die dritte Herkunft — denn
   ein Glyph allein wird nie vorgelesen.
