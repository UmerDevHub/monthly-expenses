import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final ValueNotifier<String?> selectNotificationPayload = ValueNotifier(null);

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        if (details.payload != null) {
          selectNotificationPayload.value = details.payload;
        }
      },
    );
  }

  static Future<void> scheduleMonthlyNotification({
    required String id,
    required String title,
    required String body,
    required int dueDay,
    required String categoryId,
    required double amount,
  }) async {
    final int notificationId = id.hashCode;
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final tz.TZDateTime scheduledDate = _nextInstanceOfDay(now.year, now.month, dueDay);

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'fixed_expenses_channel',
          'Fixed Expenses Notifications',
          channelDescription: 'Notifications for due and overdue recurring expenses',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      payload: '$categoryId,$amount',
    );
  }

  static tz.TZDateTime _nextInstanceOfDay(int year, int month, int dueDay) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    
    int daysInMonth = _getDaysInMonth(year, month);
    int day = dueDay > daysInMonth ? daysInMonth : dueDay;

    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, year, month, day, 9, 0);

    if (scheduledDate.isBefore(now)) {
      int nextMonth = month + 1;
      int nextYear = year;
      if (nextMonth > 12) {
        nextMonth = 1;
        nextYear++;
      }
      int nextDaysInMonth = _getDaysInMonth(nextYear, nextMonth);
      int nextDay = dueDay > nextDaysInMonth ? nextDaysInMonth : dueDay;
      scheduledDate = tz.TZDateTime(tz.local, nextYear, nextMonth, nextDay, 9, 0);
    }
    return scheduledDate;
  }

  static int _getDaysInMonth(int year, int month) {
    if (month == 2) {
      final bool isLeapYear = (year % 4 == 0) && (year % 100 != 0 || year % 400 == 0);
      return isLeapYear ? 29 : 28;
    }
    const List<int> daysInMonths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return daysInMonths[month - 1];
  }

  static Future<void> cancelNotification(String id) async {
    await _notificationsPlugin.cancel(id.hashCode);
  }
}
