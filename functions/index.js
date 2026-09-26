const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Background Cloud Function for User Cleanup upon Account Deletion
exports.onUserDeleted = functions.auth.user().onDelete(async (user) => {
  const uid = user.uid;
  const db = admin.firestore();

  console.log(`[VYRO CLEANUP]: Deleting user data for UID ${uid}`);

  const batch = db.batch();

  // Delete User Doc
  batch.delete(db.collection('users').doc(uid));

  // Find & Delete Username Doc
  const usernameQuery = await db.collection('usernames').where('uid', '==', uid).get();
  usernameQuery.forEach((doc) => batch.delete(doc.ref));

  await batch.commit();
});
