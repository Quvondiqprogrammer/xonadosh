import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../firebase_options.dart';

final fcmServiceProvider = Provider<XonaDoshFcmService>((ref) {
  return XonaDoshFcmService.instance;
});

@pragma('vm:entry-point')
Future<void> xonadoshFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    print(
      '[XonaDosh FCM Background] Title: ${message.notification?.title}, Body: ${message.notification?.body}',
    );
  }
}

class XonaDoshFcmService {
  XonaDoshFcmService._();
  static final XonaDoshFcmService instance = XonaDoshFcmService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'xonadosh_fcm_channel',
    'XonaDosh Xabarlari',
    description: 'XonaDosh yangi xonadoshlar, xabarlar va bildirishnomalar',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 1. Notification permissions
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (kDebugMode) {
        print(
          '[XonaDosh FCM] Authorization status: ${settings.authorizationStatus}',
        );
      }

      // 2. Local notification channel for Android foreground
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);

      // Foreground notification presentation options (iOS)
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Get FCM Token
      _fcmToken = await _fcm.getToken();
      if (kDebugMode) {
        print('[XonaDosh FCM] Token: $_fcmToken');
      }

      _fcm.onTokenRefresh.listen((token) {
        _fcmToken = token;
        if (kDebugMode) {
          print('[XonaDosh FCM] Token refreshed: $token');
        }
      });

      // 4. Listen foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        final android = message.notification?.android;

        if (notification != null && !kIsWeb) {
          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                channelDescription: _channel.description,
                icon: android?.smallIcon ?? '@mipmap/ic_launcher',
                importance: Importance.high,
                priority: Priority.high,
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
          );
        }
      });

      // 5. App opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('[XonaDosh FCM] App opened from message: ${message.data}');
        }
      });

      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('[XonaDosh FCM] Init error: $e');
      }
    }
  }
}
