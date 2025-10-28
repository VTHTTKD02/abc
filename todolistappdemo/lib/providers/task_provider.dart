import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

// Trạng thái tải task
enum TaskStatus { Idle, Loading, Success, Error }

class TaskProvider with ChangeNotifier {
  final TaskService _taskService = TaskService();

  // State cho danh sách task theo Project
  Map<int, List<Task>> _tasksByProject = {};
  TaskStatus _status = TaskStatus.Idle; // Trạng thái cho list theo project
  String _errorMessage = ''; // Lỗi chung

  // State cho task chi tiết
  Task? _currentTask;
  TaskStatus _detailStatus = TaskStatus.Idle; // Trạng thái cho tải chi tiết

  // ===== 1. THÊM STATE CHO MY TASKS =====
  List<Task> _myTasks = [];
  TaskStatus _myTasksStatus = TaskStatus.Idle; // Trạng thái riêng cho My Tasks

  // --- Getters ---
  List<Task> tasksForProject(int projectId) => _tasksByProject[projectId] ?? [];
  TaskStatus get status => _status;
  String get errorMessage => _errorMessage;

  Task? get currentTask => _currentTask;
  TaskStatus get detailStatus => _detailStatus;

  // ===== 2. THÊM GETTER CHO MY TASKS =====
  List<Task> get myTasks => _myTasks;
  TaskStatus get myTasksStatus => _myTasksStatus;


  // --- Hàm gọi API ---

  // Lấy tasks theo project
  Future<void> fetchTasks(int projectId) async {
    if (_status == TaskStatus.Loading) return;
    _status = TaskStatus.Loading;
    notifyListeners();
    try {
      final tasks = await _taskService.getTasksByProjectId(projectId);
      _tasksByProject[projectId] = tasks;
      _status = TaskStatus.Success;
    } catch (e) {
      _status = TaskStatus.Error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  // Tạo task mới
  Future<bool> createTask({
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
      final newTask = await _taskService.createTask(
        taskName: taskName, description: description, projectId: projectId,
        status: status, priority: priority, dueDate: dueDate, assigneeId: assigneeId,
        isRecurring: isRecurring, recurrenceRule: recurrenceRule,
      );

      // Nếu là task dự án
      if (projectId != null && _tasksByProject.containsKey(projectId)) {
        _tasksByProject[projectId]!.insert(0, newTask);
      }

      // Nếu là task cá nhân (projectId == null), nó sẽ tự động được gán cho bạn
      // (do logic Back-end), nên ta thêm nó vào _myTasks.
      if (projectId == null) {
        _myTasks.insert(0, newTask);
        _myTasksStatus = TaskStatus.Success; // Đảm bảo trạng thái
      }
      // Thêm vào list theo project (nếu đã tải)
      if (_tasksByProject.containsKey(projectId)) {
        _tasksByProject[projectId]!.insert(0, newTask);
      }
      // TODO: Nếu assigneeId là user hiện tại, có thể thêm vào _myTasks luôn? Hoặc fetchMyTasks lại.
      _status = TaskStatus.Success; // Đảm bảo status list project là success
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = TaskStatus.Error; // Đặt status list project là error
      notifyListeners();
      return false;
    }
  }

  // Lấy chi tiết 1 task
  Future<void> fetchTaskDetails(int taskId) async {
    _detailStatus = TaskStatus.Loading;
    notifyListeners();
    try {
      _currentTask = await _taskService.getTaskById(taskId);
      _detailStatus = TaskStatus.Success;
    } catch (e) {
      _errorMessage = e.toString();
      _detailStatus = TaskStatus.Error;
    }
    notifyListeners();
  }

  // Cập nhật 1 task
  Future<bool> updateTask(int taskId, Map<String, dynamic> updates) async {
    try {
      final updatedTask = await _taskService.updateTask(taskId, updates);
      _currentTask = updatedTask; // Cập nhật task chi tiết đang xem

      // Cập nhật trong list theo project
      final projectId = updatedTask.projectId;
      if (_tasksByProject.containsKey(projectId)) {
        final taskIndex = _tasksByProject[projectId]!.indexWhere((task) => task.taskId == taskId);
        if (taskIndex != -1) { _tasksByProject[projectId]![taskIndex] = updatedTask; }
      }

      // ===== 3. CẬP NHẬT TRONG LIST MY TASKS =====
      final myTaskIndex = _myTasks.indexWhere((t) => t.taskId == taskId);
      if (myTaskIndex != -1) {
        _myTasks[myTaskIndex] = updatedTask;
      }
      // TODO: Xử lý trường hợp task được gán/bỏ gán cho user hiện tại khi update.
      // Có thể cần gọi lại fetchMyTasks() để đảm bảo chính xác.

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Clear task chi tiết
  void clearCurrentTask() {
    _currentTask = null;
    _detailStatus = TaskStatus.Idle;
    // Không cần notifyListeners() nếu không muốn UI tự động cập nhật khi đóng màn hình
  }

  // ===== 4. THÊM HÀM FETCH MY TASKS =====
  Future<void> fetchMyTasks({bool forceRefresh = false}) async {
    // Không tải lại nếu đang tải hoặc đã có dữ liệu (trừ khi force)
    if (_myTasksStatus == TaskStatus.Loading && !forceRefresh) return;
    if (_myTasks.isNotEmpty && !forceRefresh) return;

    _myTasksStatus = TaskStatus.Loading;
    notifyListeners();
    try {
      _myTasks = await _taskService.getMyTasks();
      _myTasksStatus = TaskStatus.Success;
    } catch (e) {
      _errorMessage = e.toString();
      _myTasksStatus = TaskStatus.Error;
    }
    notifyListeners();
  }
}