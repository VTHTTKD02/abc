// File: lib/providers/comment_provider.dart
import 'package:flutter/material.dart';
// Bỏ các import signalr_netcore không dùng ở đây
// import 'package:signalr_netcore/http_connection_options.dart';
// import 'package:signalr_netcore/hub_connection.dart';
// import 'package:signalr_netcore/hub_connection_builder.dart';
// import 'package:signalr_netcore/itransport.dart';
import '../models/comment_model.dart';
import '../services/comment_service.dart';
// import '../constants/api_constants.dart'; // Không cần BASE_URL ở đây nữa

enum CommentStatus { Idle, Loading, Success, Error }

class CommentProvider with ChangeNotifier {
  final CommentService _commentService = CommentService();

  Map<int, List<Comment>> _commentsByTask = {};
  CommentStatus _status = CommentStatus.Idle;
  String _errorMessage = '';

  // Bỏ phần SignalR Hub Connection ra khỏi Provider này
  // HubConnection? _hubConnection;

  // ===== Getters =====
  List<Comment> commentsForTask(int taskId) => _commentsByTask[taskId] ?? [];
  CommentStatus get status => _status;
  String get errorMessage => _errorMessage;

  // Bỏ các hàm liên quan đến SignalR Hub (initSignalR, disposeSignalR, _handleCommentRealtime)
  // Việc kết nối và lắng nghe nên được quản lý tập trung ở SignalRService

  // ===== CRUD =====

  // ===== SỬA HÀM NÀY =====
  Future<void> fetchComments(int taskId, {bool forceRefresh = false}) async { // <-- THÊM {bool forceRefresh = false}
    // Không tải lại nếu đang tải (trừ khi force)
    if (_status == CommentStatus.Loading && !forceRefresh) return;
    // Không tải lại nếu đã có dữ liệu và không force, và đã thành công trước đó
    if (_commentsByTask.containsKey(taskId) && !forceRefresh && _status == CommentStatus.Success) return;

    // Chỉ set Loading nếu thực sự fetch (không phải bị chặn bởi các điều kiện trên)
    _status = CommentStatus.Loading;
    notifyListeners();
    try {
      final comments = await _commentService.getComments(taskId);
      _commentsByTask[taskId] = comments;
      _status = CommentStatus.Success;
      _errorMessage = '';
    } catch (e) {
      _status = CommentStatus.Error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      // Giữ lại dữ liệu cũ nếu có lỗi khi refresh? (Tùy chọn)
      // if (!forceRefresh && _commentsByTask.containsKey(taskId)) {
      //   // Giữ nguyên _commentsByTask[taskId]
      // } else {
      //   _commentsByTask.remove(taskId);
      // }
    }
    // Chỉ notify nếu state thay đổi (tránh trường hợp bị chặn return sớm)
    if(mounted) { // Kiểm tra provider còn tồn tại không
      notifyListeners();
    }
  }
  // ======================

  Future<bool> createComment(int taskId, String content) async {
    _errorMessage = '';
    // Không cần set status Loading ở đây vì UI không trực tiếp chờ hàm này xong
    try {
      // Chỉ gọi API, không cập nhật state cục bộ
      await _commentService.createComment(taskId, content);
      // SignalRService sẽ nhận thông báo và trigger fetchComments -> tự động cập nhật UI và state
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners(); // Thông báo lỗi nếu có
      return false;
    }
  }

  Future<bool> updateComment(int taskId, int commentId, String content) async {
    _errorMessage = '';
    try {
      final updatedComment =
      await _commentService.updateComment(taskId, commentId, content);
      // Cập nhật state cục bộ ngay lập tức để UI mượt hơn
      if (_commentsByTask.containsKey(taskId)) {
        final index = _commentsByTask[taskId]!
            .indexWhere((c) => c.commentId == commentId);
        if (index != -1) {
          _commentsByTask[taskId]![index] = updatedComment;
          if(mounted) notifyListeners(); // Cập nhật ngay
        }
      }
      // SignalR cũng có thể trigger fetch lại (tùy logic backend)
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      if(mounted) notifyListeners();
      return false;
    }
  }

  Future<bool> deleteComment(int taskId, int commentId) async {
    _errorMessage = '';
    try {
      bool success = await _commentService.deleteComment(taskId, commentId);
      // Cập nhật state cục bộ ngay lập tức
      if (success && _commentsByTask.containsKey(taskId)) {
        _commentsByTask[taskId]!.removeWhere((c) => c.commentId == commentId);
        if(mounted) notifyListeners(); // Cập nhật ngay
      }
      // SignalR cũng có thể trigger fetch lại (tùy logic backend)
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      if(mounted) notifyListeners();
      return false;
    }
  }

  void clearComments(int taskId) {
    _commentsByTask.remove(taskId);
    _status = CommentStatus.Idle;
    _errorMessage = '';
    // Không cần notifyListeners() nếu chỉ gọi khi đóng màn hình
  }

  // Thêm biến kiểm tra mounted để tránh lỗi khi notifyListeners sau khi provider bị dispose
  bool _mounted = true;

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  // Ghi đè notifyListeners để kiểm tra _mounted
  @override
  void notifyListeners() {
    if (_mounted) {
      super.notifyListeners();
    }
  }

  bool get mounted => _mounted; // Getter cho mounted nếu cần
}