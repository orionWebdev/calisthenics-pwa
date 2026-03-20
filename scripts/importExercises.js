#!/usr/bin/env node

/**
 * Import curated exercises into Firestore collection "exercises_curated".
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json node importExercises.js
 *
 * Or pass the path as first argument:
 *   node importExercises.js ./serviceAccountKey.json
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// ---------------------------------------------------------------------------
// 1. Resolve service account key
// ---------------------------------------------------------------------------
const keyPath = process.argv[2] || process.env.GOOGLE_APPLICATION_CREDENTIALS;

if (!keyPath) {
  console.error(
    'Error: No service account key provided.\n' +
    'Usage:\n' +
    '  GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json node importExercises.js\n' +
    '  node importExercises.js ./serviceAccountKey.json'
  );
  process.exit(1);
}

const resolvedKeyPath = path.resolve(keyPath);

if (!fs.existsSync(resolvedKeyPath)) {
  console.error(`Error: Service account key file not found at ${resolvedKeyPath}`);
  process.exit(1);
}

// ---------------------------------------------------------------------------
// 2. Initialize Firebase Admin
// ---------------------------------------------------------------------------
const serviceAccount = require(resolvedKeyPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const COLLECTION = 'exercises_curated';

// ---------------------------------------------------------------------------
// 3. Load exercises from JSON
// ---------------------------------------------------------------------------
const exercisesPath = path.resolve(__dirname, '..', 'data', 'exercises_curated.json');

if (!fs.existsSync(exercisesPath)) {
  console.error(`Error: exercises_curated.json not found at ${exercisesPath}`);
  process.exit(1);
}

const exercises = JSON.parse(fs.readFileSync(exercisesPath, 'utf-8'));
console.log(`Loaded ${exercises.length} exercises from ${exercisesPath}`);

// ---------------------------------------------------------------------------
// 4. Import into Firestore (merge mode: updates existing, inserts new)
// ---------------------------------------------------------------------------
const forceUpdate = process.argv.includes('--force');

async function importExercises() {
  let inserted = 0;
  let updated = 0;
  let errors = 0;

  for (const exercise of exercises) {
    const docRef = db.collection(COLLECTION).doc(exercise.id);

    try {
      const doc = await docRef.get();

      if (doc.exists) {
        // Merge new fields into existing document (preserves user-added fields)
        await docRef.set(exercise, { merge: !forceUpdate });
        updated++;
      } else {
        await docRef.set(exercise);
        inserted++;
      }
    } catch (err) {
      errors++;
      console.error(`  Error importing "${exercise.id}": ${err.message}`);
    }
  }

  console.log('\n--- Import complete ---');
  console.log(`  Inserted: ${inserted}`);
  console.log(`  Updated (merged): ${updated}`);
  if (errors > 0) {
    console.log(`  Errors: ${errors}`);
  }
  console.log(`  Total processed: ${exercises.length}`);
  if (forceUpdate) {
    console.log('  Mode: --force (full replace)');
  } else {
    console.log('  Mode: merge (new fields added, existing preserved)');
  }
}

importExercises()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('Fatal error:', err);
    process.exit(1);
  });
