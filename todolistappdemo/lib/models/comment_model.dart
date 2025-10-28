// File: lib/models/comment_model.dart

class Comment {
  final int commentId;
  final String content;
  final DateTime createdAt;
  final int taskId;
  final int userId;
  final String userFullName;
  final String? userName; // API trả về cả UserName

  Comment({
    required this.commentId,
    required this.content,
    required this.createdAt,
    required this.taskId,
    required this.userId,
    required this.userFullName,
    this.userName,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      commentId: json['commentId'],
      content: json['content'],
      // Parse UTC time and convert to local time
      createdAt: DateTime.parse(json['createdAt']).toLocal(),
      taskId: json['taskId'],
      userId: json['userId'],
      userFullName: json['userFullName'] ?? 'N/A',
      userName: json['userName'],
    );
  }
}