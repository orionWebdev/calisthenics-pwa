# ATEM Hybrid — Auswertung evaluieren

Du bist Produktdesigner und Sportwissenschaftler. Bewerte die Auswertungs-
funktionen einer Trainings-App und schlage vor, was dort stattdessen oder
zusätzlich stehen sollte. Antworte auf Deutsch.

---

## 1 · Was die App ist

**ATEM Hybrid**, Android, privat, ein einzelner Nutzer. Hybrides Training:
Kraft und Ausdauer nebeneinander, dazu Regeneration. Die App ersetzt eine
gewachsene Web-App, deren Datenbestand vollständig übernommen wurde.

Vier Bereiche in der unteren Leiste: **Hybrid · Kraft · Cardio ·
Regeneration**.

---

## 2 · Der tatsächliche Datenbestand

Keine Annahmen — das sind die realen Zahlen des Bestands.

**136 Einheiten** über 245 Tage, davon an 87 Tagen trainiert.

| Art | Zahl | Anmerkung |
|---|---|---|
| Kraft | 63 | davon **16 ohne jede Übung/Sätze** — nur Dauer erfasst |
| Ausdauer | 51 | 37 Laufen · 5 Rad · 4 Wandern · 5 sonstiges |
| Regeneration | 12 | **11 davon ohne jede Angabe** ausser Datum und Dauer |
| Körpergewicht | 10 | |

**Was bei Ausdauer erfasst ist:**

| Feld | Abdeckung |
|---|---|
| Distanz | 44 / 51 |
| RPE (subjektive Anstrengung 1–10) | 32 / 51 |
| Ø Puls | **4 / 51** |
| Maximalpuls | ähnlich niedrig |

**Übungsbestand:** 154 Übungen, 84 kuratiert (mit Anleitung, Cues, Fehlern,
Muskelgruppen, Stufe 1–5), 70 selbst angelegt. Von den kuratierten sind die
meisten nie ausgeführt worden.

**Felder je Einheit** (`null` heisst: nicht erfasst)

* Alle: `date`, `duration`, `notes`, `rpe`, `preWorkoutEnergy`,
  `postWorkoutFeeling`
* Kraft: `exercises[]` mit `sets[]` (`reps`, `weight`, `holdSeconds`),
  `planId`, `planName`, `bodyweight`
* Ausdauer: `activity` (Laufen/Rad/Indoor-Rad/Schwimmen/Wandern/Gehen/
  Rudern/sonstiges), `distanceKm`, `avgHr`, `maxHr`
* Regeneration: `recoveryKind` (Yoga/Sauna/Dehnen/Mobility)

**Was es nicht gibt und nicht geben wird:** GPS und Streckenverlauf,
Herzfrequenz-Zeitreihen, Schlafdaten, HRV, Ruhepuls, Wetter, Ernährung,
Körpermaße ausser dem Gewicht.

---

## 3 · Was heute gerechnet wird

Alles davon existiert und ist getestet.

**Last** — `TrainingLoad`: eine Zahl je Einheit, portiert aus der Vorgänger-App
(Kraft aus Volumen und Sätzen, Ausdauer aus Dauer, Distanz und RPE).

**Bereitschaft** — `Readiness`: akute Last (7 Tage) gegen chronische Last
(28 Tage) als exponentielle Mittel → ACWR, daraus Zone und ein Wert 0–100.
Erscheint erst ab 14 Tagen Historie und genug Einheiten, sonst gar nicht.

**Form** — `FormResult`, ein Wert 0–100 aus fünf Bestandteilen:

| Bestandteil | Punkte | Grundlage |
|---|---|---|
| Konstanz | 0–35 | Trainingstage der letzten 28 Tage, voll ab 16 |
| Lastentwicklung | 0–30 | letzte 14 Tage gegen die 14 davor |
| Aktualität | 0–15 | Tage seit der letzten Aktivität |
| Fitness gegen Höchststand | 0–15 | 33-Tage-Mittel gegen eigenen Peak |
| Tageszuschlag | 0–8 | Einheit heute |
| Abzug Untätigkeit | negativ | beschleunigt steigend |

**Weitere fertige Rechnungen**

* `FormSeries` — Formkurve über Monate, durchgezogen mit Training,
  gestrichelt ohne, plus Einheiten-je-Woche als Strichleiste
* `HistoryTimeline` — Monate, Lücken ab 7 Tagen, Mehrfachtage
* `MuscleBalance` — Anteil, Sätze, Volumen und „zuletzt vor n Tagen" je
  Muskelgruppe, plus die längsten Abstände
* `SessionComparison` — eine Einheit gegen eine frühere, in drei Stufen:
  gleicher Plan → gleiche Übungen → gleiche Art (dann Median). Vier
  Kennzahlen mit Vorher-Wert und Delta
* `SessionPercentile` — Rang einer Einheit im eigenen Bestand, je Aktivität
* `ExerciseHistory` — je Übung: Bestwert, Ausführungen, Frequenz, Volumen,
  Kurve ab 5 Ausführungen
* `CardioIntensity` — dreistufige Kaskade: Puls, sonst RPE, sonst Tempo
  gegen den eigenen Median. Die führende Stufe steht sichtbar dabei
* `DistanceDistribution` — fünf feste Distanzklassen
* `PaceSeries` — Tempoentwicklung je Aktivität, Kurve ab 8 Einheiten
* `WeekRatio` — Anteil Kraft zu Ausdauer, gerechnet über **Trainingsminuten**
* `WeeklyDistance` — 8-Wochen-Streifen, Verschiebung zum 4-Wochen-Schnitt
* `DataSufficiency` — Schwellen, ab wann eine Auswertung überhaupt etwas sagt

---

## 4 · Was heute in der Oberfläche steht

### Hybrid-Tab
1. **Bereitschaftskarte** — Ring 0–100 in Zonenfarbe, Zone als Wort, Art der
   letzten Einheit („Gestern Regeneration")
2. **Verhältnisblock** — Kraft-/Ausdaueranteil dieser Woche über
   Trainingsminuten, Verschiebung in Prozentpunkten zum 4-Wochen-Mittel,
   darunter je Spur die Fachgrösse (Tonnage und Sätze · Kilometer)
3. **Regenerationszeile** — letzte Regeneration, oder Lücke, oder nie erfasst
4. **Formwert** — Kurve über vier Wochen, Wert mit Trend
5. Knopf „Auswertung öffnen"

### Auswertung (der Bildschirm, um den es geht)
1. **Formkurve** über sieben Monate, mit Strichleiste Einheiten/Woche
2. **„Form heute" x/100** und die fünf Bestandteile, jeder mit Balken und
   einer Begründungszeile („Aktualität 0/15 — letzte Einheit vor 50 Tagen")
3. Ein Erklärungsabsatz, wie sich der Wert zusammensetzt
4. Dünner Zustand: „Einheiten 3/8 · Historie 9/21 Tage" plus „Was es schon
   gibt" (Einheiten, Gesamtlast, längste Kette)

**Das ist der gesamte Auswertungsbildschirm.**

### Kraft-Tab
* Aussagekarte: „50 Tage ohne Training" oder „7 Einheiten in 14 Tagen",
  darunter der Formwert mit Balken
* Monatsstreifen: Einheiten je Monat, Median-Abstand, längste Pause
* Letzte Einheiten, dahinter die volle Liste mit Monatsgruppen, Lücken und
  Last-Balken je Zeile
* Einheitendetail: drei Kennzahlen **oder** der Vergleich zu einer früheren
  Einheit, ACWR-Skala des Tages, Übungsliste mit Schema, „Beitrag zur Form"
  bei Einheiten ohne Sätze
* Muskelbalance (im Workouts-Bereich): Anteil, Sätze, „zuletzt vor" je
  Muskel, plus die drei längsten Abstände
* Übungsdetail: Bestwert, Ausführungen, Frequenz, Volumen, Kurve ab 5

### Cardio-Tab
* Wochenkachel: Kilometer dieser Woche, Verschiebung, 8-Wochen-Streifen
* Auswertung: Wochenstreifen, Distanzverteilung, Tempokurve je Aktivität,
  Perzentil, Intensitätskaskade
* Einheitendetail: Distanz, Last, Tempo, Perzentil, Intensität

### Regenerations-Tab
* Statuskarte: letzte Regeneration oder Lücke, Knopf zum Erfassen
* Zählung je Art (Yoga 4 · Sauna 3 …)
* Liste aller erfassten Einheiten

**Mehr nicht. Hier gibt es keine Auswertung.**

---

## 5 · Die Regeln, gegen die jeder Vorschlag geprüft wird

Diese Regeln sind gesetzt. Ein Vorschlag, der eine bricht, wird verworfen —
es sei denn, du begründest ausdrücklich, warum die Regel hier falsch ist.

1. **Keine gemeinsame Lastwährung.** Kein Hybrid-Score, keine Summe aus
   Tonnage und Kilometern. Das Verhältnis rechnet über Trainingsminuten.
2. **Jede Zahl nennt ihre Grundlage.** Nie einen Anteil ohne Nenner
   („268 Sätze · 14 von 18 Krafteinheiten").
3. **Kein Sollwert, kein Urteil.** Die App weiss nicht, wie viel Rücken
   richtig ist. „Mehr" ist nicht „besser". Deltas sind Tatsachen mit
   Richtungsglyph, keine Ampelfarben.
4. **Puls ist nie Voraussetzung** — 4 von 51 Einheiten haben ihn.
5. **Regeneration trägt keine Last.** Sie bricht die Untätigkeitsstrafe,
   erhöht aber keinen Wert. 25 Minuten Dehnen dürfen keine harte Woche
   kompensieren.
6. **Ein Block ohne Daten rendert nicht.** Kein Platzhalter, kein „Leg los!".
   Der Bildschirm hört einfach früher auf.
7. **Wo die Daten dünn sind, muss das sichtbar sein** — mit Nenner, nicht
   mit einer glatt aussehenden Zahl.
8. **Keine Interpolation über Tage ohne Ereignis.**
9. **Keine Gesundheits- oder Medizinaussagen.** Kein Verletzungsrisiko, keine
   Trainingsempfehlung, die wie eine Verordnung klingt.
10. Barrierefreiheit: Farbe nie als einziger Statusträger, Text ≥ 12 sp,
    Tap-Ziele ≥ 48 dp, lesbar bei 200 % Systemschrift auf 320 dp Breite.

---

## 6 · Was ich von dir will

Der Betreiber sagt: *„Ich habe nicht den Eindruck, dass wir etwas mit
Substanz bauen, was Leute daran hält, diese App zu nutzen."* Der
Auswertungsbildschirm gefällt ihm nicht, und im Regenerations-Tab steht
nichts mit Aussagekraft.

Beantworte für **jeden der vier Bereiche** — Auswertung (Form), Kraft,
Cardio, Regeneration — diese vier Fragen:

**A. Was ist heute schwach?**
Konkret, nicht allgemein. Welcher Block trägt nichts, welche Zahl beantwortet
keine Frage, die jemand tatsächlich hat?

**B. Was sollte stattdessen dort stehen?**
Nenne je Bereich zwei bis vier konkrete Auswertungen. Für jede:
* Welche Frage beantwortet sie? (in den Worten eines Trainierenden)
* Aus welchen der oben genannten Felder wird sie gerechnet?
* Ab wie viel Daten trägt sie? Was steht darunter?
* Wie sieht sie aus — Zahl, Balken, Kurve, Verteilung, Zeile?
* Warum hält sie jemanden an der App?

**C. Was fehlt im Datenmodell?**
Welche **eine** zusätzliche Angabe je Bereich hätte den grössten Ertrag —
gemessen daran, dass sie jemand tatsächlich einträgt? Bedenke: 11 von 12
Regenerationseinheiten haben heute nur Datum und Dauer.

**D. Was würdest du streichen?**
Was steht heute da, das man weglassen sollte?

**Zum Schluss:** Nenne die **drei** Auswertungen, die du zuerst bauen würdest,
mit Begründung, warum genau diese drei den Unterschied machen.

Sei konkret und streitbar. Allgemeinplätze über „Gamification" oder
„Motivation durch Streaks" helfen nicht — begründe an diesem Datenbestand.
