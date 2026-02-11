import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const int _dailyReviewNotificationId = 2000;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    tz.initializeTimeZones();
    await _configureLocalTimezone();

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/launcher_icon'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _notificationsPlugin.initialize(settings: initializationSettings);
    await _requestPermissions();
    _initialized = true;
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      // App primarily targets Vietnam users; fallback keeps 20:00 local reminder usable.
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    }
  }

  Future<void> _requestPermissions() async {
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();

    final iosImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Schedule notification at 20:00 (8 PM) every evening
  Future<void> scheduleDailyReviewReminder() async {
    if (kIsWeb) return;
    if (!_initialized) {
      await initialize();
    }

    final now = tz.TZDateTime.now(tz.local);
    var next8Pm = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20);
    if (next8Pm.isBefore(now)) {
      next8Pm = next8Pm.add(const Duration(days: 1));
    }

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_review_channel',
        'Daily Review Reminder',
        channelDescription: 'Nhắc ôn bài mỗi 8h tối mỗi ngày',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.zonedSchedule(
      id: _dailyReviewNotificationId,
      title: 'Đến giờ ôn bài rồi',
      body: 'Mở app để ôn bài bạn nhé!',
      scheduledDate: next8Pm,
      notificationDetails: notificationDetails,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Test notification - hiển thị ngay lập tức để kiểm tra
  Future<void> showTestNotification() async {
    if (kIsWeb) return;
    if (!_initialized) {
      await initialize();
    }

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_review_channel',
        'Daily Review Reminder',
        channelDescription: 'Nhắc ôn bài mỗi 8h tối mỗi ngày',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id: _dailyReviewNotificationId + 1,
      title: 'Test thông báo',
      body: 'Thông báo đẩy đang hoạt động! Bạn sẽ nhận nhắc lúc 20:00 mỗi tối.',
      notificationDetails: notificationDetails,
    );
  }
}
