# Prompt für Claude Design — Modul 19: Die Woche von Hand

**Stand:** 23.09.2026 · Offener Auftrag, bewusst ohne Lösungsvorgabe.
Zweites von drei Boards zur Wochenplanung: **18 Zielbriefing → 19 Woche von
Hand → 20 Vorschlag.** Board 18 ist gebaut und hält in Sektion K fest, was
dieses Board voraussetzt. Datenmodell: `docs/contracts/04-firestore-schema.md`,
§ `userProfiles/{uid}/planning`. Läuft parallel zu Board 18b
(Bewegungsgrammatik) — für Bewegung gilt, was dort entschieden wird; hier
bitte nur, was diesem Bildschirm eigen ist.
Kopiere ab der Trennlinie in Claude Design.

---

## Worum es geht

ATEM Hybrid ist eine private Android-App für hybrides Training (Kraft und
Ausdauer), Ästhetik „Dark Cyber-Athlete". Drei Tabs: **Kraft · Cardio ·
Hybrid**. Die App schreibt mit, was jemand trainiert, und wertet es aus —
ohne Sollwert, ohne Urteil.

Dieses Board entwirft die **Wochenplanung von Hand**: den Ort, an dem jemand
seine übliche Woche festlegt — welche Art an welchem Tag, auf Wunsch mit
einem seiner Pläne — und das kleine Widget im Hybrid-Tab, das beantwortet:
**„Was wird heute trainiert?"**

Die App schlägt hier **nichts** vor. Das kommt in Board 20, und nur aus dem,
was jemand selbst gesagt hat. Board 19 ist das Werkzeug, mit dem jemand
selbst plant.

## Was schon feststeht

**Der Ort (entschieden am 22.09.):** Die Planung ist eine **eigene Unterseite
aus dem Hybrid-Tab**, nicht je eine Ausprägung in Kraft und Cardio. Im
Hybrid-Tab selbst steht nur ein **kleines Widget**, das „Was wird heute
trainiert" beantwortet. Cardio gehört dazu — die Planung ist kein reines
Kraft-Thema.

**Das Datenmodell (vorab festgelegt):**

| | Was es ist | Wo es liegt |
|---|---|---|
| **Plan** | Eine Übungsliste mit Zielvorgaben. Kein Datum. Nur Kraft — **Cardio hat keine Pläne.** | `plans` |
| **Termin** | Eine Einheit an einem bestimmten Tag. Bestand der Vorgänger-App; ATEM liest und hakt ab, legt aber keinen an. | `schedule` |
| **Wochenplan** | Ein wiederkehrender Rhythmus: welche Art an welchem Wochentag, optional mit Plan. **Keine Daten, sondern Wochentage.** | `planning/week` — dieses Board |
| **Zielbriefing** | Was jemand über sein Training sagt. | `planning/goal` — Board 18 |

Daraus folgt:
- **„Heute" wird aus dem Rhythmus abgeleitet, nicht gespeichert.** Es gibt
  keine vorab angelegten Termine für Wochen im Voraus.
- **Ein gelöschter Plan ist der Normalfall**, nicht der Fehler: Der Eintrag
  bleibt als freies Training seiner Art stehen.
- **Ein Cardio-Eintrag** trägt seine Art (Lauf, Rad, Schwimmen, …) und
  optional eine Dauer, nie einen Plan.
- Liegt für denselben Tag zusätzlich ein alter Termin in `schedule`, gewinnt
  vorläufig der Termin — **das Datierte schlägt das Wiederkehrende.** Du darfst
  das anders entscheiden, mit Grund.

**Aus Board 18, verbindlich übernommen (Sektion K):**
- **Die Messregel F3.** Die Woche darf mit der eigenen Angabe verglichen
  werden, aber nur als **zwei Tatsachen nebeneinander**: „2 Kraft-Einheiten ·
  angegeben 3". **Nie** als Bruch „2/3", Ring oder Balken, der sich zum Nenner
  hin füllt; kein „übertroffen", kein „noch 1", **kein Farbwechsel beim
  Erreichen**, Mehr und Weniger sehen gleich aus. Die Herkunft steht dabei
  („deine Angabe vom 14. Sept"); bei „so will ich wieder trainieren" heisst es
  „vorgenommen", nicht „angegeben". Ohne beantwortete Häufigkeit: kein
  Vergleich.
- **Wechselwochen** (Schicht, Kinder) sind im Briefing mit einem Anker
  erfasst: Die App weiss, ob diese Kalenderwoche A oder B ist. Die Planung
  braucht dann **zwei Wochen**.
- **Das Briefing wird verlinkt, nicht nachgebaut.** Die Planungsseite öffnet
  dieselbe Seite „Trainingsangaben"; eine zweite Eingabeform für dieselben
  Fragen darf es nicht geben. Das Briefing ist **freiwillig** — die Woche muss
  sich auch ohne es planen lassen.
- Sobald die Planung da ist, steht auf der Briefing-Seite „Genutzt von ·
  Woche (Planung)" statt „bisher keiner Auswertung".

## Die vier Menschen, die das benutzen

Aus Board 18 — die Woche muss für alle vier gut aussehen:

1. **Drei Kraft- und drei Cardio-Einheiten** an festen Tagen (Mo Mi Fr Kraft,
   Di Do Sa Lauf). Der Normalfall.
2. **Nur Kraft**, viermal die Woche, freier Rhythmus. Cardio kommt nicht vor —
   auch nicht als leere Spur.
3. **Nur Cardio**, fünfmal, jede Woche anders. Plant vielleicht gar keine
   festen Tage — was zeigt die Planung dann?
4. **Mehrmals am Tag**: morgens Lauf, abends Kraft, an den meisten Tagen. Ein
   Tag hat hier zwei Einträge, in der Reihenfolge der Tageszeit.

Dazu: **Wechselwochen** (A/B), und **jemand, der nach einer Pause neu
anfängt** — seine Woche ist ein Vorhaben, kein Ist.

## Die Fragen, die das Board beantworten muss

1. **Wie sieht eine Woche aus, die jemand selbst baut?** Sieben Tage,
   Einträge je Tag, Art und optional Plan. Wie legt man einen Eintrag an,
   verschiebt ihn auf einen anderen Tag, entfernt ihn? **Bei 200 % Schrift auf
   320 dp ist eine Sieben-Spalten-Woche unmöglich** — Board 18 hat die sieben
   Tag-Chips schon als Umbruch lösen müssen.
2. **„Heute" erscheint zweimal.** Der Kraft-Tab beantwortet in „Trainieren"
   bereits „Was mache ich jetzt" (Startblock, Board 17, mit „Heute geplant" aus
   einem Termin). Das Hybrid-Widget soll dasselbe für Kraft **und** Cardio
   beantworten. **Wie unterscheiden sich die beiden**, damit sie sich am
   ersten Tag, an dem beide Daten haben, nicht widersprechen? Speisen beide
   aus derselben Ableitung? Darf der Kraft-Tab nur den Kraft-Eintrag zeigen?
3. **Das Hybrid-Widget.** Nachfolger der heutigen Karte „Heute und diese
   Woche" (`TodayWeekCard`). Deren Regel: *„Ohne Termin steht nur die Woche —
   keine leere Zeile, kein ‚nichts geplant'."* Board 17 sagt dasselbe noch
   schärfer: *„Keine Platzhalterkarte, kein ‚Heute nichts geplant': Das
   behauptete einen Mangel."* **Was steht da an einem Tag ohne Eintrag** — ist
   ein Ruhetag im Plan eine Aussage („Heute: Ruhe, laut deiner Woche") und
   damit etwas anderes als ein Tag ohne Plan? Und wie führt das Widget in die
   Planung, ohne ein Aufruf zu sein?
4. **Die Woche und das Ist.** Darf die Planungsseite zeigen, was in dieser
   Woche schon trainiert wurde (ein abgehakter Montag)? Wenn ja: nach
   Messregel F3, ohne Häkchen-Ampel, ohne „verpasst". **Ein nicht
   trainierter, geplanter Tag ist kein Versäumnis** — wie sieht er aus?
5. **Der leere Anfang.** Wer die Planung zum ersten Mal öffnet, hat keine
   Woche. Was steht da — ohne „Leg los!", ohne Platzhalterkarte, und so, dass
   das Briefing als Möglichkeit erkennbar ist, aber nicht als Pflicht?
6. **Das Briefing als Grundlage, nicht als Vorlage.** Wer im Briefing „Kraft
   3×, feste Tage Mo Mi Fr" angegeben hat — füllt die Planung diese Tage vor?
   Das wäre ein Vorschlag, und Vorschläge sind Board 20. Oder zeigt sie die
   Angabe nur als Bezug neben der leeren Woche? Entscheide mit Grund.

## Nicht verhandelbar

- Nur die Farbtokens aus `atem_theme.dart` / README §3. **Keine erfundenen
  Zwischentöne, keine vierte Farbebene.** Drei Flächen: Grund `#050507`,
  Karte `#14141D`, angehobene Fläche `#1A1A26` — dazu `#0B0B0E` für deckende
  Kästen.
- **Cyan trägt Handlung** — wer Cyan sieht, kann tippen. **Der Bereichston
  trägt den Ort**: Die Planung kommt aus dem Hybrid-Tab, `#AB6BF0`. Die
  **Spuren** sind in Board 18 festgelegt: Kraft Amber `#FFB020` als
  Symbolfarbe, Cardio Violett `#7A2BDB` **nur als Fläche** mit weissem Symbol.
  Farbe sagt, welche Spur ein Eintrag betrifft — nie Status, nie Wertung.
- `#94A3B8` ist die dunkelste erlaubte Textfarbe. Informationstragender Text
  ≥ 12 sp, Kontrast ≥ 4,5:1. **Drei Textstufen:** Weiss für Titel und
  Hauptzahl · `#CDD3EA` für Sätze · `#94A3B8` für Metazeilen.
- Farbe ist nie der einzige Statusträger — immer Wort, Glyph oder Icon daneben.
- Jedes Tap-Ziel ≥ 48 dp. Kein Material-Ripple: gedrückt = `scale 0.97` +
  Akzent-Glow, 200 ms. **Ziehen ist nie der einzige Weg** — Verschieben muss
  auch ohne Drag gehen (Screenreader, Schalterbedienung).
- Muss bei **200 % Systemschrift auf 320 dp** ohne Überlauf funktionieren.
  Kein Verkleinern, kein horizontales Scrollen, kein Kürzen von Wochentagen
  auf einen Buchstaben.
- **Höchstens ein `BackdropFilter` pro scrollendem Screen.**
  **Genau eine Karte mit Gradient-Rand je Bildschirm** — oder keine.
- **Schreiben ist reversibel und deshalb optimistisch**; bei Ablehnung zurück
  ins Formular, nicht in einen Toast. Snackbars stehen 6 s. **Löschen einer
  ganzen Woche ist irreversibel** — zwei Stufen, Stufe 1 zählt die Folgen.
- **Bottom-Bar hat genau drei Plätze.** Die Planung ist kein vierter Tab.

## Haltung

- **Kein Urteil, kein Sollwert.** Die App weiss nicht, wie viel Training
  richtig ist. Kein „zu viel Kraft", kein „Ruhetag fehlt", kein Hinweis auf
  Überlastung — auch nicht, wenn sieben Kraft-Einheiten geplant sind.
- **Nichts mahnt.** Kein Badge, kein roter Punkt, keine Erinnerung an einen
  geplanten, nicht trainierten Tag. Ein Plan ist ein Vorhaben, kein Vertrag.
- **Jede Zahl nennt ihre Grundlage**, nie ein Anteil ohne Nenner.
- **Auf dem Hybrid-Tab rendert ein Block ohne Daten nicht** — der Bildschirm
  hört früher auf.
- **Keine Motivationssprache**, kein Emoji. Die App redet wie ein genauer
  Trainingspartner.

## Was es schon gibt

- **Board 18** (Trainingsangaben): die Bausteine `AtemAnswerOption`,
  `AtemAnswerChip` (48 dp, Häkchen-Ecke), `AtemAnswerTile`, `AtemAnswerRow`
  (gefaltete Zeile mit Statuspunkt), `AtemRevealGroup`, die Spurtöne und die
  Symbole für Kraft, Cardio, Tageszeiten.
- **Board 17** (Trainieren): der Startblock mit Kopf, einem Knopf und Fuss;
  „Training planen" steht dort schon als Kachel und führt heute nur zur
  Planliste.
- **Board 11** (Hybrid & Cardio): der Hybrid-Tab, die Karte „Heute und diese
  Woche", die Cardio-Arten.
- **Board 05/07** (Workouts, Daten & Eingaben): Plankarten, Planliste,
  Formulare, zweistufiges Löschen.
- **Board 13** (Ortszeile): wie ATEM eine Seite mit mehreren Themen gliedert.

## Zustände sind Pflicht

Je als eigenes Artboard, für die Planungsseite **und** das Hybrid-Widget:

- **leer** — nie geplant
- **halb gefüllt** — drei Tage belegt
- **voll** — Person 1, und Person 4 mit zwei Einträgen am Tag
- **Wechselwochen** — Woche A und B
- **heute mit Eintrag / heute ohne Eintrag / heute Ruhetag laut Plan**
- **ein Eintrag, dessen Plan gelöscht wurde**
- **lädt**, **Fehler beim Laden**, **Fehler beim Speichern**
- **200 % auf 320 dp**

## Bewegung

Grundlage ist Board 18b (Bewegungsgrammatik), das parallel entsteht: Glow ist
Quittung, die Lichtkante markiert einen Moment, nichts leuchtet an Offenem.
Hier interessant und diesem Board eigen: **ein Eintrag wandert von einem Tag
auf einen anderen** (mit und ohne Ziehen), **ein Eintrag entsteht** in einem
Tag, und **das Widget wechselt um Mitternacht** auf den nächsten Tag. Für jede
Bewegung: Auslöser, Eigenschaft, Dauer, Kurve, Ruhelage, reduziert.

## Was ich von dir brauche

Ein Spezifikations-Board im Format der Module 1–18: **Leitsatz**, Artboards je
Zustand, **Spezifikation** (Maße, Abstände, Flächen, Typo, Tap-Ziele),
**Motion**, **Stringtabelle** (`key | Deutsch | Englisch`, Deutsch primär,
Zählformen mit Einzahl, Platzhalter in `{n}`), **A11y-Notizen** (Element ·
Semantics-Label · Rolle · Zustand — besonders für das Verschieben ohne
Ziehen), **Wiederverwendung**, ein **Entscheidungsprotokoll** mit Gewähltem
und Verworfenem samt Begründung — darunter die sechs Fragen oben — und einen
**Vorschlag für die Felder von `planning/week`** (wie Sektion C in Board 18).

**Nicht Teil dieses Boards:** der Vorschlag (Board 20). Wenn die Woche etwas
davon voraussetzt, halte es fest, statt es zu entwerfen.

**Gestalte deine eigene Lösung.** Ich habe bewusst kein Layout, keine
Wochenform und keine Maße festgelegt. Was oben steht, ist das Problem und die
Grenzen — nicht der Entwurf.
