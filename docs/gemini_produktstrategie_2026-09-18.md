# Gemini-Produktstrategie vom 18.09.2026 — Bewertung und Übernahmeplan

**Quelle:** `ATEM Hybrid – Produktstrategie & UX/UI Spezifikation.pdf`, von Christian mit Gemini erstellt.
**Zweck dieses Dokuments:** Festhalten, was daraus übernommen wird, wie, und was schon steht. Jede
Zeile ist gegen den tatsächlichen Code geprüft — Gemini kannte den Bestand nicht im Detail, deshalb
stimmen einige Tech-Annahmen nicht mit diesem Projekt überein (siehe Abschnitt 5).

---

## 1 · Bereits umgesetzt — nichts zu tun

| Vorschlag aus dem PDF | Fundstelle im Code |
|---|---|
| Nenner-Pflicht bei jeder Zahl | `CLAUDE.md` „Umgang mit Zahlen", seit Projektbeginn Regel |
| Keine Ampelfarben, neutrale Deltas mit Glyphe | `CLAUDE.md`, dieselbe Regel — das PDF nennt das „Design-Regel 2" |
| Schwellenwert-Zustand statt leerer Diagramme | `AtemThresholdBlock` (`lib/core/widgets/atem_threshold_block.dart`), seit 16.09. Pflicht auf Auswertungsbildschirmen |
| PR-Chip entfällt ohne Bestwert | `ExerciseHistory.measuresWeight` (`lib/features/history/domain/exercise_history.dart:174`) — kein „PR —" |
| Haltezeit (Isometrie) auf Satz-Ebene | `LoggedSet.holdSeconds` (`training_session.dart:523`), im Runner erfassbar |
| Geschätztes 1RM nach Epley | `StrengthProgress.epley` (`strength_progress.dart:95`), **bereits mit Sperre über 10 Wdh.** — wir sperren ab 12, das PDF schlägt „>10" vor, praktisch dieselbe Grenze |
| Rest-Timer im Workout-Flow | `rest_bar.dart`, automatischer Start nach dem Abhaken eines Satzes, seit dem Umbau am 18.09. mit Regler statt reinem Tippen |
| Offline-First | Firestore mit `Settings.CACHE_SIZE_UNLIMITED` (`main.dart:30`) — **nicht** SQLite/Isar, siehe Abschnitt 5 |

---

## 2 · Übernehmen — mit Begründung und Umsetzung

### 2.1 Weighted Calisthenics: Zusatzgewicht zur Last addieren

**Das ist der einzige echte Fehler, den das PDF gefunden hat.** Geprüft in
`lib/features/history/domain/training_load.dart:110`:

```dart
final weight = usesBodyweight ? context.bodyWeightKg : (set.weight ?? 0);
```

Bei `usesBodyweight == true` wird **nur** das Körpergewicht gezählt, ein eingetragenes `set.weight`
(Zusatzweste, Dip-Gürtel) geht komplett verloren. Ein Weighted Pull-up mit 20 kg Zusatzlast zählt
also identisch zu einem ohne. Das PDF schlägt korrekt vor: `effectiveLoad = Körpergewicht + Zusatzlast`.

**Umsetzung (klein, keine Migration):**
- `training_load.dart`: `weight = usesBodyweight ? context.bodyWeightKg + (set.weight ?? 0) : (set.weight ?? 0)`.
- Gleiche Korrektur, falls sie an anderer Stelle dieselbe Fallunterscheidung wiederholt (grep nach
  `usesBodyweight` vor dem Ändern — Stand heute nur diese eine Stelle in `training_load.dart`).
- Test: Weighted Pull-up mit Körpergewicht 80 kg und Zusatzlast 20 kg muss dieselbe Last liefern wie
  ein Hantelsatz mit 100 kg bei gleichen Wiederholungen.
- Das Eingabefeld für Gewicht ist bei `usesBodyweight`-Übungen im Runner schon nicht gesperrt (Domäne
  unterscheidet nicht) — nur die Rechnung muss korrigiert werden, keine UI-Änderung nötig.
- **Aufwand:** klein, ein Agent, eine Session.

### 2.2 Hard Sets (RPE ≥ 7) als Muskelgruppen-Metrik

Sinnvolle Ergänzung zur Muskelbalance, **aber sie setzt eine Datenmodell-Änderung voraus**, die das
PDF nicht benennt: `rpe` ist heute ein Feld der **Einheit**, nicht des **Satzes**
(`training_session.dart:223`, `TrainingSession.rpe`). Eine Einheit hat eine RPE-Zahl für alle Sätze
zusammen. „14 Hard Sets für Brust diese Woche" verlangt aber eine RPE- oder RIR-Angabe **je Satz**,
sonst zählt entweder die ganze Einheit oder keiner ihrer Sätze.

**Umsetzung, in dieser Reihenfolge:**
1. `LoggedSet` um ein optionales Feld erweitern, z. B. `final int? rpe` (1–10) — additiv, keine
   bestehenden Leser brechen daran.
2. Runner-UI: RPE-Eingabe je Satz, freiwillig, ohne Vorbelegung (wie alle Selbstauskünfte in
   `wellness_fields.dart`).
3. Domäne `HardSets` (analog zu `FocusDistribution`): zählt Sätze mit `rpe >= 7` je Muskelgruppe über
   ein Fenster, mit Vergleich zur Vorperiode — **als Verschiebung in Sätzen, kein Sollwert** (CLAUDE.md).
4. Auswertungsblock nach dem `AtemThresholdBlock`-Muster, erscheint erst mit genug Sätzen mit RPE.
5. **Nicht** „Hard Sets ersetzt Tonnage" wie im PDF — Tonnage bleibt für Kraftsportler die richtige
   Grundlage, Hard Sets ist die zusätzliche Sicht für alle. Ersetzen wäre ein Rückschritt für reine
   Kraftsportler mit vollständigen Gewichtsangaben.
- **Aufwand:** mittel — ein neues Feld im Bestand (additiv), eine Domänenrechnung, ein Auswertungsblock,
  eine Runner-Eingabe. Guter Kandidat für einen eigenen Durchgang mit mehreren Agenten.

### 2.3 RIR statt/neben RPE, umschaltbar

Nachvollziehbar für Hypertrophie-Training, aber **kein Free-Lunch**: Der Bestand trägt heute RPE
(1–10 auf Einheitsebene). Ein Umschalter „intern als RIR speichern, UI umschaltbar" verlangt eine
Umrechnung (`RIR ≈ 10 − RPE`, grob) und eine Entscheidung, welche Skala die Wahrheit ist.

**Empfehlung:** zurückstellen, bis 2.2 (RPE je Satz) steht. Danach ist ein Umschalter in den
Einstellungen ein kleiner Aufsatz auf demselben Feld, keine zweite Datenquelle. Kein eigenes Ticket
jetzt.

### 2.4 Plate Calculator

Eigenständiges, kleines Feature ohne Datenmodell-Abhängigkeit. Rechnet aus einem Zielgewicht und der
Stangenmasse (Standard 20 kg) die Bestückung.

**Umsetzung:**
- Reine Domänenfunktion: `PlateCalculator.solve(targetKg, barKg, plates: [25, 20, 15, 10, 5, 2.5, 1.25])`
  → Liste `(plateKg, count)` je Seite, greedy von der schwersten Scheibe.
- Darstellung als Scheibenstapel (Farbe nach Standard-Kennfarben — **das wäre eine neue Farbebene**,
  gegen `CLAUDE.md` „keine vierte Farbebene". Lösung: Grössen statt Farben unterscheiden die Scheiben,
  Zahl auf jeder Scheibe als Beschriftung; kein Verstoss gegen die Nur-Tokens-Regel.
- Zugriff aus dem Eingabeblatt (`AtemStepPad`) heraus, als zusätzlicher Reiter oder Link neben dem
  Gewicht-Regler — nicht als eigener Screen, sonst App-Wechsel-artige Unterbrechung im Training.
- **Aufwand:** klein bis mittel, gut als Einzel-Agent nach 2.1 machbar.

### 2.5 Skill-Progression-Tree (Hebel-Ketten für Calisthenics)

Der bestandsseitig grösste Vorschlag. Heute hat `Exercise` nur `difficulty` (1–5, siehe
`exercise.dart:76`) als grobes Fortschrittssignal, **keine Verknüpfung** zwischen verwandten Übungen
(Tuck Planche → Advanced Tuck → Straddle → Full).

**Umsetzung, grob skizziert (kein sofortiger Bau):**
1. Datenmodell: `Exercise.progressionChain` (Liste von Übungs-IDs in Reihenfolge) oder ein separates
   `SkillTrack`-Dokument, das mehrere `Exercise`-IDs ordnet. Nur für kuratierte Übungen sinnvoll
   befüllbar — eigene Übungen hätten keine Kette, es sei denn der Nutzer verknüpft sie selbst.
2. Übergangsschwelle: „Ziel-Wdh/Haltezeit" je Stufe — das ist wieder ein Sollwert-Feld, das mit
   „kein Sollwert, kein Urteil" abgewogen werden muss. Vorschlag: die Schwelle ist eine **Selbstauskunft
   des Nutzers**, keine App-Vorgabe, damit sie nicht wie eine Trainingsempfehlung wirkt (CLAUDE.md,
   „keine Trainingsempfehlung, die wie eine Verordnung klingt").
3. UI: eine Kette als vertikale Stufenanzeige im Übungsverlauf, aktuelle Stufe hervorgehoben.
- **Aufwand:** grösser — verlangt Pflege der Ketten für die 84 kuratierten Übungen, ein eigenes
  Redaktionsprojekt, nicht nur Code. **Empfehlung: zurückstellen bis nach dem Onboarding-Vorhaben**
  (siehe Abschnitt 4), weil die Dateneingabe (welche Übung folgt auf welche) der eigentliche Aufwand ist.

### 2.6 Tempo / Time Under Tension (3-0-1-0)

Zusätzliches optionales Feld je Satz, additiv wie 2.2. **Aufwand:** klein, aber **niedriger Nutzen für
diesen einzelnen Nutzer** (Calisthenics-fokussiert, kein Bodybuilding-Tempo-Training erwähnt).
Empfehlung: nicht bauen, ausser der Bedarf wird konkret genannt.

---

## 3 · Verworfen — mit Begründung

| Vorschlag | Warum nicht |
|---|---|
| Tonnage = 0 bei BW „für Dashboard-Vergleiche ungeeignet" | Teilweise falsch: Nach 2.1 ist Tonnage bei Weighted Calisthenics **nicht** mehr 0. Bei reinem Körpergewicht ohne Zusatzlast bleibt Tonnage bewusst niedrig — das ist korrekt, nicht falsch, weil `TrainingLoad` dafür schon auf Dauer ausweicht (`training_load.dart:120`, „Ersatzrechnung nach Dauer"). Hard Sets (2.2) ergänzt, ersetzt aber nicht. |
| SQLite/Isar als lokale Datenbank | Das Projekt nutzt Firestore mit unbegrenztem lokalen Cache, bereits offline-first. Eine zweite lokale Datenbank wäre eine parallele Wahrheit — nicht bauen. |
| Google Play Billing / Paywall-Phase 3 | Verfrüht: siehe Notiz „ATEM ist privat" — die App hat aktuell keine Store-Veröffentlichung geplant, kein Monetarisierungs-Bedarf. Kann neu bewertet werden, falls sich das ändert. |
| ASO/Store-Listing, Reddit-Seeding, Micro-Influencer | Gegenstandslos ohne Store-Veröffentlichung, siehe oben. |
| Android Live Activity / System-Overlay für den Rest-Timer | **Deckt sich mit einem bereits gemerkten Zukunftsziel** (Lockscreen-Widget mit Pausentimer, siehe [[atem-geplante-features]]) — dort schon vermerkt, hier keine doppelte Aufgabe. |

---

## 4 · Abgleich mit den festgehaltenen Zukunftszielen

Aus dem Projektgedächtnis (`atem-geplante-features.md`, drei vom Nutzer angemeldete Vorhaben):

1. **Lockscreen-Widget mit Pausentimer** — deckt sich mit dem PDF-Vorschlag „Integrated Rest Timer &
   Live Tracking" (Abschnitt 4.4 des PDFs). Bestätigt als sinnvoll, technische Einschätzung unverändert:
   Android App Widget/Glance plus Vordergrunddienst, kein reines Flutter-Feature.
2. **Seitengetrennte Sätze** (z. B. Bizeps-Curl nur rechts/links) — **im PDF nicht erwähnt**, bleibt
   ein eigenständiges Vorhaben. Bietet sich an, mit 2.2 (`LoggedSet`-Erweiterung um `rpe`) in **einem**
   Durchgang zu erledigen, weil beides additive Felder am selben Modell sind — eine Migration statt zwei.
3. **Muskel- und Ablaufvisualisierung** — verwandt mit dem Skill-Progression-Tree (2.5), aber breiter
   (alle Muskelgruppen, nicht nur Calisthenics-Hebelketten). Getrennt zu behandeln: die Körperkarte ist
   ein reines Anzeige-Feature ohne neue Daten, der Skill-Tree braucht neue Verknüpfungsdaten.

**Empfehlung:** Wenn als Nächstes an Runner-Feldern gearbeitet wird, `rpe` (2.2) und die
Seiten-Kennzeichnung (Zukunftsziel 2) zusammen an `LoggedSet` anlegen — eine Erweiterung des Modells
statt zwei.

---

## 5 · Wo das PDF am tatsächlichen Stack vorbeigeht

Gemini kannte den Code nicht, nur die Beschreibung. Zwei Annahmen stimmen nicht:

- **Persistenz:** Das PDF nimmt „SQLite/Isar" an (Abschnitt 5, 8). Tatsächlich läuft die App auf
  Firestore mit lokalem Cache — bereits offline-first, ohne zweite Datenbank.
- **Store-Reife:** Die Roadmap in Abschnitt 8 unterstellt einen bevorstehenden Play-Store-Launch. Die
  App ist heute ein privates Projekt für einen einzelnen Nutzer (siehe Memory „ATEM ist privat"), Phase 1
  des PDFs („Free MVP Launch") ist damit kein aktuelles Ziel.

Das schmälert die UX/Metrik-Vorschläge in Abschnitt 2–4 nicht — die sind unabhängig vom Backend gültig
und wurden entsprechend übernommen oder begründet zurückgestellt.

---

## 6 · Empfohlene Reihenfolge

1. **2.1 Weighted-Calisthenics-Fix** — echter Fehler, klein, sofort machbar.
2. **2.2 + Zukunftsziel 2 zusammen** — `LoggedSet` um `rpe` und Seiten-Kennzeichnung in einem Zug
   erweitern, dann Hard-Sets-Auswertung und die Auswahl links/rechts im Runner.
3. **2.4 Plate Calculator** — kleiner, unabhängiger Gewinn für Kraftsportler.
4. **2.5 Skill-Tree** — zurückgestellt, eigenes Redaktionsprojekt für die Übungsketten nötig.
5. **2.3 RIR-Umschalter** — erst nach 2, kein eigener Aufwand mehr.
6. **2.6 Tempo/TUT** — nicht bauen ohne konkreten Bedarf.
