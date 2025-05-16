const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Function to send push notifications
exports.sendPushNotification = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'The function must be called while authenticated.'
      );
    }

    const { token, title, body, data: messageData } = data;

    if (!token || !title || !body) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing required fields: token, title, or body.'
      );
    }

    const message = {
      notification: {
        title,
        body,
      },
      data: messageData || {},
      token,
    };

    const response = await admin.messaging().send(message);
    console.log('Successfully sent message:', response);
    return { success: true, messageId: response };
  } catch (error) {
    console.error('Error sending push notification:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Optional: Trigger function to notify seller when a new request is created
// This is a backup mechanism in case the client-side notification fails
exports.notifySellerOnNewRequest = functions.firestore
  .document('requests/{requestId}')
  .onCreate(async (snap, context) => {
    try {
      const requestData = snap.data();
      const { sellerId, productName, buyerName, quantity, sellerEmail } = requestData;

      // Skip if no sellerId or productName is available
      if (!productName) {
        console.log('Product name missing, skipping notification');
        return null;
      }

      // Try to find seller's FCM token
      let sellerFCMToken = null;

      // If we have sellerId, get user document directly
      if (sellerId) {
        const sellerDoc = await admin.firestore().collection('users').doc(sellerId).get();
        if (sellerDoc.exists) {
          sellerFCMToken = sellerDoc.data().fcmToken;
        }
      }
      // If we have email but no token yet, try querying by email as backup
      else if (sellerEmail && !sellerFCMToken) {
        const sellerSnapshot = await admin.firestore()
          .collection('users')
          .where('email', '==', sellerEmail)
          .limit(1)
          .get();

        if (!sellerSnapshot.empty) {
          sellerFCMToken = sellerSnapshot.docs[0].data().fcmToken;
        }
      }

      // Exit if we couldn't find a token
      if (!sellerFCMToken) {
        console.log('No FCM token found for seller');
        return null;
      }

      // Send the notification
      const message = {
        notification: {
          title: 'New Product Request',
          body: `A buyer has requested your product ${productName} for quantity ${quantity || 'unspecified'}`,
        },
        data: {
          type: 'new_request',
          requestId: context.params.requestId,
        },
        token: sellerFCMToken,
      };

      const response = await admin.messaging().send(message);
      console.log('Notification sent to seller from cloud function:', response);
      return null;

    } catch (error) {
      console.error('Error in notifySellerOnNewRequest function:', error);
      return null;
    }
  });