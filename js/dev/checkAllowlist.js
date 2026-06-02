// ========================================
// ALLOWLIST DEBUG HELPER
// ========================================

/**
 * Debug function to check allowlist status
 * Call this from browser console: checkMyAllowlistStatus('your@email.com')
 */
window.checkMyAllowlistStatus = async function(email) {
  console.log('\n🔍 Checking Allowlist Status...\n');
  console.log('📧 Email:', email);

  try {
    // Get current user
    const currentUser = firebase.auth().currentUser;
    if (currentUser) {
      console.log('✅ Currently logged in as:', currentUser.email);
      console.log('   UID:', currentUser.uid);
    } else {
      console.log('⚠️ No user currently logged in');
    }

    // Check allowedUsers collection
    const db = firebase.firestore();
    const allowedUsersCollection = db.collection('allowedUsers');

    console.log('\n📋 Checking allowedUsers collection...\n');

    // Method 1: Check by UID (if logged in)
    if (currentUser) {
      console.log('1️⃣ Checking by UID:', currentUser.uid);
      try {
        const uidDoc = await allowedUsersCollection.doc(currentUser.uid).get();
        if (uidDoc.exists) {
          const data = uidDoc.data();
          console.log('   ✅ Found document by UID!');
          console.log('   Data:', data);
          console.log('   Enabled:', data.enabled);
        } else {
          console.log('   ❌ No document found with UID:', currentUser.uid);
        }
      } catch (error) {
        console.error('   ❌ Error checking by UID:', error.message);
      }
    }

    // Method 2: Check by email
    console.log('\n2️⃣ Checking by email:', email);
    try {
      const emailQuery = await allowedUsersCollection
        .where('email', '==', email)
        .get();

      if (!emailQuery.empty) {
        console.log('   ✅ Found document(s) by email!');
        emailQuery.forEach(doc => {
          console.log('   Document ID:', doc.id);
          console.log('   Data:', doc.data());
          console.log('   Enabled:', doc.data().enabled);
        });
      } else {
        console.log('   ❌ No document found with email:', email);
      }
    } catch (error) {
      console.error('   ❌ Error checking by email:', error.message);
    }

    // Method 3: List ALL documents in allowedUsers
    console.log('\n3️⃣ Listing ALL documents in allowedUsers collection:');
    try {
      const allDocs = await allowedUsersCollection.get();

      if (allDocs.empty) {
        console.log('   ⚠️ Collection is EMPTY! No users in allowlist.');
        console.log('\n📝 TO FIX THIS:');
        console.log('   1. Go to: https://console.firebase.google.com/project/calisthenics-pro-57d6d/firestore');
        console.log('   2. Click "Start collection"');
        console.log('   3. Collection ID: allowedUsers');
        console.log('   4. Document ID: Use your email or UID');
        console.log('   5. Add fields:');
        console.log('      - email: "' + (email || 'your@email.com') + '"');
        console.log('      - enabled: true');
        console.log('      - addedAt: [timestamp]');
      } else {
        console.log('   Found', allDocs.size, 'document(s):');
        allDocs.forEach(doc => {
          console.log('\n   📄 Document ID:', doc.id);
          console.log('      Data:', doc.data());
        });
      }
    } catch (error) {
      console.error('   ❌ Error listing all documents:', error.message);

      if (error.code === 'permission-denied') {
        console.log('\n   ⚠️ PERMISSION DENIED - This might mean:');
        console.log('      1. The collection doesn\'t exist yet');
        console.log('      2. Security rules are blocking access');
        console.log('      3. You need to create the collection first');
      }
    }

    console.log('\n✨ Check complete!\n');

  } catch (error) {
    console.error('❌ Error during check:', error);
  }
};

// Auto-run check if user is logged in
if (typeof firebase !== 'undefined') {
  firebase.auth().onAuthStateChanged((user) => {
    if (user && window.location.hostname === 'localhost') {
      console.log('\n🔍 Auto-checking allowlist for logged-in user...');
      setTimeout(() => {
        window.checkMyAllowlistStatus(user.email);
      }, 1000);
    }
  });
}

console.log('✅ Allowlist Debug Helper loaded!');
console.log('💡 Usage: checkMyAllowlistStatus("your@email.com")');
