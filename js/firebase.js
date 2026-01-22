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

// Collections (unsere "Tabellen")
const exercisesCollection = db.collection('exercises');
const plansCollection = db.collection('plans');
const workoutsCollection = db.collection('workouts');
const scheduleCollection = db.collection('schedule');
const progressCollection = db.collection('progress');
const sessionsCollection = db.collection('sessions');

// ========================================
// FIRESTORE HELPER FUNCTIONS
// ========================================

// Alle Dokumente aus einer Collection laden
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

// Ein Dokument hinzufügen
async function addDoc(collection, data) {
  try {
    const docRef = await collection.add({
      ...data,
      createdAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    return docRef.id;
  } catch (error) {
    console.error('Error adding document:', error);
    throw error;
  }
}

// Ein Dokument updaten
async function updateDoc(collection, id, data) {
  try {
    await collection.doc(id).update({
      ...data,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    });
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

// Real-time Listener für eine Collection
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

console.log('🔥 Firebase initialized successfully!');