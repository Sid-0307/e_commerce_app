const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp({
    storageBucket: 'e-commercedev-e9149.firebasestorage.app'
});

const fcm = admin.messaging();


exports.checkHealth = functions.https.onCall(async(data,context)=>{
return "Function is online";
})

exports.sendPushNotification = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'You must be logged in to send notifications'
      );
    }

    const { token, title, body, data: messageData = {} } = data;

    // Validate inputs
    if (!token) {
      throw new functions.https.HttpsError('invalid-argument', 'Token is required');
    }
    if (!title || !body) {
      throw new functions.https.HttpsError('invalid-argument', 'Title and body are required');
    }

    const message = {
      notification: { title, body },
      data: messageData,
      token,
      android: {
        priority: 'high',
        notification: {
          clickAction: 'FLUTTER_NOTIFICATION_CLICK'
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1
          }
        }
      }
    };

    const response = await admin.messaging().send(message);
    console.log('Successfully sent message:', response);
    return { success: true, messageId: response };
  } catch (error) {
    console.error('Error sending notification:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});