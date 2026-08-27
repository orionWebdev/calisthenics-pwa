/**
 * Erzeugt ein Testorakel für die Dart-Portierung des Scorings.
 *
 * Die Portierung von `js/views/sessions/scoring.js` ist erst dann bewiesen,
 * wenn beide Fassungen für dieselben Eingaben dieselben Zahlen liefern. Dieses
 * Werkzeug führt das **echte JavaScript** aus und schreibt Eingaben und
 * Ergebnisse in eine Datei, gegen die der Dart-Test prüft.
 *
 * Die Einheiten sind synthetisch und deterministisch erzeugt — kein einziger
 * echter Trainingswert. Sie decken die Fälle ab, an denen sich die beiden
 * Fassungen unterscheiden könnten: alle Arten, RPE 1 bis 5 und fehlend, Übungen
 * mit und ohne Körpergewichtsflagge, leere Sätze, Dauern über der
 * Dämpfungsschwelle, Ruhetage, Erholungstage.
 *
 *     node tool/scoring_oracle.mjs test/fixtures/scoring_oracle.json
 */

import { readFileSync, writeFileSync } from 'node:fs';
import vm from 'node:vm';

// ---------------------------------------------------------------- Zufall
// Linearer Kongruenzgenerator: deterministisch, damit die Datei bei jedem Lauf
// identisch ist und ein Diff etwas bedeutet.
let seed = 20260827;
function rnd() {
  seed = (seed * 1103515245 + 12345) & 0x7fffffff;
  return seed / 0x7fffffff;
}
const pick = (list) => list[Math.floor(rnd() * list.length)];
const between = (lo, hi) => lo + rnd() * (hi - lo);
const intBetween = (lo, hi) => Math.floor(between(lo, hi + 1));

// ---------------------------------------------------------------- Eingaben
const BASE = new Date('2026-01-01T00:00:00');
const DAYS = 100;
const TYPES = ['strength', 'bodyweight', 'cardio', 'recovery'];
const ACTIVITIES = ['run', 'bike', 'hike', 'walk', 'stretching', 'yoga', 'sauna', 'other', 'padel'];
const EXERCISES = ['push_up', 'pull_up', 'squat', 'deadlift', 'dip'];

function buildSessions() {
  const sessions = [];
  for (let day = 0; day < DAYS; day++) {
    // Etwa jeder dritte Tag ist ein Ruhetag — die Kurve braucht sie, sonst
    // klingt die akute Last nie ab.
    if (rnd() < 0.35) continue;

    const count = rnd() < 0.12 ? 2 : 1; // gelegentlich zwei am Tag
    for (let n = 0; n < count; n++) {
      const type = pick(TYPES);
      const date = new Date(BASE);
      date.setDate(date.getDate() + day);
      date.setHours(intBetween(6, 21), intBetween(0, 59), 0, 0);

      const s = { type, date: date.toISOString() };

      // rpe fehlt in einem Drittel der Fälle — dann rechnet die PWA mit 3.
      if (rnd() > 0.33) s.rpe = intBetween(1, 5);
      if (rnd() > 0.5) s.duration = Math.round(between(5, 200) * 10) / 10;

      if (type === 'cardio') {
        s.activityType = pick(ACTIVITIES);
      }

      if (type === 'strength' || type === 'bodyweight') {
        if (rnd() > 0.25) {
          s.exercises = Array.from({ length: intBetween(1, 4) }, () => {
            const ex = { exerciseId: pick(EXERCISES) };
            if (rnd() > 0.6) ex.usesBodyweight = rnd() > 0.5;
            ex.sets = Array.from({ length: intBetween(1, 5) }, () => {
              if (rnd() < 0.08) return {}; // leerer Satz, kommt im Bestand vor
              const set = { reps: rnd() < 0.1 ? 0 : intBetween(1, 15) };
              if (rnd() > 0.15) set.weight = intBetween(0, 120);
              return set;
            });
            return ex;
          });
        }
        if (rnd() > 0.7) s.discipline = pick(['bodyweight', 'weights']);
      }

      sessions.push(s);
    }
  }
  return sessions;
}

// ---------------------------------------------------------------- JS laden
// Am Dateiende hängt ein Block `window.foo = foo` — und ein Teil dieser
// Funktionen liegt in anderen Dateien. Der Block wird abgeschnitten; die
// Rechenfunktionen darüber bleiben unangetastet.
const raw = readFileSync('js/views/sessions/scoring.js', 'utf8');
const cut = raw.indexOf('\nwindow.');
const src = cut === -1 ? raw : raw.slice(0, cut);

// Körpergewicht bewusst gesetzt: Ohne es liefert jede Körpergewichtsübung
// Volumen 0, und der interessantere Pfad würde nie durchlaufen.
// `window` als Auffangbecken: Die Datei hängt am Ende ihre Funktionen an das
// Fenster. Ohne diesen Platzhalter bricht sie beim Laden ab.
const sandbox = {
  userProfile: { bodyWeight: 78 },
  allExercises: [],
  window: {},
  console,
  Math,
  Date,
};

const EXPORTS =
  '\n;({ calculateSessionLoadValue, isRecoverySession, mapReadiness, mapZone, getACWR, computeFormScore, mapFormZone })';

const api = vm.runInNewContext(src + EXPORTS, sandbox);

/**
 * Dieselbe Datei, aber mit kalendarischer statt millisekundengenauer
 * Fenstergrenze.
 *
 * Die PWA rechnet `refDay.getTime() - N * 24 * 60 * 60 * 1000`. Liegt eine
 * Zeitumstellung im Fenster, ergibt das 23:00 des Vortags statt Mitternacht —
 * und weil die Schleife die Uhrzeit mitschleppt, endet sie einen Tag zu früh:
 * Der Referenztag fällt aus dem gleitenden Mittel heraus. Zweimal im Jahr,
 * jeweils für die folgenden acht Wochen.
 *
 * Die Dart-Fassung rechnet kalendarisch und ist damit unabhängig von der
 * Zeitumstellung. Diese zweite Auswertung ist ihr Massstab.
 */
const corrected = vm.runInNewContext(
  src
    // Fenstergrenze kalendarisch statt in Millisekunden.
    .replace(
      /refDay\.getTime\(\) - (\d+) \* 24 \* 60 \* 60 \* 1000/g,
      'new Date(refDay.getFullYear(), refDay.getMonth(), refDay.getDate() - $1).getTime()',
    )
    // Tagesabstände runden statt abschneiden. Zwischen zwei lokalen
    // Mitternachten liegen bei einer Zeitumstellung 23 oder 25 Stunden;
    // `Math.floor` macht daraus einen Tag zu wenig.
    .replace(
      /Math\.floor\(\(refDay\.getTime\(\) - ([A-Za-z]+)\.getTime\(\)\) \/ \(1000 \* 60 \* 60 \* 24\)\)/g,
      'Math.round((refDay.getTime() - $1.getTime()) / (1000 * 60 * 60 * 24))',
    ) + EXPORTS,
  { ...sandbox },
);

// ---------------------------------------------------------------- Ausgabe
const sessions = buildSessions();

const loads = sessions.map((s) => {
  const { rawLoad } = api.calculateSessionLoadValue(s);
  return { rawLoad, isRecovery: api.isRecoverySession(s) };
});

// Stützstellen der Kurve einzeln, damit ein Abweichen sofort lokalisierbar ist.
const curve = [];
for (let x = 0; x <= 260; x += 3) {
  const acwr = x / 100;
  const score = api.mapReadiness(acwr);
  curve.push({ acwr, score, zone: api.mapZone(score, acwr) });
}

// Früheste Einheit mit Last — der tatsächliche Anfang beider Schleifen.
const earliest = sessions
  .map((s) => new Date(s.date))
  .reduce((a, b) => (a < b ? a : b));

const cases = [];
const forms = [];
for (const day of [13, 14, 20, 35, 50, 70, 99]) {
  const ref = new Date(BASE);
  ref.setDate(ref.getDate() + day);
  ref.setHours(12, 0, 0, 0);

  // Fällt eine Zeitumstellung ins Fenster? Nur dann können beide Fassungen
  // abweichen.
  //
  // Entscheidend ist der **tatsächliche** Anfang: Beide Schleifen beginnen bei
  // `max(erste Einheit, refDay - N)`. Wird auf die erste Einheit geklemmt, hat
  // der Startpunkt echte Mitternacht, und der Fehler der PWA tritt gar nicht
  // auf. Eine Markierung nach `refDay - N` wäre zu pessimistisch und liesse den
  // Abgleich gegen die PWA fast nie laufen.
  const effectiveStart = (n) => {
    const nominal = new Date(ref.getFullYear(), ref.getMonth(), ref.getDate() - n);
    return nominal > earliest ? nominal : earliest;
  };
  const dstInWindow =
    effectiveStart(56).getTimezoneOffset() !== ref.getTimezoneOffset();
  const dstInFormWindow =
    effectiveStart(120).getTimezoneOffset() !== ref.getTimezoneOffset();

  for (const applyFatigue of [false, true]) {
    const shape = (a) => ({
      acuteLoad: a.acuteLoad,
      chronicLoad: a.chronicLoad,
      acwr: a.acwr,
      readinessScore: a.readinessScore,
      zone: a.zone,
      daysSinceLastSession: a.daysSinceLastSession,
      todayLoad: a.todayLoad,
      fatiguePenalty: a.fatiguePenalty,
    });
    cases.push({
      day,
      applyFatigue,
      dstInWindow,
      referenceDate: ref.toISOString(),
      ...shape(corrected.getACWR(sessions, ref, { applyFatigue })),
      pwa: shape(api.getACWR(sessions, ref, { applyFatigue })),
    });
  }

  const shapeForm = (f) => ({
    formScore: f.formScore,
    zone: f.zone,
    consistency: f.consistency,
    loadLevel: f.loadLevel,
    recency: f.recency,
    trend: f.trend,
    daysSinceLastSession: f.daysSinceLastSession,
  });
  forms.push({
    day,
    referenceDate: ref.toISOString(),
    dstInWindow: dstInFormWindow,
    ...shapeForm(corrected.computeFormScore(sessions, ref)),
    pwa: shapeForm(api.computeFormScore(sessions, ref)),
  });
}

const target = process.argv[2] ?? 'test/fixtures/scoring_oracle.json';
writeFileSync(
  target,
  JSON.stringify({ bodyWeightKg: 78, sessions, loads, curve, cases, forms }, null, 1),
);

const abweichend = cases.filter((c) => c.acwr !== c.pwa.acwr).length;
const formAbweichend = forms.filter((f) => f.formScore !== f.pwa.formScore).length;
console.log(
  `${sessions.length} Einheiten, ${curve.length} Kurvenpunkte, ` +
    `${cases.length} ACWR-Fälle (${abweichend} abweichend), ` +
    `${forms.length} Form-Fälle (${formAbweichend} abweichend) -> ${target}`,
);
