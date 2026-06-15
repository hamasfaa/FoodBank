import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'foodbridge_notifications',
        'FoodBridge Notifications',
        description: 'Notifikasi klaim dan aktivitas FoodBridge',
        importance: Importance.high,
      );

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FlutterLocalNotificationsPlugin _localNotifications;

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _notificationSubscription;
  bool _permissionRequested = false;
  String? _listeningUserId;

  NotificationService({
    required FirebaseMessaging messaging,
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required FlutterLocalNotificationsPlugin localNotifications,
  }) : _messaging = messaging,
       _firestore = firestore,
       _auth = auth,
       _localNotifications = localNotifications;

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _localNotifications.initialize(settings: settings);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen(
      _saveTokenForCurrentUser,
    );
  }

  Future<void> syncTokenForUser(String uid) async {
    await _requestPermissionIfNeeded();

    final token = await _messaging.getToken();
    if (token == null) return;

    await _saveToken(uid: uid, token: token);
  }

  Future<void> listenForUserNotifications({
    required String uid,
    required void Function(String title, String body) onNotification,
  }) async {
    if (_listeningUserId == uid && _notificationSubscription != null) return;

    await _notificationSubscription?.cancel();
    _listeningUserId = uid;

    _notificationSubscription = _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: uid)
        .where('deliveredAt', isNull: true)
        .snapshots()
        .listen((snapshot) {
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.removed) continue;

            final data = change.doc.data();
            if (data == null || data['deliveredAt'] != null) continue;

            final title = data['title']?.toString() ?? 'FoodBridge';
            final body = data['body']?.toString() ?? '';
            onNotification(title, body);
            unawaited(showLocalNotification(title: title, body: body));

            unawaited(
              change.doc.reference.set({
                'deliveredAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true)),
            );
          }
        });
  }

  Future<void> _saveTokenForCurrentUser(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _saveToken(uid: uid, token: token);
  }

  Future<void> _saveToken({required String uid, required String token}) async {
    final userRef = _firestore.collection('users').doc(uid);
    final snapshot = await userRef.get();
    if (!snapshot.exists) return;

    await userRef.set({
      'fcmToken': token,
      'fcmTokens': FieldValue.arrayUnion([token]),
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      'notificationsEnabled': true,
    }, SetOptions(merge: true));
  }

  Future<void> _requestPermissionIfNeeded() async {
    if (_permissionRequested) return;

    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _permissionRequested = true;
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'foodbridge_notifications',
          'FoodBridge Notifications',
          channelDescription: 'Notifikasi klaim dan aktivitas FoodBridge',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _notificationSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _notificationSubscription = null;
    _listeningUserId = null;
  }
}
