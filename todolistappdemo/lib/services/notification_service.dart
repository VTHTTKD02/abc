// File: lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io'; // Để kiểm tra nền tảng (Platform)

class NotificationService {
  // Tạo một instance duy nhất (Singleton pattern)
  static final NotificationService _notificationService = NotificationService._internal();
  factory NotificationService() {
    return _notificationService;
  }
  NotificationService._internal();

  // Khởi tạo plugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  /// Khởi tạo service, cài đặt, và yêu cầu quyền
  Future<void> init() async {
    // --- 1. Cài đặt cho Android ---
    // Sử dụng icon app mặc định (thường là @mipmap/ic_launcher)
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // --- 2. Cài đặt cho iOS ---
    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {
        // Xử lý khi nhấn thông báo lúc app đang mở (iOS cũ)
      },
    );

    // --- 3. Gộp cài đặt ---
    final InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // --- 4. Khởi tạo Múi giờ (Quan trọng) ---
    tz.initializeTimeZones();
    try {
      // Đặt múi giờ địa phương (quan trọng)
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    } catch (e) {
      print("Không thể đặt múi giờ: $e");
    }

    // --- 5. Khởi tạo Plugin ---
    await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        // Xử lý khi user nhấn vào thông báo (lúc app đang tắt/chạy nền)
        onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
          final String? payload = notificationResponse.payload;
          if (payload != null) {
            print('NOTIFICATION PAYLOAD: $payload');
            // TODO: Xử lý điều hướng khi nhấn vào thông báo
            // Ví dụ: Mở TaskDetailScreen với TaskId từ payload
          }
        }
    );

    // --- 6. Yêu cầu quyền trên Android 13+ ---
    if (Platform.isAndroid) {
      final bool? androidPermissionGranted = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission(); // Yêu cầu quyền POST_NOTIFICATIONS
      print("Quyền thông báo Android đã được cấp: $androidPermissionGranted");
    }
  }

  /// Lên lịch cho một thông báo
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload, // Dữ liệu đính kèm (ví dụ: "taskId:123")
  }) async {
    // Đảm bảo thời gian hẹn giờ là trong tương lai
    if (scheduledDate.isBefore(DateTime.now().add(Duration(seconds: 1)))) {
      print("Không thể hẹn giờ thông báo trong quá khứ. Thời gian: $scheduledDate");
      // Nếu thời gian quá gần, có thể hẹn sau 1-2 giây
      // scheduledDate = DateTime.now().add(Duration(seconds: 2));
      return; // Bỏ qua nếu đã là quá khứ
    }

    // Chuyển đổi DateTime sang TZDateTime (DateTime có múi giờ)
    final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id, // ID duy nhất của thông báo (dùng TaskId)
      title, // Tiêu đề
      body, // Nội dung
      tzScheduledDate, // Thời gian hiển thị (theo múi giờ)
      const NotificationDetails(
        // Cài đặt chi tiết cho Android
        android: AndroidNotificationDetails(
          'task_due_date_channel_id', // ID của channel
          'Nhắc nhở Công việc', // Tên channel (hiển thị trong cài đặt Android)
          channelDescription: 'Kênh thông báo khi công việc đến hạn.',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
        // Cài đặt chi tiết cho iOS
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime, // Khớp cả ngày và giờ
      payload: payload,
    );
    print("Đã lên lịch thông báo $id lúc $tzScheduledDate");
  }

  /// Hủy một thông báo đã lên lịch
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    print("Đã hủy thông báo $id");
  }

  /// Hủy tất cả thông báo
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    print("Đã hủy TẤT CẢ thông báo");
  }
}