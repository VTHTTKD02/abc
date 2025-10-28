// File: lib/providers/project_provider.dart
import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../services/project_service.dart';

enum ProjectStatus { Idle, Loading, Success, Error }

class ProjectProvider with ChangeNotifier {
  final ProjectService _projectService = ProjectService();

  List<Project> _projects = [];
  ProjectStatus _status = ProjectStatus.Idle;
  String _errorMessage = '';

  List<Project> get projects => _projects;
  ProjectStatus get status => _status;
  String get errorMessage => _errorMessage;

  // ===== SỬA HÀM NÀY =====
  Future<void> fetchProjects({bool forceRefresh = false}) async { // <-- THÊM {bool forceRefresh = false}
    // Không tải lại nếu đang tải hoặc đã có dữ liệu (trừ khi force)
    if (_status == ProjectStatus.Loading && !forceRefresh) return;
    if (_projects.isNotEmpty && !forceRefresh && _status == ProjectStatus.Success) return; // Chỉ bỏ qua nếu đã thành công trước đó

    _status = ProjectStatus.Loading;
    notifyListeners();

    try {
      _projects = await _projectService.getProjects();
      _status = ProjectStatus.Success;
    } catch (e) {
      _status = ProjectStatus.Error;
      _errorMessage = e.toString();
      // Giữ lại dữ liệu cũ nếu có lỗi khi refresh? (Tùy chọn)
      // if (!forceRefresh) _projects = [];
    }

    notifyListeners();
  }
  // ======================

  Future<bool> createProject({
    required String name,
    required String description,
    required DateTime startDate,
    DateTime? endDate,
    int? departmentId,
  }) async {
    // ... (code không đổi) ...
    try {
      final newProject = await _projectService.createProject(
        name: name,
        description: description,
        startDate: startDate,
        endDate: endDate,
        departmentId: departmentId,
      );
      _projects.insert(0, newProject);
      _status = ProjectStatus.Success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = ProjectStatus.Error;
      notifyListeners();
      return false;
    }
  }
}