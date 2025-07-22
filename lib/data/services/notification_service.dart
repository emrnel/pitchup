// lib/data/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/notification_model.dart';
import 'firestore_service.dart';
import 'firebase_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static NotificationService get instance => _instance;

  final FirebaseMessaging _messaging = FirebaseService.messaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirestoreService _firestoreService = FirestoreService();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    await _initializeLocalNotifications();
    await _initializeFCM();
    _setupMessageHandlers();
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> _initializeFCM() async {
    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Get FCM token
    _fcmToken = await _messaging.getToken();
    print('FCM Token: $_fcmToken');

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      _updateUserFCMToken(newToken);
    });
  }

  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle message when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Foreground message: ${message.notification?.title}');

    // Show local notification
    await _showLocalNotification(message);

    // Store in Firestore
    await _storeNotificationInFirestore(message);
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Background message: ${message.notification?.title}');
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    print('Message clicked: ${message.notification?.title}');

    // Navigate to appropriate screen based on notification data
    _handleNotificationTap(message.data);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'pitchup_channel',
      'PitchUp Notifications',
      channelDescription: 'Notifications for PitchUp app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      notificationDetails,
      payload: message.data.toString(),
    );
  }

  Future<void> _storeNotificationInFirestore(RemoteMessage message) async {
    try {
      final userId = message.data['userId'];
      if (userId == null) return;

      final notification = NotificationModel(
        id: '',
        userId: userId,
        type: _parseNotificationType(message.data['type']),
        title: message.notification?.title ?? '',
        body: message.notification?.body ?? '',
        data: message.data,
        isRead: false,
        createdAt: DateTime.now(),
      );

      await _firestoreService.createNotification(notification);
    } catch (e) {
      print('Failed to store notification: $e');
    }
  }

  NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'offer_received':
        return NotificationType.offerReceived;
      case 'offer_accepted':
        return NotificationType.offerAccepted;
      case 'offer_rejected':
        return NotificationType.offerRejected;
      case 'new_message':
        return NotificationType.newMessage;
      default:
        return NotificationType.offerReceived;
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Parse payload and navigate
    if (response.payload != null) {
      _handleNotificationTap({});
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    // TODO: Implement navigation based on notification data
    // This will be implemented when we have the routing system ready
  }

  Future<void> _updateUserFCMToken(String token) async {
    // TODO: Update user's FCM token in Firestore
    // This will be implemented when we have the user service ready
  }

  // Public methods for sending notifications
  Future<void> sendOfferReceivedNotification({
    required String entrepreneurId,
    required String offerId,
    required double amount,
  }) async {
    final notification = NotificationModel(
      id: '',
      userId: entrepreneurId,
      type: NotificationType.offerReceived,
      title: 'Yeni Teklif Aldınız!',
      body:
          'Projeniz için ${amount.toStringAsFixed(0)}₺ tutarında yeni bir teklif aldınız.',
      data: {
        'type': 'offer_received',
        'offerId': offerId,
      },
      isRead: false,
      createdAt: DateTime.now(),
    );

    await _firestoreService.createNotification(notification);
  }

  Future<void> sendOfferAcceptedNotification({
    required String investorId,
    required String offerId,
  }) async {
    final notification = NotificationModel(
      id: '',
      userId: investorId,
      type: NotificationType.offerAccepted,
      title: 'Teklifiniz Kabul Edildi!',
      body: 'Gönderdiğiniz yatırım teklifi kabul edildi.',
      data: {
        'type': 'offer_accepted',
        'offerId': offerId,
      },
      isRead: false,
      createdAt: DateTime.now(),
    );

    await _firestoreService.createNotification(notification);
  }

  Future<void> sendOfferRejectedNotification({
    required String investorId,
    required String offerId,
  }) async {
    final notification = NotificationModel(
      id: '',
      userId: investorId,
      type: NotificationType.offerRejected,
      title: 'Teklifiniz Reddedildi',
      body: 'Gönderdiğiniz yatırım teklifi reddedildi.',
      data: {
        'type': 'offer_rejected',
        'offerId': offerId,
      },
      isRead: false,
      createdAt: DateTime.now(),
    );

    await _firestoreService.createNotification(notification);
  }

  Future<void> sendNewMessageNotification({
    required String receiverId,
    required String offerId,
    required String senderName,
  }) async {
    final notification = NotificationModel(
      id: '',
      userId: receiverId,
      type: NotificationType.newMessage,
      title: 'Yeni Mesaj',
      body: '$senderName size yeni bir mesaj gönderdi.',
      data: {
        'type': 'new_message',
        'offerId': offerId,
      },
      isRead: false,
      createdAt: DateTime.now(),
    );

    await _firestoreService.createNotification(notification);
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }
}