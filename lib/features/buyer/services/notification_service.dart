import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize and set up notifications
  static Future<void> initialize() async {
    try {
      // Request permissions
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('User granted notification permission: ${settings.authorizationStatus}');

      // Get FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        // Save the token to user's Firestore document
        await _saveTokenToDatabase(token);

        // Listen for token refresh
        _messaging.onTokenRefresh.listen(_saveTokenToDatabase);
      }

      // Configure foreground message handling
      configureForegroundNotifications();

      // Set up background message handler (must be done in main.dart as well)
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
    }
  }

  static void setupTokenRefresh() {
    try {
      _messaging.onTokenRefresh.listen((String token) async {
        debugPrint('FCM token refreshed: $token');
        await _saveTokenToDatabase(token);
      });
      debugPrint('FCM token refresh listener set up');
    } catch (e) {
      debugPrint('Error setting up token refresh listener: $e');
    }
  }

  // Save FCM token to Firestore
  static Future<void> _saveTokenToDatabase(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM Token saved to Firestore: $token');
      } else {
        debugPrint('Cannot save FCM token: No authenticated user');
      }
    } catch (e) {
      debugPrint('Error saving FCM token to database: $e');
    }
  }

  // Send push notification using Firebase Cloud Functions with authentication
  static Future<bool> sendPushNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Ensure user is authenticated
      if (_auth.currentUser == null) {
        debugPrint('Failed to send notification: Not authenticated');
        return false;
      }

      debugPrint('Sending authenticated push notification to token: $token');

      // Get ID token for authentication with Cloud Functions
      final idToken = await _auth.currentUser!.getIdToken();

      // Create the callable with options
      final callable = _functions.httpsCallable(
        'sendPushNotification',
        // Firebase Functions SDK automatically includes the ID token
        // No need to set custom headers
      );

      final response = await callable.call({
        'token': token,
        'title': title,
        'body': body,
        'data': data ?? {},
      });

      final success = response.data['success'] ?? false;
      debugPrint('Push notification sent successfully: $success');
      return success;
    } catch (e) {
      debugPrint('Failed to send push notification: $e');
      return false;
    }
  }

  // Send email notification through Firebase Cloud Function
  static Future<bool> sendEmail({
    required String to,
    required String subject,
    required String body,
  }) async {
    try {
      // Ensure user is authenticated
      if (_auth.currentUser == null) {
        debugPrint('Failed to send email: Not authenticated');
        return false;
      }

      debugPrint('Sending email to: $to');

      // Get ID token for authentication with Cloud Functions
      // Firebase Functions SDK automatically includes the ID token
      final callable = _functions.httpsCallable(
        'sendEmail',
        // No need to set custom headers here
      );

      final response = await callable.call({
        'to': to,
        'subject': subject,
        'body': body,
      });

      final success = response.data['success'] ?? false;
      debugPrint('Email sent successfully: $success');
      return success;
    } catch (e) {
      debugPrint('Failed to send email: $e');
      return false;
    }
  }

  // Configure how to handle notifications when app is in foreground
  static void configureForegroundNotifications() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Notification title: ${message.notification?.title}');
        debugPrint('Notification body: ${message.notification?.body}');

        // TODO: Add local notification display here
        // You can use flutter_local_notifications package to show a notification
        // while the app is in the foreground
        _showLocalNotification(message);
      }
    });
  }

  // Show local notification - placeholder for implementing with flutter_local_notifications
  static void _showLocalNotification(RemoteMessage message) {
    // This is where you would implement local notifications with flutter_local_notifications
    // Example implementation:
    //
    // final notification = message.notification;
    // final android = message.notification?.android;
    //
    // final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    // flutterLocalNotificationsPlugin.show(
    //   notification.hashCode,
    //   notification?.title,
    //   notification?.body,
    //   NotificationDetails(
    //     android: AndroidNotificationDetails(
    //       channel.id,
    //       channel.name,
    //       channelDescription: channel.description,
    //       importance: Importance.max,
    //       priority: Priority.high,
    //     ),
    //   ),
    //   payload: jsonEncode(message.data),
    // );
  }

  // Subscribe to specific topic for notifications
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  // Unsubscribe from a topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }

  // Get notification settings
  static Future<bool> getNotificationPermissionStatus() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  // Request notification permissions and return status
  static Future<bool> requestNotificationPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  // Get the current FCM token
  static Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  // Check if a seller has a valid FCM token
  static Future<String?> getSellerFCMToken(String sellerEmail) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: sellerEmail)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final sellerData = querySnapshot.docs.first.data();
        return sellerData['fcmToken'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting seller FCM token: $e');
      return null;
    }
  }
}

// This needs to be a top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Don't need Firebase.initializeApp() here if it's already done in main.dart
  debugPrint('Handling a background message: ${message.messageId}');
  debugPrint('Background message data: ${message.data}');
}