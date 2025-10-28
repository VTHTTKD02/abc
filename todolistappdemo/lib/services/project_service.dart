// File: lib/services/project_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/project_model.dart';

class ProjectService {
  // Hàm trợ giúp lấy Token
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token', // <-- Gửi Token ở đây
    };
  }

  // Hàm gọi API lấy danh sách dự án
  Future<List<Project>> getProjects() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$BASE_URL/projects'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Nếu thành công (200 OK)
        List<dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes)); // Sửa lỗi UTF-8
        // Chuyển đổi List<JSON> thành List<Project>
        return jsonResponse.map((json) => Project.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        // 401 Unauthorized (Token sai hoặc hết hạn)
        throw Exception('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
      } else {
        // Các lỗi khác
        throw Exception('Lỗi khi tải dự án: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Không thể kết nối: $e');
    }
  }

// (Chúng ta sẽ thêm hàm createProject ở đây sau)
  Future<Project> createProject({
    required String name,
    required String description,
    required DateTime startDate,
    DateTime? endDate,
    int? departmentId,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = jsonEncode({
        'projectName': name,
        'description': description,
        'startDate': startDate.toIso8601String(), // Gửi dạng ISO 8601
        'endDate': endDate?.toIso8601String(),
        'departmentId': departmentId,
      });

      final response = await http.post(
        Uri.parse('$BASE_URL/projects'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 201) { // 201 Created
        // API trả về dự án vừa tạo, parse nó
        return Project.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        // Xử lý lỗi
        throw Exception('Lỗi khi tạo dự án: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Không thể kết nối: $e');
    }
  }

}