// ========================================
// FIREBASE CONFIGURATION & INITIALIZATION
// ========================================

// WICHTIG: Ersetze dies mit deinem eigenen Firebase Config!
const firebaseConfig = {
    apiKey: "AIzaSyDb25zKgtki24LXid9T8UE3jc8mbQRBQdE",
    authDomain: "calisthenics-pro-57d6d.firebaseapp.com",
    projectId: "calisthenics-pro-57d6d",
    storageBucket: "calisthenics-pro-57d6d.firebasestorage.app",
    messagingSenderId: "53503392138",
    appId: "1:53503392138:web:6bd9c5af650c496d62b073"
    };

// Firebase initialisieren
firebase.initializeApp(firebaseConfig);

// Firestore Datenbank Referenz
const db = firebase.firestore();

// Offline-first: cache reads/writes locally and auto-sync on reconnect. Single
// Capacitor WebView → synchronizeTabs harmless. Failures (multi-tab / unsupported
// browser) degrade gracefully to online-only.
try {
  db.enablePersistence({ synchronizeTabs: true }).catch(function (err) {
    console.warn('Firestore offline persistence not enabled:', err && err.code);
  });
} catch (e) {
  console.warn('Firestore offline persistence threw:', e);
}

// Collections (unsere "Tabellen")
const exercisesCuratedCollection = db.collection('exercises_curated');
const exercisesCollection = db.collection('exercises');
const plansCollection = db.collection('plans');
const workoutsCollection = db.collection('workouts');
const scheduleCollection = db.collection('schedule');
const progressCollection = db.collection('progress');
const sessionsCollection = db.collection('sessions');
const userProfilesCollection = db.collection('userProfiles');

// ========================================
// FIRESTORE HELPER FUNCTIONS
// ========================================

function getActiveUserId() {
  const user = firebase.auth().currentUser;
  if (!user) {
    throw new Error('No authenticated user — Firestore operation blocked');
  }
  return user.uid;
}

function isPlainObject(value) {
  if (!value || typeof value !== 'object') return false;
  return Object.getPrototypeOf(value) === Object.prototype;
}

function stripUndefinedDeep(value) {
  if (value === undefined) return undefined;

  if (Array.isArray(value)) {
    const cleaned = value
      .map(item => stripUndefinedDeep(item))
      .filter(item => item !== undefined);
    return cleaned;
  }

  if (isPlainObject(value)) {
    const result = {};
    Object.keys(value).forEach(key => {
      const cleanedValue = stripUndefinedDeep(value[key]);
      if (cleanedValue !== undefined) {
        result[key] = cleanedValue;
      }
    });
    return result;
  }

  return value;
}

function sanitizeFirestorePayload(payload) {
  return stripUndefinedDeep(payload);
}

// Alle Dokumente aus einer Collection laden (global, z.B. für exercises_curated)
async function getAllDocs(collection) {
  try {
    const snapshot = await collection.get();
    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
  } catch (error) {
    console.error('Error loading documents:', error);
    return [];
  }
}

// User-scoped Load: nur Dokumente des aktuell angemeldeten Nutzers
async function getAllDocsForUser(collection) {
  try {
    const uid = getActiveUserId();
    const snapshot = await collection.where('userId', '==', uid).get();
    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
  } catch (error) {
    console.error('Error loading user-scoped documents:', error);
    return [];
  }
}

// Ein Dokument hinzufügen. scoped=true (Default) injiziert userId automatisch.
async function addDoc(collection, data, options = { scoped: true }) {
  try {
    const payload = {
      ...data,
      createdAt: firebase.firestore.FieldValue.serverTimestamp()
    };
    if (options.scoped !== false) {
      payload.userId = getActiveUserId();
    }
    const sanitized = sanitizeFirestorePayload(payload);
    const docRef = await collection.add(sanitized);
    return docRef.id;
  } catch (error) {
    console.error('Error adding document:', error);
    throw error;
  }
}

// Curated-Übung mit STABILER id schreiben (Upsert, global/ungescoped).
// Wird vom Seeding genutzt, damit Übungs-ids deterministisch & lesbar sind.
async function setCuratedExercise(id, data) {
  try {
    // id steckt im Dokumentpfad — nicht zusätzlich im Body speichern.
    const { id: _drop, ...rest } = data;
    const sanitized = sanitizeFirestorePayload({
      ...rest,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    await exercisesCuratedCollection.doc(id).set(sanitized);
    return id;
  } catch (error) {
    console.error('Error writing curated exercise:', error);
    throw error;
  }
}

// Ein Dokument updaten
async function updateDoc(collection, id, data) {
  try {
    const sanitized = sanitizeFirestorePayload({
      ...data,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    await collection.doc(id).update(sanitized);
    return true;
  } catch (error) {
    console.error('Error updating document:', error);
    throw error;
  }
}

// Ein Dokument löschen
async function deleteDoc(collection, id) {
  try {
    await collection.doc(id).delete();
    return true;
  } catch (error) {
    console.error('Error deleting document:', error);
    throw error;
  }
}

// Real-time Listener für eine Collection (global, z.B. für exercises_curated)
function onCollectionChange(collection, callback) {
  return collection.onSnapshot(snapshot => {
    const docs = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    callback(docs);
  }, error => {
    console.error('Error in real-time listener:', error);
  });
}

// User-scoped Real-time Listener: nur Dokumente des aktuellen Nutzers
function onUserCollectionChange(collection, callback) {
  const uid = getActiveUserId();
  return collection
    .where('userId', '==', uid)
    .onSnapshot(snapshot => {
      const docs = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      callback(docs);
    }, error => {
      console.error('Error in user-scoped listener:', error);
    });
}

// ========================================
// ONE-TIME MIGRATION: backfill userId
// ========================================

const MIGRATION_KEY = 'userId_backfill_done';
const COLLECTIONS_TO_BACKFILL = [
  sessionsCollection,
  plansCollection,
  progressCollection,
  scheduleCollection,
  exercisesCollection,
  db.collection('sessionTemplates')
];

async function runUserIdBackfillIfNeeded() {
  if (localStorage.getItem(MIGRATION_KEY)) return;

  const uid = getActiveUserId();
  console.log(`🔄 Running one-time userId backfill for ${uid}...`);

  let totalUpdated = 0;

  for (const coll of COLLECTIONS_TO_BACKFILL) {
    const snap = await coll.get();
    const docsWithout = snap.docs.filter(doc => !doc.data().userId);
    if (docsWithout.length === 0) continue;

    const BATCH_SIZE = 500;
    for (let i = 0; i < docsWithout.length; i += BATCH_SIZE) {
      const chunk = docsWithout.slice(i, i + BATCH_SIZE);
      const batch = db.batch();
      chunk.forEach(doc => batch.update(doc.ref, { userId: uid }));
      await batch.commit();
    }

    totalUpdated += docsWithout.length;
    console.log(`  ✅ ${coll.id}: ${docsWithout.length} docs backfilled`);
  }

  localStorage.setItem(MIGRATION_KEY, Date.now().toString());
  if (totalUpdated > 0) {
    console.log(`🎉 Backfill complete: ${totalUpdated} docs updated`);
  } else {
    console.log('✅ No backfill needed — all docs already have userId');
  }
}

console.log('🔥 Firebase initialized successfully!');
