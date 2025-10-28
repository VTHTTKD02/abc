// File: lib/services/signalr_service.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../constants/api_constants.dart';
// Import các providers cần thiết
import '../providers/task_provider.dart';
import '../providers/comment_provider.dart'; // <-- 1. THÊM IMPORT COMMENT PROVIDER
import '../providers/project_provider.dart'; // <-- 2. THÊM IMPORT PROJECT PROVIDER
import 'notification_service.dart';

class SignalRService {
  // Singleton
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() {
    return _instance;
  }
  SignalRService._internal();

  HubConnection? _hubConnection;
  BuildContext? _context; // Lưu context để tìm Provider

  String get _hubUrl {
    final baseUrl = BASE_URL.replaceAll("/api", "");
    return "$baseUrl/notificationHub";
  }

  Future<void> init(String token, BuildContext context) async {
    // Lưu context
    _context = context;

    // Chỉ khởi tạo nếu chưa có hoặc đã ngắt kết nối
    if (_hubConnection != null && _hubConnection!.state != HubConnectionState.Disconnected) {
      print("SignalR đã kết nối hoặc đang kết nối.");
      return;
    }

    print("Đang khởi tạo SignalR...");

    _hubConnection = HubConnectionBuilder()
        .withUrl(
      _hubUrl,
      options: HttpConnectionOptions(
        accessTokenFactory: () async => token,
      ),
    )
        .withAutomaticReconnect()
        .build();

    // --- Lắng nghe các sự kiện từ Hub ---

    // 1. Sự kiện cập nhật Task (Đã có)
    _hubConnection!.on("ReceiveTaskUpdate", (arguments) {
      print('SignalR: Nhận được ReceiveTaskUpdate!');
      if (arguments != null && arguments is List && arguments.isNotEmpty) {
        String message = arguments[0] as String;
        // Hiển thị thông báo
        NotificationService().scheduleNotification(
          id: UniqueKey().hashCode,
          title: "Cập nhật công việc",
          body: message,
          scheduledDate: DateTime.now().add(Duration(seconds: 1)),
        );
      }
      // Tải lại danh sách "Công việc của tôi"
      if (_context != null) {
        Provider.of<TaskProvider>(_context!, listen: false)
            .fetchMyTasks(forceRefresh: true);
        // Có thể cần tải lại task của project nếu đang mở màn hình project detail
         //Provider.of<TaskProvider>(_context!, listen: false).fetchTasks(...); // Cần projectId
      }
    });

    // ===== 2. THÊM LISTENER CHO COMMENT MỚI =====
    _hubConnection!.on("ReceiveCommentUpdate", (arguments) {
      print('SignalR: Nhận được ReceiveCommentUpdate!');
      if (arguments != null && arguments is List && arguments.length >= 2) {
        String message = arguments[0] as String;
        int taskId = arguments[1] as int; // Lấy taskId từ backend gửi về

        // Hiển thị thông báo
        NotificationService().scheduleNotification(
          id: UniqueKey().hashCode,
          title: "Bình luận mới",
          body: message, // Message đã có tên người bình luận và tên task
          scheduledDate: DateTime.now().add(Duration(seconds: 1)),
        );

        // Tải lại danh sách comment nếu người dùng đang mở màn hình chi tiết task đó
        if (_context != null) {
          // Kiểm tra xem màn hình TaskDetailScreen có đang mở không và taskId có khớp không
          // (Cách kiểm tra này hơi phức tạp, cách đơn giản là cứ fetch lại)
          Provider.of<CommentProvider>(_context!, listen: false)
              .fetchComments(taskId, forceRefresh: true); // Tải lại comment cho task cụ thể
        }
      } else {
        print('SignalR: ReceiveCommentUpdate có arguments không hợp lệ.');
      }
    });
    // ===========================================

    // ===== 3. THÊM LISTENER CHO PROJECT UPDATE (VD: THÊM THÀNH VIÊN) =====
    _hubConnection!.on("ReceiveProjectUpdate", (arguments) {
      print('SignalR: Nhận được ReceiveProjectUpdate!');
      if (arguments != null && arguments is List && arguments.isNotEmpty) {
        String message = arguments[0] as String;
        // int projectId = arguments[1] as int; // Lấy projectId nếu cần

        // Hiển thị thông báo
        NotificationService().scheduleNotification(
          id: UniqueKey().hashCode,
          title: "Cập nhật dự án",
          body: message, // Ví dụ: "Bạn vừa được thêm vào dự án..."
          scheduledDate: DateTime.now().add(Duration(seconds: 1)),
        );

        // Tải lại danh sách dự án (vì có thể có dự án mới được thêm vào)
        if (_context != null) {
          Provider.of<ProjectProvider>(_context!, listen: false)
              .fetchProjects(forceRefresh: true);
        }
      } else {
        print('SignalR: ReceiveProjectUpdate có arguments không hợp lệ.');
      }
    });
    // ============================================================

    // Bắt đầu kết nối
    try {
      // Đảm bảo dừng kết nối cũ nếu có (tránh lỗi khi reconnect)
      if (_hubConnection!.state == HubConnectionState.Connected) {
        await _hubConnection!.stop();
      }
      await _hubConnection!.start();
      print("SignalR Đã kết nối thành công!");
    } catch (e) {
      print("Lỗi khi kết nối SignalR: $e");
      // Cân nhắc thêm: Xử lý lỗi kết nối, ví dụ thử lại sau vài giây
    }
  }

  // Dừng kết nối (Không đổi)
  Future<void> stop() async {
    if (_hubConnection != null && _hubConnection!.state == HubConnectionState.Connected) {
      await _hubConnection!.stop();
      print("SignalR Đã ngắt kết nối.");
    }
    _hubConnection = null;
    _context = null; // Xóa context
  }
}