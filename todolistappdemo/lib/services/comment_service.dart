// File: lib/services/comment_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/comment_model.dart'; // Import model comment

class CommentService {
  // Hàm trợ giúp lấy Header (giống các service khác)
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null) throw Exception('Chưa đăng nhập');
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  // Lấy bình luận theo Task ID
  Future<List<Comment>> getComments(int taskId) async {
    try {
      final headers = await _getAuthHeaders();
      // Gọi API GET /api/tasks/{taskId}/comments
      final response = await http.get(
        Uri.parse('$BASE_URL/tasks/$taskId/comments'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonResponse.map((json) => Comment.fromJson(json)).toList();
      } else {
        throw Exception('Lỗi khi tải bình luận: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Không thể kết nối: $e');
    }
  }

  // Tạo bình luận mới
  Future<Comment> createComment(int taskId, String content) async {
    try {
      final headers = await _getAuthHeaders();
      final body = jsonEncode({'content': content});

      // Gọi API POST /api/tasks/{taskId}/comments
      final response = await http.post(
        Uri.parse('$BASE_URL/tasks/$taskId/comments'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) { // API có thể trả về 200 hoặc 201
        // API trả về comment vừa tạo
        return Comment.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception('Lỗi khi tạo bình luận: ${responseData['message'] ?? response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
  Future<Comment> updateComment(int taskId, int commentId, String content) async {
    try {
      final headers = await _getAuthHeaders();
      final body = jsonEncode({'content': content});

      // Gọi API PUT /api/tasks/{taskId}/comments/{commentId}
      final response = await http.put(
        Uri.parse('$BASE_URL/tasks/$taskId/comments/$commentId'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        // API trả về comment đã cập nhật
        return Comment.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception('Lỗi khi sửa bình luận: ${responseData['message'] ?? response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
  // ===================================

  // ===== THÊM HÀM DELETE COMMENT =====
  Future<bool> deleteComment(int taskId, int commentId) async {
    try {
      final headers = await _getAuthHeaders();

      // Gọi API DELETE /api/tasks/{taskId}/comments/{commentId}
      final response = await http.delete(
        Uri.parse('$BASE_URL/tasks/$taskId/comments/$commentId'),
        headers: headers,
      );

      // API trả về 204 No Content nếu thành công
      if (response.statusCode == 204) {
        return true;
      } else if (response.statusCode == 403) {
        throw Exception('Bạn không có quyền xóa bình luận này.');
      } else if (response.statusCode == 404) {
        throw Exception('Không tìm thấy bình luận để xóa.');
      }
      else {
        throw Exception('Lỗi khi xóa bình luận: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}