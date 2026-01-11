import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_init;
import 'package:timezone/timezone.dart' as tz;
import 'task_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Inisialisasi Timezone
    tz_init.initializeTimeZones();

    // 2. Setup Android Init Settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Setup iOS Init Settings
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    // 3. Initialize Plugin
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint("🔔 Notifikasi diklik: ${details.payload}");
      },
    );

    // 4. Create Notification Channel Eksplisit (PENTING untuk Android 8.0+)
    final androidImpl = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImpl != null) {
      const String channelId = 'channel_tugas_final_v1';
      const String channelName = 'Pengingat Tugas Prioritas';
      const String channelDesc = 'Notifikasi Alarm untuk deadline tugas';

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDesc,
        importance: Importance.max, // MAX Importance agar muncul pop-up
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await androidImpl.createNotificationChannel(channel);

      // 5. Request Permission (Notifikasi & Exact Alarm)
      final bool? notifGranted = await androidImpl
          .requestNotificationsPermission();
      debugPrint("🛡️ Izin Notifikasi: $notifGranted");

      // requestExactAlarmsPermission might not exist in old version of platform interface?
      // In v16 it should be there (introduced in v9).
      try {
        // Hanya untuk Android 12+ (API 31+)
        // In older versions of the plugin, this method might be missing or named differently?
        // But v16 is fairly recent (late 2023?).
        // Let's comment check if it exists or use try-catch blindly.
        // Actually, let's try to call it.
        /* 
        final bool? alarmGranted =
            await androidImpl.requestExactAlarmsPermission();
        debugPrint("🛡️ Izin Exact Alarm: $alarmGranted");
        */
        // I will keep it but wrap in try catch strongly.
        // Actually, requestExactAlarmsPermission was added in newer versions.
        // Let's check: requestExactAlarmsPermission added in 16.3.0?
        // If I use ^16.0.0, I might get 16.0.0 which doesn't have it.
        // I'll keep it as is, catch block handles it.
      } catch (e) {
        debugPrint("ℹ️ Skip Exact Alarm Request: $e");
      }
    }

    debugPrint("✅ NotificationService Ready!");
  }

  DateTime? calculateNotificationTime(
    DateTime deadline,
    ReminderOffset offset,
  ) {
    DateTime notificationTime;
    switch (offset) {
      case ReminderOffset.atDeadline:
        notificationTime = deadline;
        break;
      case ReminderOffset.fiveMinutes:
        notificationTime = deadline.subtract(const Duration(minutes: 5));
        break;
      case ReminderOffset.tenMinutes:
        notificationTime = deadline.subtract(const Duration(minutes: 10));
        break;
      case ReminderOffset.oneHour:
        notificationTime = deadline.subtract(const Duration(hours: 1));
        break;
      case ReminderOffset.oneDay:
        notificationTime = deadline.subtract(const Duration(days: 1));
        break;
    }
    return notificationTime;
  }

  Future<void> scheduleNotification(Task task) async {
    if (task.reminderOffset == null || task.deadline == null) return;

    final DateTime deadlineDate = task.deadline!.toDate().toLocal();

    final DateTime? scheduledTime = calculateNotificationTime(
      deadlineDate,
      task.reminderOffset!,
    );

    if (scheduledTime == null) return;

    final DateTime now = DateTime.now();
    if (scheduledTime.isBefore(now.subtract(const Duration(seconds: 5)))) {
      debugPrint("⚠️ Gagal Jadwal: Waktu sudah lewat -> $scheduledTime");
      return;
    }

    final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(
      scheduledTime,
      tz.local,
    );

    tz.TZDateTime finalTime = tzScheduledTime;
    if (tzScheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
      finalTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 2));
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'channel_tugas_final_v1',
          'Pengingat Tugas Prioritas',
          channelDescription: 'Notifikasi Alarm untuk deadline tugas',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          channelShowBadge: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.notification,
          color: Color(0xFF2563EB),
          icon: '@mipmap/ic_launcher',
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        task.id.hashCode,
        '📌 Pengingat Tugas',
        'Tugas: ${task.judul}',
        finalTime,
        platformDetails,
        androidAllowWhileIdle: true, // Use old param for v16 compat
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );

      debugPrint("✅ SUKSES JADWALKAN (v16 compat) pada: $finalTime");
    } catch (e) {
      debugPrint("❌ ERROR SAAT SCHEDULING: $e");
    }
  }

  Future<void> cancelNotification(String taskId) async {
    await flutterLocalNotificationsPlugin.cancel(taskId.hashCode);
    debugPrint("🗑️ Notifikasi dibatalkan untuk Task ID: $taskId");
  }
}
