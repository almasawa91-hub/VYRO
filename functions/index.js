const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');

admin.initializeApp();
const db = admin.firestore();

async function createNotification({
  userId,
  type,
  title,
  body,
  actorId = '',
  entityId = '',
}) {
  if (!userId) return;

  const id = [type, userId, entityId || actorId || Date.now().toString()]
    .join('_')
    .replace(/[^a-zA-Z0-9_-]/g, '_');

  await db.collection('notifications').doc(id).set({
    userId,
    type,
    title,
    body,
    actorId,
    entityId,
    read: false,
    readAt: null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
}

// Create a notification when a new friend request is sent.
exports.onFriendRequestCreated = onDocumentCreated(
  'friendRequests/{requestId}',
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const data = snapshot.data();
    if (data.status !== 'pending' || !data.receiverId || !data.senderId) return;

    const sender = await db.collection('users').doc(data.senderId).get();
    const senderName = sender.data()?.displayName || 'مستخدم VYRO';

    await createNotification({
      userId: data.receiverId,
      type: 'friend_request',
      title: 'طلب صداقة جديد',
      body: `${senderName} أرسل لك طلب صداقة.`,
      actorId: data.senderId,
      entityId: event.params.requestId,
    });
  },
);

// Notify the sender when their friend request is accepted.
exports.onFriendRequestUpdated = require('firebase-functions/v2/firestore')
  .onDocumentUpdated('friendRequests/{requestId}', async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    if (before.status === 'pending' &&
        after.status === 'accepted' &&
        after.senderId &&
        after.receiverId) {
      const receiver = await db.collection('users').doc(after.receiverId).get();
      const receiverName = receiver.data()?.displayName || 'مستخدم VYRO';

      await createNotification({
        userId: after.senderId,
        type: 'friend_accepted',
        title: 'تم قبول طلب الصداقة',
        body: `${receiverName} قبل طلب الصداقة.`,
        actorId: after.receiverId,
        entityId: event.params.requestId,
      });
    }
  });

// Notify the other chat participant when a new text message is created.
exports.onMessageCreated = onDocumentCreated(
  'chats/{chatId}/messages/{messageId}',
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const message = snapshot.data();
    if (!message?.senderId || message.type !== 'text') return;

    const chat = await db.collection('chats').doc(event.params.chatId).get();
    if (!chat.exists) return;

    const participants = chat.data()?.participants;
    if (!Array.isArray(participants) || participants.length !== 2) return;

    const receiverId = participants.find((id) => id !== message.senderId);
    if (!receiverId) return;

    const sender = await db.collection('users').doc(message.senderId).get();
    const senderName = sender.data()?.displayName || 'مستخدم VYRO';

    const text = String(message.text || '').trim();
    const preview = text.length > 100 ? `${text.substring(0, 100)}…` : text;

    await createNotification({
      userId: receiverId,
      type: 'message',
      title: `رسالة من ${senderName}`,
      body: preview || 'أرسل لك رسالة جديدة.',
      actorId: message.senderId,
      entityId: event.params.chatId,
    });
  },
);

// Background Cloud Function for user cleanup upon account deletion.
exports.onUserDeleted = functions.auth.user().onDelete(async (user) => {
  const uid = user.uid;

  console.log(`[VYRO CLEANUP]: Deleting user data for UID ${uid}`);

  const batch = db.batch();

  batch.delete(db.collection('users').doc(uid));

  const usernameQuery = await db.collection('usernames').where('uid', '==', uid).get();
  usernameQuery.forEach((doc) => batch.delete(doc.ref));

  await batch.commit();
});
