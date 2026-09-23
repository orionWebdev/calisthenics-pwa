# Prompt für Claude Design — Modul 18: Das Zielbriefing

**Stand:** 23.09.2026 · Offener Auftrag, bewusst ohne Lösungsvorgabe.
Erstes von drei Boards zur Wochenplanung: **18 Zielbriefing → 19 Woche von Hand →
20 Vorschlag.** Das Datenmodell steht vorab in
`docs/contracts/04-firestore-schema.md`, § `userProfiles/{uid}/planning`.
Kopiere ab der Trennlinie in Claude Design.

---

## Worum es geht

ATEM Hybrid ist eine private Android-App für hybrides Training (Kraft und
Ausdauer), Ästhetik „Dark Cyber-Athlete". Drei Tabs: **Kraft · Cardio ·
Hybrid**. Die App schreibt mit, was jemand trainiert, und wertet es aus — ohne
Sollwert, ohne Urteil.

Als Nächstes bekommt sie eine **Wochenplanung**. Sie wird eine eigene
Unterseite, erreichbar aus dem Hybrid-Tab. Bevor die App eine Woche planen
hilft — und erst recht, bevor sie je eine vorschlägt —, muss sie wissen, was
jemand überhaupt will. Das ist dieses Board: **das Zielbriefing**, der
Bildschirm, auf dem jemand in eigenen Worten sagt, wie sein Training aussehen
soll.

Warum zuerst dies und nicht die Woche: Ein Vorschlag ohne Briefing wäre eine
Verordnung — die App würde behaupten, wie viel Training richtig ist. Das
verbietet sie sich. Mit Briefing ist ein späterer Vorschlag eine Ableitung aus
der eigenen Aussage des Nutzers, mit Grundlage wie jede andere Zahl.

**Jede Frage, die die App stellt, ist eine Behauptung darüber, was zählt.** Die
Fragen selbst sind deshalb Gestaltung, nicht nur ihr Layout.

## Wer das ausfüllt — vier Menschen, die es wirklich gibt

Ein Briefing, das diese vier nicht auseinanderhalten kann, ist wertlos, weil
jede spätere Ableitung dann dreimal danebenliegt:

1. **Drei Kraft- und drei Cardio-Einheiten die Woche**, an ungefähr festen Tagen.
2. **Nur Kraft.** Cardio kommt nicht vor, und die App soll auch nicht
   nachfragen, warum.
3. **Nur Cardio.** Läuft, fährt Rad, schwimmt. Der Kraft-Tab ist für diese
   Person leer, und das ist kein Mangel.
4. **Mehrmals am Tag** — morgens Lauf, abends Kraft, manchmal zwei Kraftblöcke.
   Hier stimmt schon die Einheit „Tag" als Rhythmus nicht mehr.

Dazu Varianten, die jede der vier treffen: feste Wochentage oder freier
Rhythmus; eine Woche, die alle zwei Wochen anders aussieht (Schicht, Kinder);
jemand, der gerade nach einer Pause neu anfängt.

## Was vorgegeben ist — und was nicht

**Gesetzt:**

- **Das Briefing gehört nicht in den Einstieg.** Das Onboarding (Board 04)
  fragt genau eine Zahl, das Körpergewicht, nach dem Leitsatz: *„Ins
  Onboarding gehört eine Angabe nur, wenn ohne sie eine falsche Zahl
  entsteht."* Ein fehlendes Ziel erzeugt keine falsche Zahl. Wer die App nur
  zum Mitschreiben nutzt, soll das Briefing nie sehen müssen.
  Willst du das anders entscheiden, dann mit einem Grund im
  Entscheidungsprotokoll, der gegen diesen Leitsatz besteht.
- **Es ist überspringbar, jederzeit nachholbar und jederzeit änderbar.**
- **Eine unbeantwortete Frage ist keine Null.** „Cardio: 0× die Woche" ist eine
  Aussage; „Cardio: nicht beantwortet" ist keine. Der Bildschirm muss beides
  unterscheidbar halten — auch beim späteren Wiederansehen.
- **Nichts ist vorbelegt.** Keine Antwort steht beim Öffnen schon da, und
  keine ist hervorgehoben. „5× die Woche" darf nicht die markierte Wahl sein —
  das wäre ein Sollwert in Form einer Voreinstellung.

**Offen — das entscheidest du:**

- **Welche Fragen.** Ein Vorschlag, nicht gesetzt: Was trainierst du (Kraft ·
  Cardio · beides) · wie oft je Art in der Woche · feste Tage oder freier
  Rhythmus · mehrmals am Tag ja/nein · was ist dir wichtig · was soll die App
  **nicht** tun. Streichen, zusammenlegen, ersetzen ist erwünscht — mit Grund.
- **Wie viele Fragen es sein dürfen, bevor jemand abbricht.**
- **Die Form**: ein Formular auf einer Seite, eine Frage je Schritt, etwas
  Drittes.
- **Wo man es findet**: aus der künftigen Planungsseite, aus den
  Einstellungen, an beiden Orten.

## Drei Fragen, die das Board beantworten muss

1. **Was passiert mit einem halb ausgefüllten Briefing?** Gilt es, oder gilt es
   nicht? Ein halbes Profil, das so tut, als wäre es ganz, ist schlimmer als
   keines. Wie sieht man später, welche Fragen offen sind — ohne dass der
   Bildschirm mahnt?
2. **Wie sagt der Bildschirm, wofür die Antworten gebraucht werden, ohne etwas
   zu versprechen, das die App noch nicht kann?** Den Planvorschlag (Board 20)
   gibt es noch nicht. Das Briefing darf ihn nicht ankündigen. Es darf aber
   auch nicht so tun, als würden die Antworten nirgends hingehen.
3. **Darf die App die Woche später an der eigenen Aussage messen?** „2 von 3
   Kraft-Einheiten diese Woche" — der Nenner stammt vom Nutzer selbst, nicht
   von der App. Ist das eine Auskunft oder schon ein Urteil? Die Antwort
   bestimmt, wie Board 19 aussehen darf; sie gehört ins Entscheidungsprotokoll.

## Nicht verhandelbar

- Nur die Farbtokens aus `atem_theme.dart` / README §3. **Keine erfundenen
  Zwischentöne, keine vierte Farbebene.** Drei Flächen: Grund `#050507`,
  Karte `#14141D`, angehobene Fläche `#1A1A26` — dazu `#0B0B0E` für deckende
  Kästen.
- **Cyan trägt Handlung** — wer Cyan sieht, kann tippen. **Der Bereichston
  trägt den Ort**: Die Planung kommt aus dem Hybrid-Tab, dessen Ton ist
  `#AB6BF0`. Er ist nie ein Versprechen auf eine Handlung.
  **Violett `#7A2BDB` ist nur Fläche, nie Text.** Magenta ist Marke und
  Eingriff: der eine Haupt-CTA, Löschen, Störung.
- `#94A3B8` ist die dunkelste erlaubte Textfarbe. Informationstragender Text
  ≥ 12 sp, Kontrast ≥ 4,5:1.
- **Drei Textstufen:** Weiss für Titel · `#CDD3EA` für Sätze, die gelesen
  werden · `#94A3B8` für Metazeilen und Beschriftungen.
- Farbe ist nie der einzige Statusträger — immer Wort, Glyph oder Icon daneben.
  Gewählt/nicht gewählt muss auch ohne Farbe erkennbar sein.
- Jedes Tap-Ziel ≥ 48 dp. Kein Material-Ripple: gedrückt = `scale 0.97` +
  Akzent-Glow, 200 ms.
- Muss bei **200 % Systemschrift auf 320 dp Breite** ohne Überlauf
  funktionieren. Kein Verkleinern von Text, kein horizontales Scrollen. Eine
  Reihe aus sieben Wochentags-Chips ist bei 200 % der klassische Bruch.
- **Höchstens ein `BackdropFilter` pro scrollendem Screen.**
- **Genau eine Karte mit Gradient-Rand je Bildschirm** — oder keine.
- **Schreiben ist reversibel und deshalb optimistisch**: sofort übernommen;
  lehnt der Server ab, geht es zurück ins Formular — nicht in einen Toast.
  Snackbars stehen 6 s.

## Haltung

- **Kein Urteil, kein Sollwert.** Die App weiss nicht, wie viel Training
  richtig ist, und sagt es auch nicht durch die Hintertür (Voreinstellung,
  Reihenfolge der Optionen, „empfohlen"-Marke, Fortschrittsbalken, der zum
  Ausfüllen drängt).
- **Ein übersprungenes Briefing ist kein Mangel.** Kein Badge, kein roter
  Punkt, kein „Profil zu 40 % vollständig", keine Erinnerung.
- **Keine Motivationssprache.** Kein „Lass uns deine Ziele erreichen!", kein
  Emoji. Die App redet wie ein genauer Trainingspartner, nicht wie ein
  Onboarding-Funnel.
- **Wenige Worte.** Erklärungen sind versteckt hinter einem ⓘ neben dem Titel
  (Baustein `AtemExplainHeader`) und klappen im Block auf. Sichtbar bleibt
  höchstens eine Hinweiszeile je Block.

## Was es schon gibt

- **Board 04** (Onboarding): der Leitsatz oben und die Form der einen Frage
  dort — Eingabe, Einheitensegment, Weiter.
- **Board 07** (Daten & Eingaben): die Formularbausteine, Fehler zurück ins
  Formular, der deaktivierte Knopf mit Grund im Label („Speichern, nicht
  möglich, noch 3 Angaben nötig").
- **Board 08** (Einstellungen): Gruppen, Zeilen mit Chevron, Unterseiten.
- **Board 13** (die Ortszeile): wie ATEM eine Seite mit mehreren Themen
  gliedert, ohne Reiterleiste.
- Im Profil der Vorgänger-App stehen noch `trainingStyle` (Gerät ·
  Eigengewicht · Hybrid) und `trainingLevel`. **Sie werden nicht
  übernommen** — sie beantworten andere Fragen (Ausstattung,
  Selbsteinschätzung). Wenn du eine davon für das Briefing brauchst, frag sie
  neu und begründe es.

## Zustände sind Pflicht

Jeder als eigenes Artboard:

- **leer** — noch nie ausgefüllt, erster Aufruf
- **halb ausgefüllt** — abgebrochen, später wieder geöffnet
- **vollständig** — und wie es beim Wiederansehen aussieht: Zusammenfassung
  oder wieder das Formular?
- **lädt**
- **Fehler** — beim Laden und beim Speichern getrennt

Dazu die vier Nutzer von oben je mit ausgefülltem Briefing, damit sichtbar
wird, dass das Briefing sie auseinanderhält.

## Bewegung

Bewegung ist bei ATEM kein Beiwerk. Messlatte ist GSAP-Qualität: orchestriert
statt verstreut, und jede Bewegung sagt etwas.

Interessant hier: der Übergang zwischen Fragen (wenn es Schritte sind), der
Moment, in dem eine Antwort gewählt wird, und wie eine Antwort eine Folgefrage
öffnet oder schliesst („nur Kraft" → die Cardio-Fragen verschwinden). Für jede
Bewegung: Auslöser, Eigenschaft, Dauer, Kurve, Ruhelage — und was davon bleibt,
wenn im System „Animationen reduzieren" gesetzt ist. Dekorative Dauerschleifen
stehen dann still.

## Was ich von dir brauche

Ein Spezifikations-Board im Format der Module 1–17: **Leitsatz**, Artboards je
Zustand, **Spezifikation** (Maße, Abstände, Flächen, Typo, Tap-Ziele),
**Motion**, **Stringtabelle** (`key | Deutsch | Englisch`, Deutsch ist primär,
Zählformen mit Einzahl, Platzhalter in `{n}`), **A11y-Notizen** (Element ·
Semantics-Label · Rolle · Zustand), **Wiederverwendung** und ein
**Entscheidungsprotokoll** mit Gewähltem und Verworfenem samt Begründung —
darunter die drei Fragen oben.

**Nicht Teil dieses Boards:** die Woche selbst (Board 19), der Vorschlag
(Board 20), das Heute-Widget im Hybrid-Tab. Wenn das Briefing etwas davon
voraussetzt, halte es im Protokoll fest, statt es zu entwerfen.

**Gestalte deine eigene Lösung.** Ich habe bewusst keine Fragenliste, keine
Maße und kein Layout festgelegt. Was oben steht, ist das Problem und die
Grenzen — nicht der Entwurf.
