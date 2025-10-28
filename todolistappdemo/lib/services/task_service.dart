import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/task_model.dart';

class TaskService {
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  // Hàm gọi API lấy danh sách công việc THEO DỰ ÁN
  Future<List<Task>> getTasksByProjectId(int projectId) async {
    try {
      final headers = await _getAuthHeaders();
      // URL gọi API theo project ID
      final response = await http.get(
        Uri.parse('$BASE_URL/tasks/byproject/$projectId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonResponse.map((json) => Task.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Phiên đăng nhập hết hạn.');
      } else {
        throw Exception('Lỗi khi tải công việc: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Không thể kết nối: $e');
    }
  }

// (Chúng ta sẽ thêm hàm createTask ở đây sau)
  Future<Task> createTask({
    required String taskName,
    required String description,
    required int? projectId,
    int status = 0,
    int priority = 1,
    DateTime? dueDate,
    int? assigneeId,
    bool isRecurring = false,
    String? recurrenceRule,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      // Body (API back-end của chúng ta sẽ tự gán ReporterId từ Token)
      final body = jsonEncode({
        'taskName': taskName,
        'description': description,
        'projectId': projectId,
        'status': status,
        'priority': priority,
        'dueDate': dueDate?.toIso8601String(),
        'assigneeId': assigneeId,
        'isRecurring': isRecurring,
        'recurrenceRule': isRecurring ? recurrenceRule : null,
      });

      final response = await http.post(
        Uri.parse('$BASE_URL/tasks'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 201) { // 201 Created
        // API trả về task vừa tạo, parse nó
        return Task.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Lỗi khi tạo công việc: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Không thể kết nối: $e');
    }
  }
  Future<Task> getTaskById(int taskId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$BASE_URL/tasks/$taskId'), // Gọi API GET /api/tasks/{id}
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Task.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Lỗi khi tải chi tiết công việc: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Không thể kết nối: $e');
    }
  }

  // ===== THÊM HÀM NÀY =====
  // Cập nhật 1 task
  Future<Task> updateTask(int taskId, Map<String, dynamic> updates) async {
    try {
      final headers = await _getAuthHeaders();
      final body = jsonEncode(updates);

      final response = await http.put(
        Uri.parse('$BASE_URL/tasks/$taskId'), // Gọi API PUT /api/tasks/{id}
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        return Task.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Lỗi khi cập nhật công việc: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Không thể kết nối: $e');
    }
  }
  Future<List<Task>> getMyTasks() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$BASE_URL/tasks/my'), // Gọi API mới
        headers: headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonResponse.map((json) => Task.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Phiên đăng nhập hết hạn.');
      } else {
        throw Exception('Lỗi khi tải công việc của tôi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Không thể kết nối: $e');
    }
  }
}