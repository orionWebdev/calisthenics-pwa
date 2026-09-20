#!/usr/bin/env node
// Füllt die lokalen Firebase-Emulatoren, damit die App ohne Closed Beta läuft.
//
//   firebase emulators:start --only auth,firestore     # Terminal 1
//   node tool/emulator_seed.mjs                        # Terminal 2, nach dem Start
//   flutter run --dart-define=USE_EMULATOR=true        # Terminal 3
//
// Was es anlegt (alles nur im Emulator, nie im echten Projekt):
//   * das Testkonto test@atem.local (dasselbe wie in lib/app/emulator.dart)
//   * allowedUsers/{uid} und allowedUsers/{email} — dieselbe Zugangsliste, die
//     die echten Regeln prüfen; die Regeln selbst bleiben unverändert
//   * userProfiles/{uid} mit Körpergewicht, damit das Onboarding nicht
//     dazwischenkommt (Profil im Emulator-UI löschen, um es zu sehen)
//   * exercises_curated aus data/exercises_curated.json
//
// Der Emulator startet leer. Das Skript ist wiederholbar: Es überschreibt.
// Ohne Abhängigkeiten, braucht Node ≥ 18.

import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const AUTH = process.env.AUTH_EMULATOR ?? 'http://127.0.0.1:9099';
const STORE = process.env.FIRESTORE_EMULATOR ?? 'http://127.0.0.1:8081';

const EMAIL = 'test@atem.local';
const PASSWORD = 'atem-test-2026'; // Gegenstück: AtemEmulator.testPassword

const projectId = JSON.parse(
  readFileSync(resolve(root, 'android/app/google-services.json'), 'utf8'),
).project_info.project_id;

const docs = `${STORE}/v1/projects/${projectId}/databases/(default)/documents`;

/** JS-Wert → Firestore-REST-Wert. */
function toValue(v) {
  if (v === null || v === undefined) return { nullValue: null };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') {
    return Number.isInteger(v)
      ? { integerValue: String(v) }
      : { doubleValue: v };
  }
  if (typeof v === 'string') return { stringValue: v };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(toValue) } };
  return { mapValue: { fields: toFields(v) } };
}

function toFields(obj) {
  return Object.fromEntries(
    Object.entries(obj).map(([k, v]) => [k, toValue(v)]),
  );
}

/** Schreibt ein Dokument. `Bearer owner` umgeht die Regeln — nur im Emulator. */
async function put(collection, id, data) {
  const res = await fetch(`${docs}/${collection}/${encodeURIComponent(id)}`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: 'Bearer owner',
    },
    body: JSON.stringify({ fields: toFields(data) }),
  });
  if (!res.ok) throw new Error(`${collection}/${id}: ${res.status} ${await res.text()}`);
}

/** Legt das Testkonto an oder holt seine UID, falls es schon existiert. */
async function ensureUser() {
  const call = async (path) => {
    const res = await fetch(
      `${AUTH}/identitytoolkit.googleapis.com/v1/accounts:${path}?key=fake`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: EMAIL,
          password: PASSWORD,
          returnSecureToken: true,
        }),
      },
    );
    return { ok: res.ok, body: await res.json() };
  };
  let r = await call('signUp');
  if (!r.ok) r = await call('signInWithPassword'); // gab es schon
  if (!r.ok) throw new Error(`Testkonto: ${JSON.stringify(r.body)}`);
  return r.body.localId;
}

try {
  const uid = await ensureUser();
  console.log(`Testkonto ${EMAIL}  (uid ${uid}, Projekt ${projectId})`);

  await put('allowedUsers', uid, { enabled: true, email: EMAIL });
  await put('allowedUsers', EMAIL, { enabled: true, email: EMAIL });
  await put('userProfiles', uid, { bodyWeight: 80, unitSystem: 'metric' });

  const exercises = JSON.parse(
    readFileSync(resolve(root, 'data/exercises_curated.json'), 'utf8'),
  );
  for (const e of exercises) await put('exercises_curated', e.id, e);
  console.log(`exercises_curated: ${exercises.length} Übungen`);
  console.log('Fertig. Jetzt: flutter run --dart-define=USE_EMULATOR=true');
} catch (e) {
  console.error(`\nSeed fehlgeschlagen: ${e.message}`);
  console.error('Läuft der Emulator? firebase emulators:start --only auth,firestore');
  process.exit(1);
}
