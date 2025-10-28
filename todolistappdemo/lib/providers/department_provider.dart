// File: lib/providers/department_provider.dart
import 'package:flutter/material.dart';
import '../models/department_model.dart';
import '../services/department_service.dart';

class DepartmentProvider with ChangeNotifier {
  final DepartmentService _departmentService = DepartmentService();

  List<Department> _departments = [];
  bool _isLoading = false;
  String _errorMessage = ''; // Thêm biến lưu lỗi

  List<Department> get departments => _departments;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage; // Thêm getter

  Future<void> fetchDepartments({bool forceRefresh = false}) async { // Thêm forceRefresh
    // Chỉ tải 1 lần trừ khi bắt buộc tải lại
    if (_departments.isNotEmpty && !forceRefresh) return;

    _isLoading = true;
    notifyListeners();
    try {
      _departments = await _departmentService.getDepartments();
      _errorMessage = ''; // Xóa lỗi cũ nếu thành công
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ===== THÊM HÀM NÀY VÀO =====
  Future<bool> createDepartment(String name, String description) async {
    _isLoading = true; // Có thể thêm trạng thái loading riêng
    _errorMessage = ''; // Xóa lỗi cũ
    notifyListeners();

    try {
      final newDepartment = await _departmentService.createDepartment(name, description);
      // Thêm phòng ban mới vào đầu danh sách
      _departments.insert(0, newDepartment);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}