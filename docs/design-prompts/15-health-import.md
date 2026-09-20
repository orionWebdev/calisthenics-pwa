# Design-Gespräch 15 — Trainings aus Health Connect übernehmen

**Stand:** 20.09.2026 · Offener Auftrag, bewusst ohne Lösungsvorgabe
Kopiere ab der Trennlinie in Claude Design.

Vorher lesen: `docs/gemini_produktstrategie_2026-09-18.md`, Abschnitt 8.4 —
dort stehen die vier Fragen, die **vor** dem Board zu klären sind (Datenmodell,
Paar-Regel, Vorrang bei Widerspruch, Verhalten bei „nein"). Der Prompt stellt
sie erneut; die Antworten gehören ins Entscheidungsprotokoll.

---

## Kontext

ATEM Hybrid — Android-App (Flutter) für hybrides Training, ein Nutzer, ein
Gerät im Blick: Honor VKJ-NX9, 361 dp breit, Systemschrift 1,15. Ästhetik:
Dark Cyber-Athlete. Farbsystem, Typenskala und die Bausteine aus den Modulen
1 bis 14 sind gesetzt und Grundlage, nicht Gegenstand dieses Gesprächs.

Die Bottom-Bar hat drei Plätze: **Kraft · Cardio · Hybrid**. Dieses Gespräch
berührt alle drei, hat aber keinen eigenen Platz und bekommt auch keinen.

Seit Modul 14 liest die App Körpergewicht aus Health Connect: Ein Punkt der
Gewichtskurve ist gefüllt, wenn ihn jemand getippt hat, und hohl, wenn er
gemessen wurde. Dieselbe Unterscheidung — **getippt gegen gemessen** — ist hier
das Thema, aber über eine ganze Trainingseinheit statt über eine Zahl.

## Worum es geht

Auf dem Telefon liegt eine zweite Quelle für dasselbe Training.

Wer eine Uhr trägt (Garmin, Fitbit, Withings, Samsung — sie alle schreiben nach
Health Connect), hat nach einer Einheit dort einen Datensatz: Beginn, Dauer,
Art, Durchschnittspuls, Maximalpuls, Kalorien. Die App weiss davon nichts. Und
umgekehrt: Wer im ATEM-Runner Sätze mitschreibt, erzeugt eine zweite Einheit
über **dasselbe Training**.

Daraus folgen drei Gestaltungsaufgaben, und sie hängen zusammen:

1. **Ein hereinkommendes Training muss geprüft werden können**, bevor es im
   Verlauf steht. Die Uhr weiss, wie lange und wie schnell der Puls war. Sie
   weiss nicht, wie schwer es sich angefühlt hat — und ohne Anstrengung rechnet
   die Trainingslast mit einem Ersatzwert, den niemand gewählt hat.
2. **Zwei Datensätze über eine Einheit dürfen nicht zwei Einheiten werden.**
   Die App muss das Paar erkennen und zusammenführen: Sätze und Anstrengung aus
   der App, Puls und Kalorien aus der Uhr.
3. **Beides muss man sehen können, ohne es zu suchen.** Ein stiller Abgleich,
   der Einheiten verändert, wäre der schwerste Vertrauensbruch, den diese App
   begehen kann.

## Was zu gestalten ist

### 1. Der Prüfbildschirm

Eine Einheit ist aus Health Connect hereingekommen. Was sieht man, was fragt
die App, was passiert dann?

Sicher ist: Die App braucht **Anstrengung** (RPE 1–10, in den Einstellungen auf
RIR umschaltbar) und das **Empfinden nach dem Training**. Beides kennt sie
bereits aus dem Runner und aus dem Cardio-Formular — prüfe die Bausteine, statt
etwas Neues zu erfinden.

Offene Fragen, die der Entwurf beantworten muss:

- **Wann geht er auf?** Beim Öffnen der App, als Zeile im Verlauf, als Meldung?
  Ein Blatt, das beim Start von selbst aufgeht, ist ein Überfall; eine Zeile,
  die niemand sieht, ist ein Datenfriedhof. Entscheide, mit Begründung.
- **Was, wenn drei Einheiten warten?** Nacheinander, als Liste, als Stapel?
- **Was heisst „nein"?** Verwerfen, aufheben, beim nächsten Mal wieder fragen —
  und woran erkennt man beim nächsten Lesen, dass diese Einheit schon einmal
  abgelehnt wurde?
- **Was, wenn jemand nichts angibt?** Die App darf keine Angabe erfinden. Eine
  Einheit ohne Anstrengung ist erlaubt (im Runner ist sie es seit dem
  20.09.2026 auch) — dann muss der Verlauf das aber sichtbar tragen.
- **Welche Werte sind überhaupt zu zeigen?** Alles, was die Uhr liefert, wäre
  eine Tabelle. Was davon trägt eine Entscheidung?

### 2. Der Abgleich zweier Einheiten

Die App hat eine Krafteinheit von 18:02 bis 18:54 mit 24 Sätzen. Die Uhr hat
eine Einheit von 18:00 bis 18:58 mit Ø 118 und max. 164.

Wie sieht es aus, wenn die App beide für dasselbe Training hält? Wie fragt sie
nach, wie zeigt sie das Ergebnis, und wie kommt man aus einer falschen
Zuordnung wieder heraus?

Bedenke: Das Zusammenführen ist die **eingreifendste** Operation, die diese App
kennt — sie verändert eine Einheit, die schon im Verlauf steht, mit Daten aus
einer fremden Quelle. Modul 7 hat dafür die Antwort etabliert: **rechnen, nicht
warnen.** Nenne die Folge mit Zahlen, bevor jemand zustimmt.

Offene Fragen:

- **Woran erkennt man das Paar?** Vorschlag zur Prüfung, nicht zur Übernahme:
  mehr als die Hälfte der kürzeren Dauer überlappt. Verwirf ihn, wenn du einen
  besseren Schnitt findest — aber schreib den Grund auf.
- **Was gewinnt bei Widerspruch?** Die Dauer steht in beiden Quellen und ist in
  beiden verschieden. Wer hat recht, und sieht man den anderen Wert noch?
- **Was, wenn die Zuordnung falsch war?** Ein Weg zurück ist Pflicht. Ist er
  eine Rücknahme oder ein zweiter Schritt?
- **Was, wenn eine Uhr-Einheit zu keiner App-Einheit passt?** Dann ist sie eine
  eigene Einheit und geht durch den Prüfbildschirm aus Aufgabe 1.

### 3. Die Herkunft im Bestand

Eine Einheit aus der Uhr und eine selbst geführte sind nicht dasselbe. Wo und
wie ist das sichtbar — in der Verlaufsliste, im Einheitendetail, in der
Auswertung?

Modul 14 hat dafür ein Idiom: **dieselbe Form, gefüllt gegen hohl** — kein
zweites Farbwort, kein Abzeichen. Prüfe, ob es sich auf eine ganze Einheit
übertragen lässt, und sag ausdrücklich, wenn nicht.

Bedenke auch den Fall „beides": eine zusammengeführte Einheit ist getippt
**und** gemessen. Zwei Zustände reichen dafür nicht.

### 4. Der Zugang zu Health Connect

Berechtigungen fragt Google je Datentyp einzeln ab, und sie können jederzeit
entzogen werden. Daraus folgen Zustände, die gestaltet werden müssen:

- Health Connect ist auf dem Gerät gar nicht vorhanden
- vorhanden, aber nichts freigegeben
- Gewicht freigegeben, Einheiten nicht
- alles freigegeben, aber nichts gelesen (leerer Zeitraum)
- Berechtigung nachträglich entzogen, während Daten schon übernommen wurden

Der letzte ist der interessante: Übernommene Einheiten bleiben. Was sagt die
App darüber, ohne zu drohen?

## Zustände sind Pflicht

Jeder Bildschirm und jeder Block braucht **default, loading, empty,
zu-wenig-Daten und error** als eigenes Artboard. Kein Zustand ist „kommt
später".

## Bewegung

Bewegung ist bei ATEM kein Beiwerk. Messlatte ist GSAP-Qualität: orchestriert
statt verstreut, und jede Bewegung sagt etwas.

Interessant hier: der Moment, in dem zwei Einheiten zu einer werden — zwei
Dinge, die eins werden, ist eine der wenigen Bewegungen, die eine Aussage
tragen kann statt sie nur zu begleiten. Für jede Bewegung: Auslöser,
Eigenschaft, Dauer, Kurve, Ruhelage — und was davon bleibt, wenn im System
„Animationen reduzieren" gesetzt ist.

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
- **Die Bottom-Bar bekommt keinen vierten Platz.** Nichts hieran rechtfertigt
  einen eigenen Bereich.
- **Kein Urteil.** Ein Puls von 164 ist keine Note. Die App kennt keine
  Sollzone und keine Bewertung einer Einheit.
- Jede Zahl nennt ihre Grundlage mit Nenner.
- Irreversibles in zwei Stufen: Stufe 1 informiert und zählt die Folgen,
  Stufe 2 entscheidet. Genau zwei Wege in Stufe 2, kein dritter.
- Jede Meldung steht **6 Sekunden**, mit oder ohne Rückgängig.
- Erklärungen sind versteckt (`AtemExplainHeader`); höchstens **eine**
  sichtbare Hinweiszeile ausser der Grundlage.
- Prüfe die Bausteine aus den Modulen 2, 6, 7, 9, 11 und 14, bevor du etwas
  Neues erfindest — besonders Blatt, Dialog-Anatomie, Folgen-Panel,
  Einheitenzeile, Intensitätsblock und das Herkunfts-Idiom. Was wirklich neu
  ist, benenne ausdrücklich als neu.

## Liefergegenstände

1. **Artboards** — der Prüfbildschirm in jedem Zustand; der Abgleich von der
   Vermutung bis zum Ergebnis; der Weg zurück aus einer falschen Zuordnung; die
   Herkunft in Liste und Detail; die fünf Berechtigungszustände; dazu alles bei
   200 % auf 320 dp
2. **Spezifikationstabelle** — je Element: Höhe, Innenpolster, Fläche,
   Typ-Rolle, Tap-Ziel
3. **Bewegungstabelle** — je Übergang: Auslöser, Eigenschaft, Dauer, Kurve,
   Ruhelage, Verhalten bei reduzierter Bewegung
4. **Stringtabelle** — `key | Deutsch | Englisch`, Zählformen mit Einzahlform,
   Platzhalter in geschweiften Klammern
5. **A11y-Notizen** — wie eine importierte Einheit vorgelesen wird, wie ein
   Paar klingt, was stumm bleibt, wie der Abgleich angesagt wird
6. **Wiederverwendungsliste** — was aus bestehenden Modulen kommt, was neu ist
7. **Entscheidungsprotokoll** — jede verworfene Idee mit dem Grund gegen sie,
   ausdrücklich einschliesslich: Paar-Regel, Vorrang bei Widerspruch, Verhalten
   bei „nein"
