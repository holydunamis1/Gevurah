import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/errors/app_error.dart';
import '../core/ports/notification_port.dart';

/// One daily local reminder for the Daily Bout. Nothing leaves the device.
class NotificationService implements NotificationPort {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const int dailyId = 1;
  static const String channelId = 'daily_bout';

  final FlutterLocalNotificationsPlugin _plugin;
  final StreamController<void> _taps = StreamController<void>.broadcast();
  bool _ready = false;

  /// Emits when the player taps the reminder while the app is running.
  Stream<void> get dailyTaps => _taps.stream;

  /// Sets up the plugin and the local time zone. Asks for no permission.
  Future<void> initialize() async {
    if (_ready) {
      return;
    }
    tzdata.initializeTimeZones();
    try {
      final TimezoneInfo info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } on Object {
      // Keep UTC if the zone cannot be read; the reminder is then a little off.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) => _taps.add(null),
    );
    _ready = true;
  }

  /// True when the app was opened by tapping the reminder.
  Future<bool> launchedFromNotification() async {
    final NotificationAppLaunchDetails? details = await _plugin.getNotificationAppLaunchDetails();
    return details?.didNotificationLaunchApp ?? false;
  }

  /// The next time the clock shows [minuteOfDay] (minutes after midnight),
  /// strictly after [now].
  static tz.TZDateTime nextOccurrence(tz.TZDateTime now, int minuteOfDay) {
    final tz.TZDateTime today = tz.TZDateTime(now.location, now.year, now.month, now.day, minuteOfDay ~/ 60, minuteOfDay % 60);
    return today.isAfter(now) ? today : tz.TZDateTime(now.location, now.year, now.month, now.day + 1, minuteOfDay ~/ 60, minuteOfDay % 60);
  }

  @override
  Future<bool> permissionGranted() async {
    await initialize();
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled() ??
          false;
    }
    if (Platform.isIOS) {
      final NotificationsEnabledOptions? options =
          await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.checkPermissions();
      return options?.isEnabled ?? false;
    }
    return false;
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          false;
    }
    if (Platform.isIOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    return false;
  }

  @override
  Future<void> scheduleDaily({required int minuteOfDay, required String title, required String body}) async {
    await initialize();
    if (minuteOfDay < 0 || minuteOfDay >= 24 * 60) {
      throw const UserRecoverableError('The reminder time is not valid');
    }
    if (!await permissionGranted()) {
      throw const UserRecoverableError('Notifications are not allowed for this app');
    }
    try {
      await _plugin.cancel(id: dailyId);
      await _plugin.zonedSchedule(
        id: dailyId,
        title: title,
        body: body,
        scheduledDate: nextOccurrence(tz.TZDateTime.now(tz.local), minuteOfDay),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            'Daily Bout reminder',
            channelDescription: 'One reminder a day for the Daily Bout',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } on Object catch (e) {
      throw ThirdPartyError('Could not schedule the reminder', cause: e);
    }
  }

  @override
  Future<void> cancelDaily() async {
    await initialize();
    try {
      await _plugin.cancel(id: dailyId);
    } on Object catch (e) {
      throw ThirdPartyError('Could not cancel the reminder', cause: e);
    }
  }
}
