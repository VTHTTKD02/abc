// File: lib/services/project_member_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/user_model.dart'; // Import AppUser

class ProjectMemberService {
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  // Lấy danh sách thành viên của dự án
  Future<List<AppUser>> getProjectMembers(int projectId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        // Gọi API lồng nhau
        Uri.parse('$BASE_URL/projects/$projectId/members'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonResponse.map((json) => AppUser.fromJson(json)).toList();
      } else {
        throw Exception('Lỗi khi tải thành viên: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Không thể kết nối: $e');
    }
  }

  // Thêm thành viên vào dự án bằng Email
  Future<AppUser> addMemberByEmail(int projectId, String email) async {
    try {
      final headers = await _getAuthHeaders();
      final body = jsonEncode({
        'email': email,
      });

      final response = await http.post(
        Uri.parse('$BASE_URL/projects/$projectId/members'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) { // API trả về 200 OK
        // API trả về thành viên vừa thêm
        return AppUser.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception('Lỗi khi thêm thành viên: ${responseData['message'] ?? response.statusCode}');
      }
    } catch (e) {
      // Ném lại lỗi để Provider bắt
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
  Future<bool> removeMember(int projectId, int userId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        // Gọi API DELETE
        Uri.parse('$BASE_URL/projects/$projectId/members/$userId'),
        headers: headers,
      );

      // API trả về 204 No Content nếu thành công
      if (response.statusCode == 204) {
        return true;
      } else if (response.statusCode == 404) { // Not Found
        throw Exception('Thành viên không tồn tại trong dự án.');
      }
      else {
        throw Exception('Lỗi khi xóa thành viên: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}