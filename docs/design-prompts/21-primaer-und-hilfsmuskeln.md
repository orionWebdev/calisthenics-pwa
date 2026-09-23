# Prompt für Claude Design — Modul 21: Hauptmuskel und Hilfsmuskeln

**Stand:** 23.09.2026 · Offener Auftrag. Nummer 21, weil 19 und 20 der
Wochenplanung gehören. Bewegung nach Board 18b (Bewegungsgrammatik).
Kopiere ab der Trennlinie in Claude Design.

---

## Worum es geht

ATEM Hybrid ist eine private Android-App für hybrides Training (Kraft und
Ausdauer), Ästhetik „Dark Cyber-Athlete". Drei Tabs: **Kraft · Cardio ·
Hybrid**. Die App schreibt mit und wertet aus — ohne Sollwert, ohne Urteil.

Eine Übung trainiert nicht alle ihre Muskeln gleich. **Bankdrücken** hat
**Brust** als Hauptmuskel, **Trizeps** und **Schulter** arbeiten mit. Die App
weiss das — und wirft es heute weg. Dieses Board entscheidet, wie
Hauptmuskel und Hilfsmuskeln **sichtbar, filterbar, eintragbar und zählbar**
werden. Später baut die Wochenplanung (Boards 19, 20) darauf auf: Wer einen
Plan zusammenstellt, will wissen, welche Übung welchen Muskel **trägt**.

## Was die Daten heute hergeben

- **84 kuratierte Übungen:** alle mit `primaryMuscles`, **62** zusätzlich mit
  `secondaryMuscles`. Beispiel Bankdrücken: primär `[chest]`, sekundär
  `[triceps, shoulders]`. Kurzhantel-Bankdrücken: `[chest]` / `[triceps]`.
  Schrägbank: `[chest]` / `[shoulders]`. 22 kuratierte haben keine
  Hilfsmuskeln eingetragen — ob das „keine" heisst oder „nicht erfasst",
  wissen wir nicht.
- **71 eigene Übungen:** nur eine **flache Liste** `muscleGroups`, ohne
  Unterscheidung — 57 gefüllt, 14 leer. Welcher Muskel dort der Hauptmuskel
  ist, weiss nur der Nutzer. **Die App rät nicht.**
- **Zwölf Muskelgruppen, sechs Regionen, neun Farben.** Brust, Rücken,
  Schulter, Core, Bizeps, Trizeps, Arme, Gesäss, Quadrizeps, Beinbeuger,
  Waden, Beine — eingefärbt nach Region (**keine zehnte Muskelfarbe**).
  Kuratierte Übungen nennen Einzelmuskeln (`biceps`), eigene oft Regionen
  (`arms`) — beides muss nebeneinander funktionieren.

## Was die App heute damit macht

- **Anzeige:** Primär und sekundär werden zu einer Liste verschmolzen
  (`displayMuscles`), in der Reihenfolge primär zuerst — aber ohne dass man es
  sieht. Die Farbe einer Übungszeile kommt vom ersten Muskel.
- **Filter** (Übungsliste, Board 05): „Brust" findet jede Übung, bei der Brust
  **irgendwo** vorkommt — auch den Dip, bei dem Brust nur mithilft.
- **Formular** (eigene Übung, Board 07): eine Mehrfachwahl ohne Rangfolge.
- **Auswertung** (Muskelbalance, harte Sätze je Muskel, Board 09): **Ein Satz
  Bankdrücken zählt voll für Brust, voll für Trizeps und voll für Schulter.**
  Wer viel drückt, sieht dadurch viel „Schulter" — mehr, als sie getragen hat.

## Die Fragen, die das Board beantworten muss

1. **Anzeige.** Wie sieht man in der Übungsliste und im Übungsdetail, was
   Hauptmuskel und was Hilfsmuskel ist — ohne dass Farbe der einzige Träger
   ist? Eine Zeile ist schmal; bei 200 % auf 320 dp noch schmaler.
2. **Filter.** Filtert „Brust" nach Hauptmuskel, nach allen, oder lässt es die
   Wahl? Wenn Wahl: wie, ohne einen zweiten Filterriegel? Und was findet
   „Arme" — Übungen mit Bizeps oder Trizeps als Hauptmuskel?
3. **Eigene Übungen eintragen.** Wie legt man im Formular Hauptmuskel und
   Hilfsmuskeln fest? Einer oder mehrere Hauptmuskeln (Kniebeuge: Quadrizeps
   **und** Gesäss)? Bleibt „Muskelgruppe" Pflicht, wie heute die Regeln
   verlangen, und welcher Teil davon?
4. **Der Bestand ohne Unterscheidung.** 57 eigene Übungen haben nur die flache
   Liste. Wie erscheinen sie — als „nicht unterschieden", und wie wird daraus
   eine Unterscheidung, ohne dass die App mahnt oder eine Liste „zu
   vervollständigen" anbietet? (Die App mahnt nie.) Und die 22 kuratierten
   ohne Hilfsmuskeln: „keine" oder „nicht erfasst"?
5. **Zählen.** Wie zählt ein Satz in der Muskelbalance und bei den harten
   Sätzen je Muskel: für den Hauptmuskel voll, für Hilfsmuskeln **voll,
   anteilig oder gar nicht**? Jede Antwort ist eine Behauptung darüber, was
   ein Muskel geleistet hat. **Kein Sollwert** darf daraus entstehen — die
   App weiss nicht, wie viel Schulter richtig ist. Wie steht die Zählweise
   sichtbar dabei („268 Sätze · Hilfsmuskeln halb")? Und was geschieht mit
   Auswertungen, deren Zahlen sich durch die neue Zählweise ändern — sieht
   der Nutzer, dass sich die Rechnung geändert hat, nicht sein Training?
6. **Der Plan.** Plankarten tragen künftig eine stehende Aurora in der Farbe
   ihrer **Hauptmuskelgruppe** (entschieden am 23.09.). Wie wird die aus den
   Übungen eines Plans bestimmt — nach Hauptmuskeln, gewichtet nach Sätzen?
   Was, wenn zwei Regionen gleichauf liegen, oder der Plan nur eigene Übungen
   ohne Unterscheidung hat?

## Nicht verhandelbar

- Nur die Farbtokens aus `atem_theme.dart` / README §3. **Keine zehnte
  Muskelfarbe**, keine erfundenen Zwischentöne, keine vierte Farbebene.
  **Farbe kodiert die Körperregion, Text den Muskel** (Board 05).
- **Cyan trägt Handlung.** Violett `#7A2BDB` ist nur Fläche, nie Text.
- `#94A3B8` ist die dunkelste erlaubte Textfarbe. Informationstragender Text
  ≥ 12 sp, Kontrast ≥ 4,5:1. **Drei Textstufen.**
- **Farbe ist nie der einzige Statusträger** — primär und sekundär brauchen
  Wort, Form oder Reihenfolge, nicht nur Helligkeit.
- Jedes Tap-Ziel ≥ 48 dp. Kein Material-Ripple.
- Muss bei **200 % Systemschrift auf 320 dp** ohne Überlauf funktionieren.
- **Jede Zahl nennt ihre Grundlage**, nie ein Anteil ohne Nenner. Wo die
  Daten dünn sind („12 von 71 eigenen Übungen unterschieden"), muss das
  sichtbar sein.
- **Kein Urteil, kein Sollverhältnis.** Keine Ampel, kein „zu wenig Rücken".
- **Schreiben** (Formular) ist reversibel und optimistisch; bei Ablehnung
  zurück ins Formular. `difficulty` bleibt 1–5 ohne Vorbelegung.

## Was es schon gibt

- **Board 05** (Workouts): Übungsliste, Filter-Chips nach Muskelgruppe,
  Übungsdetail. **Board 07** (Daten & Eingaben): Übungsformular.
  **Board 09** (Aussagekraft): Muskelbalance, harte Sätze je Muskel.
- **Board 18b** (Bewegungsgrammatik): Filter-Chips bekommen nur die
  Häkchen-Ecke (der gefilterte Inhalt ist ihre Quittung), Chips, die etwas
  festhalten (Formular), zusätzlich den Bloom.
- **Board 18** (Trainingsangaben): `AtemAnswerChip` und `AtemAnswerTile` mit
  Häkchen-Ecke — Kandidaten für die Wahl im Formular.

## Zustände sind Pflicht

Übungsliste, Übungsdetail, Formular und die betroffenen Auswertungsblöcke je
mit: **kuratiert mit Hilfsmuskeln · kuratiert ohne · eigene unterschieden ·
eigene nicht unterschieden · ohne jeden Muskel**, dazu **lädt**, **Fehler**
und **200 % auf 320 dp**.

## Was ich von dir brauche

Ein Spezifikations-Board im Format der Module 1–18: **Leitsatz**, Artboards je
Zustand, **Spezifikation**, **Motion** (nur, was diesem Board eigen ist),
**Stringtabelle** (`key | Deutsch | Englisch`), **A11y-Notizen** (wie wird
„Brust, Hauptmuskel; Trizeps und Schulter helfen mit" vorgelesen?),
**Wiederverwendung**, ein **Entscheidungsprotokoll** mit den sechs Fragen oben
und einen **Vorschlag fürs Datenmodell** der eigenen Übungen
(`primaryMuscles` / `secondaryMuscles` wie bei den kuratierten?), abzugleichen
mit `docs/contracts/04-firestore-schema.md`.

**Gestalte deine eigene Lösung.** Was oben steht, ist der Bestand und die
Grenzen — nicht der Entwurf.
