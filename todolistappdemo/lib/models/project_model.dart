// File: lib/models/project_model.dart

class Project {
  final int projectId;
  final String projectName;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;
  final int? departmentId;
  final String? departmentName;

  Project({
    required this.projectId,
    required this.projectName,
    this.description,
    required this.startDate,
    this.endDate,
    this.departmentId,
    this.departmentName,
  });

  // Hàm này dùng để chuyển đổi JSON (từ API) sang object Project
  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      projectId: json['projectId'],
      projectName: json['projectName'],
      description: json['description'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      departmentId: json['departmentId'],
      departmentName: json['departmentName'],
    );
  }
}