// File: lib/providers/auth_provider.dart
import 'dart:async'; // <-- THÊM IMPORT cho Timer
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../services/auth_service.dart';
import '../services/signalr_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  String? _token;
  int? _userId; // <-- THÊM LẠI: Biến lưu User ID
  DateTime? _expiryDate; // <-- THÊM LẠI: Biến lưu ngày hết hạn token
  Timer? _authTimer; // <-- THÊM LẠI: Biến hẹn giờ tự động logout
  bool _isAuthenticated = false;
  String _authMessage = '';

  // Biến lưu thông tin user
  String? _username;
  String? _email;
  String? _fullName;

  // --- Getters ---
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  String get authMessage => _authMessage;
  String? get username => _username;
  String? get email => _email;
  String? get fullName => _fullName;

  AuthProvider() {
    _tryAutoLogin(); // Cố gắng tự động đăng nhập khi khởi tạo
  }

  // ===== CẬP NHẬT HÀM TỰ ĐỘNG ĐĂNG NHẬP =====
  Future<void> _tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('authToken') || !prefs.containsKey('expiryDate')) {
      return; // Không có token hoặc ngày hết hạn -> không tự động đăng nhập
    }

    final storedToken = prefs.getString('authToken');
    final expiryDateString = prefs.getString('expiryDate');

    if (expiryDateString == null) return; // Thiếu dữ liệu

    final expiryDate = DateTime.parse(expiryDateString);

    // Kiểm tra token đã hết hạn chưa
    if (expiryDate.isBefore(DateTime.now())) {
      await logout(); // Hết hạn -> Đăng xuất
      return;
    }

    // Token còn hạn -> Đăng nhập
    _token = storedToken;
    _expiryDate = expiryDate;
    _userId = prefs.getInt('userId'); // Lấy lại userId
    _username = prefs.getString('username');
    _email = prefs.getString('email');
    _fullName = prefs.getString('fullName');
    _isAuthenticated = true;

    _autoLogout(); // Khởi động lại bộ đếm thời gian
    notifyListeners();
    // LƯU Ý: Không thể gọi SignalRService.init() ở đây vì thiếu context.
    // Việc này sẽ được xử lý tại HomeScreen.
  }
  // ===========================================

  // ===== CẬP NHẬT HÀM LOGIN =====
  Future<bool> login(String username, String password, BuildContext context) async {
    final Map<String, dynamic>? loginData = await _authService.loginAndGetData(username, password);

    if (loginData != null && loginData['success'] == true) {
      _token = await _authService.getToken();
      if (_token == null) {
        _authMessage = "Lỗi: Không lấy được token sau khi đăng nhập.";
        notifyListeners();
        return false;
      }

      // Giải mã token để lấy thông tin
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(_token!);
      _expiryDate = DateTime.fromMillisecondsSinceEpoch(decodedToken['exp'] * 1000);

      // Lấy userId từ claim "nameid"
      final userIdClaim = decodedToken['nameid'];
      if (userIdClaim is String) {
        _userId = int.tryParse(userIdClaim);
      } else if (userIdClaim is int) {
        _userId = userIdClaim;
      }

      // Lưu thông tin user
      _email = loginData['email'];
      _fullName = loginData['fullName'];
      _username = loginData['username'];
      _isAuthenticated = true;
      _authMessage = loginData['message'] ?? 'Đăng nhập thành công!';

      // ===== KHỞI ĐỘNG SIGNALR (Đã có) =====
      await SignalRService().init(_token!, context);
      // ====================================

      _autoLogout(); // Bắt đầu hẹn giờ tự động logout
      notifyListeners();

      // Lưu trữ TOÀN BỘ thông tin vào SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('authToken', _token!);
      await prefs.setString('expiryDate', _expiryDate!.toIso8601String());
      await prefs.setInt('userId', _userId ?? 0);
      await prefs.setString('email', _email ?? '');
      await prefs.setString('fullName', _fullName ?? '');
      await prefs.setString('username', _username ?? '');

      return true;
    } else {
      _authMessage = loginData?['message'] ?? 'Tên tài khoản hoặc mật khẩu không đúng.';
      notifyListeners();
      return false;
    }
  }
  // =================================

  // Đăng ký (Không đổi)
  Future<bool> register({
    required String fullName, required String email, required String phoneNumber,
    required String username, required String password, required String confirmPassword,
  }) async {
    // ... (code giữ nguyên) ...
    final result = await _authService.register(
      fullName: fullName, email: email, phoneNumber: phoneNumber,
      username: username, password: password, confirmPassword: confirmPassword,
    );
    _authMessage = result['message'];
    notifyListeners();
    return result['success'];
  }

  // ===== CẬP NHẬT HÀM LOGOUT =====
  Future<void> logout() async {
    if (_authTimer != null) {
      _authTimer!.cancel(); // Hủy bộ đếm giờ
      _authTimer = null;
    }

    await _authService.logout(); // (Hàm này đã bao gồm xóa SharedPreferences)
    _token = null;
    _isAuthenticated = false;
    _username = null;
    _email = null;
    _fullName = null;
    _userId = null;
    _expiryDate = null;

    // ===== DỪNG KẾT NỐI SIGNALR (Đã có) =====
    await SignalRService().stop();
    // ====================================

    notifyListeners();
  }
  // ==================================

  // ===== HÀM HẸN GIỜ TỰ ĐỘNG LOGOUT =====
  void _autoLogout() {
    if (_authTimer != null) {
      _authTimer!.cancel(); // Hủy timer cũ nếu có
    }
    if (_expiryDate == null) return; // Không có ngày hết hạn thì không hẹn giờ

    final timeToExpiry = _expiryDate!.difference(DateTime.now()).inSeconds;
    // Hẹn giờ để gọi hàm logout() khi token hết hạn
    _authTimer = Timer(Duration(seconds: timeToExpiry), logout);
  }
  // ===================================

  // Hàm đổi mật khẩu (Không đổi)
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    // ... (code giữ nguyên) ...
    _authMessage = '';
    final result = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmNewPassword: confirmNewPassword
    );
    _authMessage = result['message'];
    return result['success'];
  }

  // Hàm quên mật khẩu (Không đổi)
  Future<bool> forgotPassword(String email) async {
    // ... (code giữ nguyên) ...
    _authMessage = '';
    notifyListeners();
    final result = await _authService.forgotPassword(email);
    _authMessage = result['message'];
    notifyListeners();
    return result['success'];
  }

  // Hàm đặt lại mật khẩu (Không đổi)
  Future<bool> resetPassword({
    required String email,
    required String token,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    // ... (code giữ nguyên) ...
    _authMessage = '';
    notifyListeners();
    final result = await _authService.resetPassword(
        email: email,
        token: token,
        newPassword: newPassword,
        confirmNewPassword: confirmNewPassword
    );
    _authMessage = result['message'];
    notifyListeners();
    return result['success'];
  }

  // ===== CẬP NHẬT HÀM GETUSERID =====
  // Trả về _userId đã lưu, hiệu quả hơn là giải mã token mỗi lần gọi
  int? getUserId() {
    return _userId;
  }
// ================================
}