// File: lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class AuthService {

  // ===== HÀM login ĐÃ ĐƯỢC SỬA THÀNH loginAndGetData =====
  Future<Map<String, dynamic>?> loginAndGetData(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/auth/login'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        String token = responseData['token'];
        String responseUsername = responseData['username'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', token);
        await prefs.setString('username', responseUsername);

        responseData['success'] = true;
        return responseData;

      } else {
        responseData['success'] = false;
        responseData['message'] ??= 'Tên tài khoản hoặc mật khẩu không đúng';
        return responseData;
      }
    } catch (e) {
      print('!!! LỖI KẾT NỐI API ĐĂNG NHẬP: $e');
      return {'success': false, 'message': 'Không thể kết nối. (Lỗi: $e)'};
    }
  }
  // =======================================================

  // Hàm Đăng ký (Không đổi)
  Future<Map<String, dynamic>> register({
    required String fullName, required String email, required String phoneNumber,
    required String username, required String password, required String confirmPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/auth/register'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'fullName': fullName, 'email': email, 'phoneNumber': phoneNumber,
          'username': username, 'password': password, 'confirmPassword': confirmPassword,
        }),
      );
      // Sửa decode để xử lý UTF8 nếu cần
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Đăng ký thành công! Vui lòng đăng nhập.'};
      } else {
        if (responseData is List && responseData.isNotEmpty) return {'success': false, 'message': responseData[0]['description']};
        return {'success': false, 'message': responseData['message'] ?? 'Đăng ký thất bại.'};
      }
    } catch (e) {
      print('!!! LỖI KẾT NỐI API ĐĂNG KÝ: $e');
      return {'success': false, 'message': 'Không thể kết nối. (Lỗi: $e)'};
    }
  }

  // Hàm Đăng xuất (Đã cập nhật để xóa thêm email/fullName)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('username');
    await prefs.remove('email');
    await prefs.remove('fullName');
  }

  // Lấy token (Không đổi)
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // ===== HÀM TRỢ GIÚP LẤY TOKEN HEADER (Thêm nếu chưa có) =====
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null) throw Exception('Chưa đăng nhập'); // Ném lỗi nếu không có token
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }
  // =======================================================

  // ===== THÊM HÀM ĐỔI MẬT KHẨU VÀO ĐÂY =====
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      final headers = await _getAuthHeaders(); // Lấy header có token
      final body = jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      });

      final response = await http.post(
        Uri.parse('$BASE_URL/auth/change-password'), // Gọi API đổi mật khẩu
        headers: headers,
        body: body,
      );

      // Sửa decode để xử lý UTF8 nếu cần và lỗi JSON
      Map<String, dynamic> responseData = {};
      String? errorMessage;
      try {
        responseData = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (jsonError){
        // Nếu response không phải JSON (ví dụ lỗi 500 server)
        errorMessage = response.body.isEmpty ? 'Lỗi không xác định từ server' : response.body;
      }


      if (response.statusCode == 200) {
        // Thành công
        return {'success': true, 'message': responseData['message'] ?? 'Đổi mật khẩu thành công!'};
      } else {
        // Lỗi từ server (sai mật khẩu cũ, không khớp,...)
        String finalErrorMessage = 'Đổi mật khẩu thất bại.';
        // Identity trả về lỗi dạng List<ErrorDescription>
        if (responseData is List && responseData.isNotEmpty && responseData[0] is Map && responseData[0].containsKey('description')) {
          finalErrorMessage = responseData[0]['description'] ?? finalErrorMessage;
        } else if (responseData is Map && responseData.containsKey('message')) {
          finalErrorMessage = responseData['message'];
        } else if (responseData is Map && responseData.containsKey('errors')) {
          // Xử lý lỗi validation phức tạp hơn nếu cần
        } else if (errorMessage != null) {
          finalErrorMessage = errorMessage; // Sử dụng lỗi không phải JSON nếu có
        }
        return {'success': false, 'message': finalErrorMessage};
      }
    } catch (e) {
      print('!!! LỖI KẾT NỐI API ĐỔI MẬT KHẨU: $e');
      return {'success': false, 'message': 'Không thể kết nối. (Lỗi: $e)'};
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/auth/forgot-password'), // Gọi API forgot-password
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'email': email}),
      );

      // API này thường trả về 200 OK bất kể email có tồn tại hay không
      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        return {'success': true, 'message': responseData['message'] ?? 'Yêu cầu đã được gửi.'};
      } else {
        // Xử lý các lỗi khác nếu có (ví dụ 400 Bad Request nếu email không hợp lệ)
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        return {'success': false, 'message': responseData['message'] ?? 'Đã xảy ra lỗi.'};
      }
    } catch (e) {
      print('!!! LỖI KẾT NỐI API FORGOT PASSWORD: $e');
      return {'success': false, 'message': 'Không thể kết nối. (Lỗi: $e)'};
    }
  }
  // ===================================

  // ===== THÊM HÀM RESET PASSWORD =====
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String token,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/auth/reset-password'), // Gọi API reset-password
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'email': email,
          'token': token,
          'newPassword': newPassword,
          'confirmNewPassword': confirmNewPassword,
        }),
      );

      final responseData = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        // Thành công
        return {'success': true, 'message': responseData['message'] ?? 'Đặt lại mật khẩu thành công!'};
      } else {
        // Lỗi từ server (token sai, mật khẩu yếu,...)
        String errorMessage = 'Đặt lại mật khẩu thất bại.';
        if (responseData is Map && responseData.containsKey('errors') && responseData['errors'] is List && responseData['errors'].isNotEmpty) {
          // Lấy lỗi đầu tiên từ list errors
          errorMessage = responseData['errors'][0] ?? errorMessage;
        } else if (responseData is Map && responseData.containsKey('message')) {
          errorMessage = responseData['message'];
        }
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      print('!!! LỖI KẾT NỐI API RESET PASSWORD: $e');
      return {'success': false, 'message': 'Không thể kết nối. (Lỗi: $e)'};
    }
  }
}