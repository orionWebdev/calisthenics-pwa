# Prompt für Claude Design — Board 18b: Die Bewegungsgrammatik

**Stand:** 23.09.2026 · Anlass: Die Effekte aus Board 18 (Zielbriefing) sehen
am Gerät so gut aus, dass sie in die ganze App sollen — aber mit Regeln, nicht
als Streuung. Kein neues Modul, sondern eine Grammatik für alle.
Kopiere ab der Trennlinie in Claude Design.

---

## Worum es geht

ATEM Hybrid ist eine private Android-App für hybrides Training (Kraft und
Ausdauer), Ästhetik „Dark Cyber-Athlete". Drei Tabs: **Kraft · Cardio ·
Hybrid**. Messlatte für Bewegung ist GSAP-Qualität: orchestriert statt
verstreut, und jede Bewegung sagt etwas.

Board 18 (das Zielbriefing) hat fünf Effekte eingeführt, die am Gerät
auffallend gut wirken. Sie sollen jetzt **in die ganze App** — in die
globalen Bausteine, damit sie überall dasselbe bedeuten. Dieses Board legt
fest, **welcher Effekt wo erscheint, wann er ausgelöst wird und wo er
ausdrücklich nicht hingehört.**

Der Grund, warum die Effekte in Board 18 wirken, steht in dessen eigenem
Entscheidungsprotokoll und soll hier die Grundlage sein:

> **Glow ist Quittung, nicht Dekor** (Entscheidung 24). Jeder Schein
> antwortet auf etwas — gewählt, erschienen, geschrieben, abgelehnt. Keiner
> bleibt stehen, keiner pulsiert, um Aufmerksamkeit zu holen.
> **Die Lichtkante ist keine Gradient-Karte** (Entscheidung 25): Sie markiert
> einen Moment („das ist neu"), keinen Rang, und ist nach 1,2 s weg.
> **Verworfen: rotierender Gradient-Rand um Offenes, schimmernde
> Fortschrittsleiste** (Entscheidung 26) — typische „KI-Glow"-Muster, die
> drängen.

Die Gefahr ist klar: Laufen Glow und Kanten auf jeder Karte, sind sie nach
einer Woche Tapete, und die eine Gradient-Karte je Bildschirm verliert ihre
Wirkung. **Die Aufgabe ist deshalb nicht „mehr Effekte", sondern eine
Grammatik, die sie selten genug hält, dass sie etwas bedeuten.**

## Die fünf Effekte aus Board 18 — so, wie sie gebaut sind

| # | Effekt | Auslöser | Eigenschaft | Dauer · Kurve | Ruhelage | Reduziert |
|---|---|---|---|---|---|---|
| 1 | **Auswahl-Bloom** | Antwort gewählt | Cyan-Ring 0 → 10 dp + Schein 28 dp, klingt aus | 620 ms · cubic(0.22,1,0.36,1) | kein Schein, nur Rand | aus |
| 1b | **Kern / Häkchen** | Antwort gewählt | Kern scale 0 → 1 mit Überschwinger; Häkchen an der Ecke poppt und zieht sich als Strich | 220 / 380 + 360 ms · easeOutBack / cubic(0.65,0,0.35,1) | gewählt | sofort sichtbar |
| 2 | **Lichtkante** | Block erscheint oder klappt auf | Bogen Cyan → `#AB6BF0` läuft einmal 360° um den Rand | 1200 ms · cubic(0.45,0,0.2,1) | Standardrand `#232334` | aus |
| 3 | **Speicher-Scan** | Antwort geschrieben (optimistisch) | Lichtpunkt, 34 % Breite, läuft über die Oberkante | 760 ms · cubic(0.22,1,0.36,1) | weg | aus |
| 4 | **Aurora + Titelglanz** | Seite öffnet (Glanz einmal); Aurora als einzige Dauerschleife | drei weiche Radialflächen treiben hinter dem Titel, unter der Glasleiste mitgeblurrt; Glanz wandert einmal durch den Titel | 16 s Loop / 1400 ms | Weiss | Aurora steht still, kein Glanz |
| 5 | **Ablehnungs-Flackern** | Server lehnt ab | Fehlerzeile flackert zweimal Magenta, Auswahl springt zurück | 320 ms · ease-out | Fehler steht bis zum nächsten Tipp | kein Flackern |

Dazu das Bestehende, das überall gilt: **gedrückt = scale 0,97 + Akzent-Glow,
200 ms**, und die **Eintrittskaskade** (14 dp, 320 ms, 55 ms Versatz,
gedeckelt ab Position 6, ausgelöst beim Kreuzen von 25 % der Viewporthöhe —
Board 13).

## Was es heute schon an Bewegung gibt — und was davon kollidiert

Diese Dauerschleifen stammen aus früheren Boards und Prototypen. Einige
stehen **gegen** die Regel „Glow ist Quittung". Entscheide je Schleife:
bleibt, fällt, oder wird zur Quittung umgebaut — mit Grund.

- **Puls-Glow am Haupt-CTA** (Magenta-Verlauf, „Session starten"), 2,2 s
  Dauerschleife. *Das ist die auffälligste Kollision.*
- **Live-Puls** (laufende Einheit), 1,8 s.
- **Ruhepuls des jüngsten Kurvenpunkts** (Board 14, Gewichtsverlauf), 2,2 s.
- **Sitzungspunkt** im Runner, 1,2 s.
- **Flackern des Markenpunkts**, 2,6 s.
- **Ladeskelett**: Puls (Modul 2) — Board 18 wollte auf seinem Bildschirm
  einen Schimmer; ich habe den gemeinsamen Puls behalten, weil ein Skelett
  überall dieselbe Form haben soll. Entscheide, ob der Schimmer global wird.

## Die Bausteine, in die es gehen soll

Alle global, alle mehrfach verwendet. Bitte je Baustein entscheiden, welcher
Effekt (wenn überhaupt) hineingehört:

- **Wahl:** `AtemChoiceChip` (Pille, Muskelgruppen und Filter), `AtemSegmented`
  (Einheiten/Auswertung, kg/lbs, Zeitfenster), `AtemScaleChoice` (Anstrengung
  1–10, Schwierigkeit 1–5), **Satz abhaken im Runner**, Plan wählen, Übung
  wählen, `AtemTabSwitch`.
- **Schreiben:** Gewicht eintragen, Einheit speichern/bearbeiten, Übung und
  Plan anlegen, Herzfrequenzzonen festlegen, Health-Import übernehmen oder
  paaren, Satz im Runner geloggt.
- **Erscheinen / Aufklappen:** `AtemDisclosure`, ⓘ-Erklärung
  (`AtemExplainHeader`), Blätter (`AtemSheet`), eine gerade gespeicherte
  Einheit, die im Verlauf auftaucht, ein neu freigeschalteter Auswertungsblock
  (Schwelle erreicht).
- **Ort:** Kopf der Unterseiten (Einstellungen, Gewichtsverlauf,
  Einheitendetail, Übungsdetail, Zonen). Die **Aurora trägt den Bereichston**:
  Kraft Amber `#FFB020`, Cardio `#4C8DFF`, Hybrid `#AB6BF0`, Regeneration
  Grün `#00FF87`. In Board 18 war sie Cyan/`#AB6BF0`/Violett.
- **Fehler:** jede Speicherfehlerzeile im Formular (Modul 7).

## Nicht verhandelbar

- Nur die Farbtokens aus `atem_theme.dart` / README §3. Keine erfundenen
  Zwischentöne, keine vierte Farbebene.
- **Cyan trägt Handlung**, global reserviert. **Der Bereichston trägt den
  Ort** und ist nie ein Versprechen auf eine Handlung. Violett `#7A2BDB` ist
  nur Fläche, nie Text. Magenta ist Marke und Eingriff.
- **Genau eine Karte mit Gradient-Rand je Bildschirm.** Die Lichtkante darf
  sie nicht verwässern.
- **Höchstens ein `BackdropFilter` pro scrollendem Screen.** Die Aurora wird
  vom Filter der Kopfleiste mitgeblurrt, sie bekommt keinen eigenen.
- Farbe ist nie der einzige Statusträger — ein Effekt ersetzt nie ein Wort,
  einen Glyph oder ein Icon. **Bei „Animationen reduzieren" muss jede Aussage
  ohne Bewegung ankommen**, und jede dekorative Dauerschleife steht still.
- Kein Material-Ripple. Gedrückt = scale 0,97 + Akzent-Glow, 200 ms.
- Muss bei **200 % Systemschrift auf 320 dp** funktionieren; kein Effekt darf
  Platz beanspruchen, den der Text braucht.
- **Nichts leuchtet an etwas Offenem, Fehlendem oder Unerledigtem.** Ein
  Schein an einer leeren Frage, einem fehlenden Wert oder einem nicht
  erreichten Ziel wäre eine Erinnerung — und die App mahnt nie.

## Fragen, die das Board beantworten muss

1. **Dichte.** Wie viele Quittungen dürfen gleichzeitig sichtbar laufen? Was
   passiert, wenn im Runner in 3 s fünf Sätze abgehakt werden — fünf Blooms,
   oder wird es ruhiger, je schneller jemand tippt?
2. **Der Runner.** Während einer Einheit schaut man zwischen zwei Sätzen auf
   das Telefon, verschwitzt, mit Puls 160. Was davon ist dort Hilfe, was
   Lärm? Gilt dort eine eigene, leisere Stufe?
3. **Lichtkante und Eintrittskaskade.** Beide reagieren aufs Erscheinen. Auf
   einer Seite, die alle Blöcke auf einmal baut (Kraft-Tab), liefe sonst an
   jedem Block eine Kante. Wann läuft sie — nur, wenn das Erscheinen die
   Folge einer Handlung ist?
4. **Die Aurora als Ort.** Auf welchen Bildschirmen steht sie, und wie
   unterscheidet sie sich von der Tab-Tönung, die es schon gibt? Darf sie auf
   einem Hauptbildschirm stehen, oder nur auf Unterseiten?
5. **Die Kollisionen oben.** Je Dauerschleife: bleibt, fällt, wird Quittung.
6. **Haptik.** Sollen Quittungen eine Vibration haben (Auswahl, Speichern,
   Ablehnung)? Wenn ja, welche Stufe — und welche nie?

## Was ich von dir brauche

Ein Spezifikations-Board im Format der Module 1–18:

- **Leitsatz** — ein Satz, an dem sich jede künftige Bewegung prüfen lässt.
- **Die Grammatik als Tabelle:** Effekt · Bedeutung · Auslöser · erlaubt in ·
  verboten in · Dichte-Regel · reduziert.
- **Je Baustein ein Artboard** vorher/nachher (mindestens: Chip, Segment,
  Skala, Satz abhaken, Gewicht speichern, Disclosure, Unterseitenkopf mit
  Aurora je Bereichston, Fehlerzeile). Bewegung live, wie in Board 18 F.
- **Zwei ganze Bildschirme** im neuen Zustand, damit die Dichte sichtbar
  wird: der Kraft-Tab („Trainieren") und der Runner mitten in einem Satz.
- **Motion-Tabelle** (Element · Auslöser · Eigenschaft · Dauer · Kurve ·
  Ruhelage · reduziert), mit den Kurven aus Board 18 als Token-Satz
  (Namen dafür vorschlagen — sie werden `AtemMotion`-Konstanten).
- **A11y-Notizen**, besonders: was bei „Animationen reduzieren" die Aussage
  trägt, und welche Quittung eine Ansage braucht.
- **Wiederverwendung** — welche bestehenden Bausteine sich ändern, welche neu
  sind. Die Board-18-Bausteine (`AtemEdgeSweep`, `AtemSaveScan`, Bloom,
  Häkchen-Ecke) sind gebaut und sollen die Grundlage sein.
- **Entscheidungsprotokoll** mit Gewähltem und Verworfenem samt Begründung —
  darunter die sechs Fragen oben und jede Kollision einzeln.
- **Flutter-Hinweise**, wo nötig: Leistung auf einem Mittelklasse-Gerät
  (Honor, Impeller), was ein `CustomPainter` je Block kostet, und was nur
  während des Laufs existieren darf.

**Gestalte deine eigene Lösung.** Die Tabelle oben ist der Bestand, nicht der
Entwurf. Wenn ein Effekt an einer Stelle nichts sagt, gehört er dort nicht
hin — auch wenn er schön ist.
