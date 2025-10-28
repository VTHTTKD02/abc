// File: lib/models/department_model.dart
class Department {
  final int departmentId;
  final String departmentName;
  final String? description;

  Department({
    required this.departmentId,
    required this.departmentName,
    this.description,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      departmentId: json['departmentId'],
      departmentName: json['departmentName'],
      description: json['description'],
    );
  }
}