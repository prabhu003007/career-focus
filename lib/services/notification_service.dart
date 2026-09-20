import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance =
      NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _dailyNotificationBaseId = 5000;

  static const String _channelId = 'career_focus_daily_study';
  static const String _channelName = 'Daily Study Reminders';
  static const String _channelDescription =
      'Daily reminders for planned Career Focus study topics.';

  Future<void> initialize() async {
    tz.initializeTimeZones();

    try {
      final timezoneInfo =
          await FlutterTimezone.getLocalTimezone();

      tz.setLocalLocation(
        tz.getLocation(timezoneInfo.identifier),
      );
    } catch (error) {
      debugPrint('Timezone detection failed: $error');

      tz.setLocalLocation(
        tz.getLocation('Asia/Kolkata'),
      );
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const windowsSettings =
        WindowsInitializationSettings(
      appName: 'Career Focus',
      appUserModelId: 'com.careerfocus.app',
      guid: '7e7e7d91-75b7-4e3e-9d40-6f2f3f4e7b21',
    );

    const initializationSettings =
        InitializationSettings(
      android: androidSettings,
      windows: windowsSettings,
    );

    await _plugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse:
          _onNotificationResponse,
    );

    await _createAndroidChannel();

    await requestPermissions();
  }

  Future<void> _createAndroidChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(channel);
  }

  Future<void> requestPermissions() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  void _onNotificationResponse(
    NotificationResponse response,
  ) {
    debugPrint(
      'Career Focus notification opened: ${response.payload}',
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> cancelDate(DateTime date) async {
    final id = _notificationIdForDate(date);

    await _plugin.cancel(
      id: id,
    );
  }

  int _notificationIdForDate(DateTime date) {
    final normalized =
        DateTime(date.year, date.month, date.day);

    final epochDay =
        normalized.difference(
          DateTime(2020, 1, 1),
        ).inDays;

    return _dailyNotificationBaseId + epochDay;
  }

  Future<void> scheduleStudyDay({
    required DateTime date,
    required String title,
    required String body,
    String? payload,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    final scheduled = tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      8,
      0,
    );

    if (!scheduled.isAfter(now)) {
      return;
    }

    final id = _notificationIdForDate(date);

    const androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const windowsDetails =
        WindowsNotificationDetails();

    const details =
        NotificationDetails(
      android: androidDetails,
      windows: windowsDetails,
    );

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode:
          AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> scheduleFromAssignments({
    required List<dynamic> assignments,
  }) async {
    await cancelAll();

    final grouped =
        <String, List<dynamic>>{};

    for (final assignment in assignments) {
      if (assignment is! Map) {
        continue;
      }

      final status =
          assignment['status']?.toString();

      if (status != 'planned') {
        continue;
      }

      final date =
          assignment['date']?.toString();

      if (date == null || date.isEmpty) {
        continue;
      }

      grouped
          .putIfAbsent(date, () => [])
          .add(assignment);
    }

    for (final entry in grouped.entries) {
      final date =
          DateTime.tryParse(entry.key);

      if (date == null) {
        continue;
      }

      final count = entry.value.length;

      final topicNames = entry.value
          .map(
            (item) =>
                item['topicName']?.toString(),
          )
          .where(
            (name) =>
                name != null &&
                name.isNotEmpty,
          )
          .toList();

      String body;

      if (topicNames.isNotEmpty) {
        body =
            '$count topic${count == 1 ? '' : 's'} planned: '
            '${topicNames.take(3).join(', ')}'
            '${topicNames.length > 3 ? ' and more.' : '.'}';
      } else {
        body =
            '$count topic${count == 1 ? '' : 's'} '
            'planned for today.';
      }

      await scheduleStudyDay(
        date: date,
        title: 'Career Focus — Study Day',
        body: body,
        payload: 'schedule:${entry.key}',
      );
    }
  }
}