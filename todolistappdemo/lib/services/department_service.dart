// File: lib/services/department_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/department_model.dart';

class DepartmentService {
  Future<Map<String, String>> _getAuthHeaders() async {
    // ... (hàm này đã có)
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Department>> getDepartments() async {
    // ... (hàm này đã có)
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$BASE_URL/departments'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonResponse.map((json) => Department.fromJson(json)).toList();
      } else {
        throw Exception('Lỗi khi tải phòng ban: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Không thể kết nối: $e');
    }
  }

  // ===== THÊM HÀM NÀY VÀO =====
  Future<Department> createDepartment(String name, String description) async {
    try {
      final headers = await _getAuthHeaders();
      final body = jsonEncode({
        'departmentName': name,
        'description': description,
      });

      final response = await http.post(
        Uri.parse('$BASE_URL/departments'), // Gọi POST
        headers: headers,
        body: body,
      );

      if (response.statusCode == 201) { // 201 Created
        // API trả về phòng ban vừa tạo
        return Department.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        // Xử lý lỗi (ví dụ: tên trùng)
        final responseData = jsonDecode(response.body);
        throw Exception('Lỗi khi tạo phòng ban: ${responseData['message'] ?? response.statusCode}');
      }
    } catch (e) {
      throw Exception('Không thể kết nối: $e');
    }
  }
}