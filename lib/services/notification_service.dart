import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('[FCM] Background message: ${message.messageId}');
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'eduflow_high_importance',
    'EduFlow Notifications',
    description: 'Course and enrollment notifications',
    importance: Importance.high,
  );

  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('[NotificationService] Notification tapped: ${response.payload}');
      },
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    });
  }

  static Future<void> saveTokenToFirestore(String uid) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'fcmToken': token});

      _messaging.onTokenRefresh.listen((newToken) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'fcmToken': newToken});
      });
    } catch (e) {
      print('[NotificationService] saveToken error: $e');
    }
  }

  static Future<void> notifyNewCourse({
    required String courseTitle,
    required String instructorName,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      final tokens = snapshot.docs
          .map((d) => d.data()['fcmToken'] as String?)
          .whereType<String>()
          .toList();

      await FirebaseFirestore.instance.collection('notifications').add({
        'type': 'new_course',
        'title': '📚 New Course Available!',
        'body': '$instructorName just published "$courseTitle"',
        'tokens': tokens,
        'createdAt': FieldValue.serverTimestamp(),
        'sent': false,
      });
    } catch (e) {
      print('[NotificationService] notifyNewCourse error: $e');
    }
  }

  static Future<void> notifyTeacherEnrollment({
    required String courseId,
    required String studentName,
    required String courseTitle,
  }) async {
    try {
      final courseDoc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .get();

      if (!courseDoc.exists) return;
      final instructorName =
          courseDoc.data()?['instructorName'] as String?;
      if (instructorName == null) return;

      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isEqualTo: instructorName)
          .where('role', isEqualTo: 'teacher')
          .limit(1)
          .get();

      if (userSnap.docs.isEmpty) return;
      final token =
          userSnap.docs.first.data()['fcmToken'] as String?;
      if (token == null) return;

      await FirebaseFirestore.instance.collection('notifications').add({
        'type': 'new_enrollment',
        'title': '🎉 New Student Enrolled!',
        'body': '$studentName enrolled in "$courseTitle"',
        'tokens': [token],
        'createdAt': FieldValue.serverTimestamp(),
        'sent': false,
      });
    } catch (e) {
      print('[NotificationService] notifyTeacherEnrollment error: $e');
    }
  }
}
