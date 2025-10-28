import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

enum UserStatus { Idle, Loading, Success, Error }

class UserProvider with ChangeNotifier {
  final UserService _userService = UserService();

  List<AppUser> _users = [];
  UserStatus _status = UserStatus.Idle;
  String _errorMessage = '';

  List<AppUser> get users => _users;
  UserStatus get status => _status;
  String get errorMessage => _errorMessage;
  // FIX LỖI: Thêm getter isLoading
  bool get isLoading => _status == UserStatus.Loading;


  // Lấy danh sách users (Admin)
  Future<void> fetchUsers() async {
    if (_status == UserStatus.Loading) return;

    _status = UserStatus.Loading;
    notifyListeners();

    try {
      _users = await _userService.getAllUsers();
      _status = UserStatus.Success;
    } catch (e) {
      _status = UserStatus.Error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    notifyListeners();
  }

  // Cập nhật User
  Future<bool> updateUser(int userId, String fullName, String email, String? phoneNumber) async {
    try {
      final updatedUser = await _userService.updateUser(userId, fullName, email, phoneNumber);

      // Cập nhật danh sách cục bộ
      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = updatedUser;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Xóa User
  Future<bool> deleteUser(int userId) async {
    try {
      await _userService.deleteUser(userId);

      _users.removeWhere((u) => u.id == userId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Gán/Hủy quyền Admin
  Future<bool> toggleAdminRole(int userId, bool isAdmin) async {
    try {
      await _userService.toggleAdminRole(userId, isAdmin);

      // Cập nhật roles cục bộ
      final userIndex = _users.indexWhere((u) => u.id == userId);
      if (userIndex != -1) {
        final user = _users[userIndex];
        if (isAdmin) {
          if (!user.roles.contains("Admin")) user.roles.add("Admin");
        } else {
          user.roles.remove("Admin");
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}