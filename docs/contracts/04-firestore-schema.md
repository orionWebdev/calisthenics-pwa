# Vertrag 4 — Firestore-Schema

**Erhoben:** 26.08.2026 am vollständigen Produktivbestand von `calisthenics-pro-57d6d`
(447 Dokumente, Sicherung siehe unten).
**Zweck:** Festhalten, wie die Daten **tatsächlich** aussehen — nicht, wie sie aussehen
sollten. Jede Abweichung zwischen diesem Dokument und einer Dart-Klasse ist ein Absturz auf
echten Nutzerdaten.

---

## Die Sicherung

`gcloud firestore export` steht nicht zur Verfügung: Er schreibt in einen
Cloud-Storage-Bucket, und das Projekt liegt auf **Spark** (`billingEnabled: false`, keine
Buckets vorhanden). Ersatz ist `tool/firestore_dump.py` — liest über die REST-Schnittstelle,
schreibt nichts, braucht nur ein Token aus `gcloud auth print-access-token`.

```
gcloud auth print-access-token | python3 tool/firestore_dump.py ~/atem-firestore-sicherung-<datum>
```

Stichtagssicherung vom 26.08.2026: `~/atem-firestore-sicherung-2026-08-26/` — 447 Dokumente.
**Sie gehört nicht ins Repository.** Sie enthält personenbezogene Trainingsdaten.

---

## Bestand

| Collection | Dokumente | Rolle |
|---|---|---|
| `sessions` | 136 | Absolvierte Einheiten — die Collection, die zählt |
| `exercises_curated` | 84 | Kuratierter Übungskatalog, global |
| `schedule` | 77 | Geplante Einheiten |
| `exercises` | 70 | Nutzereigene Übungen |
| `progress` | 66 | Sätze je Übung und Datum |
| `plans` | 10 | Trainingspläne |
| `userProfiles` | 2 | Profil und Einstellungen |
| `allowedUsers` | 2 | Zugangsliste für die geschlossene Beta |

`workouts` und `sessionTemplates` werden in `js/core/firebase.js` deklariert, enthalten aber
**kein einziges Dokument**. Sie werden nicht portiert.

Alle nutzereigenen Dokumente tragen die Zugehörigkeit als Feld `userId`, nicht als
Unterpfad. Es gibt **keine Untersammlungen** — auf 447 Dokumente geprüft.

---

## `sessions` — heterogen, und das ist die eigentliche Nachricht

Nur **vier Felder existieren in allen 136 Dokumenten**:

| Feld | Typ | Vorkommen |
|---|---|---|
| `userId` | string | 136/136 |
| `createdAt` | timestamp | 136/136 |
| `date` | timestamp | 136/136 |
| `type` | string | 136/136 |

`type` ist der Diskriminator: `strength` (63) · `cardio` (51) · `recovery` (12) ·
`bodyweight` (10).

Je nach Art trägt das Dokument völlig verschiedene Felder:

**Kraft und Körpergewicht** — `exercises: array`, Einträge `{exerciseId: string, sets: array}`
(68 Dokumente), dazu `planId`, `planName`, `rpe`, `preWorkoutEnergy`, `postWorkoutFeeling`.

**Cardio** — `activityType` (`run` 37 · `bike` 5 · `hike` 4 · `walk` 2 · `stretching` 5 ·
`yoga` 1 · `sauna` 1 · `other` 5), dazu `distanceKm`, `pace`, `avgHr`, `maxHr`, `durationSec`.

In Dart gehört das in eine **versiegelte Klassenhierarchie** mit `type` als Diskriminator,
nicht in eine Klasse mit zwei Dutzend optionalen Feldern. Eine solche Klasse könnte nicht
ausdrücken, dass `distanceKm` bei `strength` bedeutungslos ist.

### Typkollisionen — hier stürzt naiver Code ab

Dasselbe Feld trägt über die Dokumente hinweg **verschiedene Firestore-Typen**:

| Feld | Verteilung |
|---|---|
| `duration` | integer in 111, **double in 25** |
| `distanceKm` | double in 36, **integer in 8**, null in 7 |
| `pace` | double in 40, **integer in 4**, null in 7 |
| `notes` | string in 61, **null in 59** |
| `name` | string in 29, null in 10 |
| `planId` | string in 52, null in 4 |
| `avgHr` | integer in 3, null in 1 |
| `maxHr` | integer in 2, null in 2 |

Daraus folgen zwei Regeln, die nicht verhandelbar sind:

**R1 — Niemals `as int`.** Firestore liefert `num`. `doc['duration'] as int` wirft auf
25 der 136 Dokumente. Immer `(v as num?)?.toDouble()` beziehungsweise `.round()`.

**R2 — `null` und „Feld fehlt" sind derselbe Fall.** Beide kommen vor, teils im selben Feld
(`notes`: 61 string, 59 explizit null, 16 gar nicht vorhanden). Der Deserialisierer darf sie
nicht unterscheiden.

---

## `progress` — sauber und gleichförmig

Alle 66 Dokumente tragen dieselben fünf Felder: `userId`, `createdAt`, `date`,
`exerciseId`, `sets: array` mit Einträgen `{reps: integer, weight: integer}`.

### Offene Frage

Sätze stehen an **zwei Stellen**: in `sessions.exercises[].sets` (68 Dokumente) und in
`progress.sets` (66 Dokumente). Ob das eine Spiegelung, eine Teilmenge oder zwei getrennte
Wahrheiten sind, ist noch nicht geklärt. **Vor dem ersten Schreibpfad muss feststehen, welche
Quelle führend ist** — sonst schreibt die App in die eine und die PWA liest aus der anderen.

---

## `userProfiles`

20 Felder, darunter für uns unmittelbar relevant: `language`, `unitSystem`, `displayName`,
`photoURL`, `defaultRestTimer`, `trainingLevel`, `trainingStyle`, `onboardingCompleted`,
`bodyWeight`, `bodyHeight`.

`language` und `unitSystem` sind die Brücke zur i18n aus Vertrag 2: Die App darf die Sprache
nicht allein aus dem Systemgebietsschema ableiten, wenn hier eine Wahl hinterlegt ist.

## `allowedUsers`

Zwei Felder: `email`, `enabled`. Das ist die Zugangsliste der geschlossenen Beta aus Stufe 7.
Zwei Einträge — beide Konten des Entwicklers.
