/**
 * One-shot Backfill Script: adds userId to all existing documents
 *
 * Usage:
 *   1. Open the app in a browser and log in with the admin account
 *   2. Open DevTools console
 *   3. Paste this entire script and press Enter
 *   4. Call: await backfillAll()
 *
 * IMPORTANT:
 *   - Run this BEFORE deploying the new strict Firestore Security Rules
 *   - Firestore batches are limited to 500 writes — this script chunks automatically
 *   - After running, verify with: await verifyBackfill()
 */

const COLLECTIONS_TO_BACKFILL = [
  'sessions',
  'plans',
  'progress',
  'schedule',
  'exercises',
  'sessionTemplates'
];

async function backfillUserId(collectionName, targetUid) {
  const coll = firebase.firestore().collection(collectionName);
  const snap = await coll.get();
  const docsWithoutUserId = snap.docs.filter(doc => !doc.data().userId);

  if (docsWithoutUserId.length === 0) {
    console.log(`✅ ${collectionName}: all ${snap.size} docs already have userId`);
    return 0;
  }

  // Chunk into batches of 500 (Firestore limit)
  const BATCH_SIZE = 500;
  let totalUpdated = 0;

  for (let i = 0; i < docsWithoutUserId.length; i += BATCH_SIZE) {
    const chunk = docsWithoutUserId.slice(i, i + BATCH_SIZE);
    const batch = firebase.firestore().batch();

    chunk.forEach(doc => {
      batch.update(doc.ref, { userId: targetUid });
    });

    await batch.commit();
    totalUpdated += chunk.length;
    console.log(`  📝 ${collectionName}: batch ${Math.floor(i / BATCH_SIZE) + 1} committed (${totalUpdated}/${docsWithoutUserId.length})`);
  }

  console.log(`✅ ${collectionName}: backfilled ${totalUpdated} of ${snap.size} docs`);
  return totalUpdated;
}

async function backfillAll() {
  const user = firebase.auth().currentUser;
  if (!user) {
    console.error('❌ Not logged in. Please log in first.');
    return;
  }

  const targetUid = user.uid;
  console.log(`🔄 Backfilling all collections with userId = ${targetUid} (${user.email})`);
  console.log('');

  let total = 0;
  for (const name of COLLECTIONS_TO_BACKFILL) {
    total += await backfillUserId(name, targetUid);
  }

  console.log('');
  console.log(`🎉 Done! Backfilled ${total} documents total.`);
  console.log('Next steps:');
  console.log('  1. Run verifyBackfill() to confirm');
  console.log('  2. Deploy the new Firestore Security Rules');
}

async function verifyBackfill() {
  console.log('🔍 Verifying all documents have userId...');
  let allGood = true;

  for (const name of COLLECTIONS_TO_BACKFILL) {
    const snap = await firebase.firestore().collection(name).get();
    const missing = snap.docs.filter(doc => !doc.data().userId);

    if (missing.length > 0) {
      console.error(`❌ ${name}: ${missing.length} docs still missing userId`);
      allGood = false;
    } else {
      console.log(`✅ ${name}: ${snap.size} docs OK`);
    }
  }

  if (allGood) {
    console.log('');
    console.log('🎉 All documents verified. Safe to deploy new Security Rules.');
  }
}

console.log('📋 Backfill script loaded. Run: await backfillAll()');
