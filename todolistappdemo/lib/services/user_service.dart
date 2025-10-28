import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../constants/api_constants.dart';
import 'auth_service.dart';

class UserService {
  final String _baseUrl = BASE_URL;
  final AuthService _authService = AuthService();

  // Hàm helper để lấy Headers (đã có trong AuthService)
  Future<Map<String, String>> _getAuthHeaders() async {
    // Giả định AuthService có hàm này hoặc tương đương
    final token = await _authService.getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  // Lấy danh sách người dùng (Admin)
  Future<List<AppUser>> getAllUsers() async {
    final headers = await _getAuthHeaders();
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/users'), // Gọi API Admin
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => AppUser.fromJson(json)).toList();
      } else if (response.statusCode == 403 || response.statusCode == 401) {
        throw Exception('Access Denied: Bạn không có quyền Admin.');
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching all users: $e');
      rethrow;
    }
  }

  // ===== HÀM ADMIN MỚI: Cập nhật User =====
  Future<AppUser> updateUser(int userId, String fullName, String email, String? phoneNumber) async {
    final headers = await _getAuthHeaders();
    final body = jsonEncode({
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
    });

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/admin/users/$userId'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return AppUser.fromJson(data);
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes))['message'] ?? 'Lỗi cập nhật người dùng.';
        throw Exception(error);
      }
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }

  // ===== HÀM ADMIN MỚI: Xóa User =====
  Future<void> deleteUser(int userId) async {
    final headers = await _getAuthHeaders();

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/admin/users/$userId'),
        headers: headers,
      );

      if (response.statusCode != 204) {
        final error = jsonDecode(utf8.decode(response.bodyBytes))['message'] ?? 'Lỗi xóa người dùng.';
        throw Exception(error);
      }
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    }
  }

  // ===== HÀM ADMIN MỚI: Gán/Hủy quyền Admin =====
  Future<void> toggleAdminRole(int userId, bool isAdmin) async {
    final headers = await _getAuthHeaders();
    final roleName = "Admin";
    final endpoint = '$_baseUrl/admin/users/$userId/roles/$roleName';

    try {
      final response = isAdmin
          ? await http.post(
          Uri.parse('$_baseUrl/admin/users/$userId/roles'), // Gán quyền
          headers: headers,
          body: jsonEncode({'roleName': roleName})
      )
          : await http.delete(
          Uri.parse(endpoint), // Thu hồi quyền
          headers: headers
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(utf8.decode(response.bodyBytes))['message'] ?? 'Lỗi quản lý quyền.';
        throw Exception(error);
      }
    } catch (e) {
      debugPrint('Error toggling admin role: $e');
      rethrow;
    }
  }
}