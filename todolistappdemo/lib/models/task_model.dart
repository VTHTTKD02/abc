// File: lib/models/task_model.dart

class Task {
  final int taskId;
  final String taskName;
  final String? description;
  final int status; // 0: ToDo, 1: InProgress, 2: Done
  final int priority;
  final DateTime createdAt;
  final DateTime? dueDate;
  final int projectId;
  final String? projectName;
  final int reporterId;
  final String reporterName;
  final int? assigneeId;
  final String? assigneeName;
  final bool isRecurring;
  final String? recurrenceRule;

  Task({
    required this.taskId,
    required this.taskName,
    this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.dueDate,
    required this.projectId,
    this.projectName,
    required this.reporterId,
    required this.reporterName,
    this.assigneeId,
    this.assigneeName,
    required this.isRecurring,
    this.recurrenceRule,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      taskId: json['taskId'],
      taskName: json['taskName'],
      description: json['description'],
      status: json['status'],
      priority: json['priority'],
      createdAt: DateTime.parse(json['createdAt']),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      projectId: json['projectId'],
      projectName: json['projectName'],
      reporterId: json['reporterId'],
      reporterName: json['reporterName'],
      assigneeId: json['assigneeId'],
      assigneeName: json['assigneeName'],
      isRecurring: json['isRecurring'] ?? false, // Mặc định false nếu API không trả về
      recurrenceRule: json['recurrenceRule'],
    );
  }
}