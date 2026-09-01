import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/utils/push_token_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Program-start reminders for the channel guide.
///
/// Future server-side FCM campaigns can use the cached FCM token
/// (`SharedPreferences` key `fcm_token_cache`). Per-program start alerts are
/// scheduled on-device with [FlutterLocalNotificationsPlugin] because FCM
/// cannot schedule a one-shot future delivery from the client without a backend.
class ScheduleReminderService extends GetxService {
  ScheduleReminderService();

  static const _prefsReminders = 'channel_schedule_reminders_v1';
  static const _androidChannelId = 'channel_schedule_reminders';
  static const _androidChannelName = 'Program start reminders';

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  /// Persisted upcoming reminders (used for bell state and reboot reschedule).
  final RxList<Map<String, dynamic>> reminders = <Map<String, dynamic>>[].obs;

  static Future<ScheduleReminderService> create() async {
    final s = ScheduleReminderService();
    await s._init();
    return s;
  }

  bool isScheduled(String programId) =>
      reminders.any((m) => m['programId'] == programId);

  Future<void> toggleReminder({
    required String programId,
    required DateTime startUtc,
    required String programTitle,
    required String channelTitle,
  }) async {
    if (isScheduled(programId)) {
      await cancelReminder(programId);
      Get.snackbar('Reminder off', 'You will not be notified for this program.');
      return;
    }
    final now = DateTime.now().toUtc();
    if (!startUtc.toUtc().isAfter(now.add(const Duration(seconds: 3)))) {
      Get.snackbar(
        'Cannot remind',
        'This program has already started or is starting now.',
      );
      return;
    }
    final entry = <String, dynamic>{
      'programId': programId,
      'start': startUtc.toUtc().toIso8601String(),
      'programTitle': programTitle,
      'channelTitle': channelTitle,
    };
    await _scheduleNotificationForEntry(entry);
    reminders.add(entry);
    await _persistReminders();
    Get.snackbar(
      'Reminder set',
      'You will be notified when "$programTitle" starts.',
    );
  }

  Future<void> cancelReminder(String programId) async {
    await _local.cancel(_notificationId(programId));
    reminders.removeWhere((m) => m['programId'] == programId);
    await _persistReminders();
  }

  Future<void> _init() async {
    tzdata.initializeTimeZones();
    await _initLocalTimezone();
    await _initLocalNotifications();
    await _bootstrapFromPrefs();
    await _initFirebaseMessaging();
  }

  Future<void> _initLocalTimezone() async {
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e, st) {
      debugPrint('ScheduleReminderService: timezone $e\n$st');
      tz.setLocalLocation(tz.UTC);
    }
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    final androidImpl =
        _local.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.requestNotificationsPermission();
      const channel = AndroidNotificationChannel(
        _androidChannelId,
        _androidChannelName,
        description:
            'Alerts when a program you chose from the channel guide is starting.',
        importance: Importance.high,
      );
      await androidImpl.createNotificationChannel(channel);
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _local
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> _bootstrapFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsReminders);
    if (raw == null || raw.isEmpty) {
      reminders.clear();
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return;
      final now = DateTime.now().toUtc();
      final valid = <Map<String, dynamic>>[];
      for (final e in decoded) {
        if (e is! Map<String, dynamic>) continue;
        final start = DateTime.tryParse(e['start']?.toString() ?? '');
        if (start == null) continue;
        if (!start.toUtc().isAfter(now.add(const Duration(seconds: 3)))) {
          continue;
        }
        valid.add(Map<String, dynamic>.from(e));
      }
      reminders.assignAll(valid);
      for (final m in valid) {
        await _scheduleNotificationForEntry(m);
      }
      await _persistReminders();
    } catch (e, st) {
      debugPrint('ScheduleReminderService bootstrap: $e\n$st');
      reminders.clear();
      await prefs.remove(_prefsReminders);
    }
  }

  Future<void> _persistReminders() async {
    final prefs = await SharedPreferences.getInstance();
    if (reminders.isEmpty) {
      await prefs.remove(_prefsReminders);
      return;
    }
    await prefs.setString(_prefsReminders, jsonEncode(reminders.toList()));
  }

  Future<void> _scheduleNotificationForEntry(Map<String, dynamic> m) async {
    final programId = m['programId'] as String? ?? '';
    if (programId.isEmpty) return;
    final start = DateTime.tryParse(m['start']?.toString() ?? '');
    if (start == null) return;
    final programTitle = m['programTitle']?.toString() ?? 'Program';
    final channelTitle = m['channelTitle']?.toString() ?? 'Channel';

    final when = tz.TZDateTime.from(start.toUtc(), tz.local);
    if (!when.isAfter(tz.TZDateTime.now(tz.local))) return;

    final id = _notificationId(programId);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        channelDescription:
            'Alerts when a program you chose from the channel guide is starting.',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'Program reminder',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _local.zonedSchedule(
      id,
      'Starting now: $programTitle',
      channelTitle,
      when,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: programId,
    );
  }

  Future<void> _initFirebaseMessaging() async {
    if (kIsWeb) return;

    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e, st) {
      debugPrint('ScheduleReminderService FCM permission: $e\n$st');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint(
        '[FCM foreground] id=${message.messageId} '
        'hasNotification=${message.notification != null} data=${message.data}',
      );
      final n = message.notification;
      if (n == null) {
        debugPrint(
          '[FCM foreground] no tray/local display: payload had no '
          '"notification" block (data-only). Add notification title/body in '
          'Firebase test or handle data in code.',
        );
        return;
      }
      await _local.show(
        message.hashCode & 0x7fffffff,
        n.title,
        n.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannelId,
            _androidChannelName,
            channelDescription:
                'Push messages from your provider (e.g. schedule updates).',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    });

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        debugPrint('[FCM] token acquired (${token.length} chars) — use in Firebase test');
        await cacheFcmToken(token);
      } else {
        debugPrint('[FCM] getToken returned null');
      }
    } catch (e, st) {
      debugPrint('ScheduleReminderService getToken: $e\n$st');
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
      await cacheFcmToken(t);
    });
  }

  static int _notificationId(String programId) {
    const fnvPrime = 0x01000193;
    var h = 0x811c9dc5;
    for (final u in programId.codeUnits) {
      h ^= u;
      h = (h * fnvPrime) & 0x7fffffff;
    }
    if (h == 0) h = 1;
    return h;
  }
}
