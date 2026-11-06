import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final xonadoshRetentionNotificationServiceProvider =
    Provider<XonaDoshRetentionNotificationService>((ref) {
      return XonaDoshRetentionNotificationService.instance;
    });

/// XonaDosh faol foydalanuvchilarini ushlab qolish bildirishnomalari servisi.
/// 1. Ro'yxatdan o'tganda xush kelibsiz xabarnomasi:
///    "XonaDosh ga xush kelibsiz! 🏠 Universitet va shahar bo'yicha mos xonadosh toping!"
/// 2. Har kuni 20:00 da yangi e'lonlar va tavsiyalar eslatmasi
/// 3. D+3 va D+7 re-engagement eslatmalari
class XonaDoshRetentionNotificationService {
  XonaDoshRetentionNotificationService._();
  static final XonaDoshRetentionNotificationService instance =
      XonaDoshRetentionNotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  static const String _channelId = 'xonadosh_retention_channel_v1';
  static const String _channelName = 'XonaDosh Eslatmalari';
  static const String _channelDesc =
      'Yangi xonadoshlar, ijara xonalar va talabalar uchun tavsiyalar';

  static const int idWelcome = 9001;
  static const int idDailyHousing = 9002;
  static const int idDay3ReEngagement = 9003;
  static const int idDay7WeeklySummary = 9004;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      await _notificationsPlugin.initialize(initSettings);
      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[XonaDoshRetentionService] Init error: $e');
      }
    }
  }

  Future<bool> requestPermission() async {
    await initialize();
    try {
      if (Platform.isAndroid) {
        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final granted = await androidPlugin?.requestNotificationsPermission();
        return granted ?? false;
      } else if (Platform.isIOS) {
        final iosPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        final granted = await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[XonaDoshRetentionService] Request permission error: $e');
      }
    }
    return false;
  }

  /// 1. Ro'yxatdan o'tganda xush kelibsiz bildirishnomasi
  Future<void> sendWelcomeNotification() async {
    await initialize();
    try {
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(
          '🏠 OTM va shahar bo‘yicha o‘zingizga mos xonadoshni tanlang. Xarita orqali yaqin joylarni ko‘ring yoki o‘z e‘loningizni joylashtiring!',
          contentTitle: '<b>XonaDosh ga xush kelibsiz! 🎉</b>',
          summaryText: 'Xush kelibsiz',
        ),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        idWelcome,
        'XonaDosh ga xush kelibsiz! 🎉',
        '🏠 Universitet atrofidagi mos xonadoshlarni ko‘rib chiqing!',
        details,
        payload: '{"route":"/app"}',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[XonaDoshRetentionService] Welcome push error: $e');
      }
    }
  }

  /// 2. Har kuni soat 20:00 da kunlik yangi takliflar eslatmasi
  Future<void> scheduleDailyEveningReminder() async {
    await initialize();
    try {
      final scheduledDate = _nextInstanceOfTime(20, 0);

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(
          'OTM yaqinida yangi xonadosh va kvartira e‘lonlari chiqdi! 🏠 O‘zingizga ma‘qul variantni tezda band qiling!',
          contentTitle: '<b>Yangi xonadosh takliflari! 🏠</b>',
          summaryText: 'Kunlik tavsiyalar',
        ),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.cancel(idDailyHousing);

      await _notificationsPlugin.zonedSchedule(
        idDailyHousing,
        'Yangi xonadosh takliflari! 🏠',
        'OTM atrofidagi yangi turar-joy e‘lonlarini ko‘ring!',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: '{"route":"/app"}',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[XonaDoshRetentionService] Schedule daily error: $e');
      }
    }
  }

  /// 3. D+3 va D+7 kunlik eslatmalar
  Future<void> scheduleReEngagementReminders() async {
    await initialize();
    try {
      final now = tz.TZDateTime.now(tz.local);

      final day3Date = now.add(const Duration(days: 3));
      final d3Scheduled = tz.TZDateTime(
        tz.local,
        day3Date.year,
        day3Date.month,
        day3Date.day,
        18,
        0,
      );

      final day7Date = now.add(const Duration(days: 7));
      final d7Scheduled = tz.TZDateTime(
        tz.local,
        day7Date.year,
        day7Date.month,
        day7Date.day,
        11,
        30,
      );

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.cancel(idDay3ReEngagement);
      await _notificationsPlugin.zonedSchedule(
        idDay3ReEngagement,
        'Xonadosh izlayapsizmi? 🔍',
        'O‘zingiz yashayotgan xonaga yangi sherik topish uchun bepul e‘lon bering!',
        d3Scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: '{"route":"/app"}',
      );

      await _notificationsPlugin.cancel(idDay7WeeklySummary);
      await _notificationsPlugin.zonedSchedule(
        idDay7WeeklySummary,
        'Haftalik yangi kvartiralar ro‘yxati! 📊',
        'Talabalar uchun arzon va qulay turar joylarni xaritadan toping!',
        d7Scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: '{"route":"/app/map"}',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[XonaDoshRetentionService] Schedule D3/D7 error: $e');
      }
    }
  }

  Future<void> setupAllRetentionHooks() async {
    await scheduleDailyEveningReminder();
    await scheduleReEngagementReminders();
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
