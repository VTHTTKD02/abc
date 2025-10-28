// File: lib/screens/task/task_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../models/comment_model.dart'; // Import Comment model
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/comment_provider.dart'; // Import Comment provider
import '../../providers/auth_provider.dart'; // <-- THÊM IMPORT AUTH PROVIDER
import '../../models/user_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tuple/tuple.dart';
import '../../services/notification_service.dart';


class TaskDetailScreen extends StatefulWidget {
  final int taskId;
  final String taskName;

  TaskDetailScreen({required this.taskId, required this.taskName});

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  // --- State Variables ---
  bool _isEditing = false;
  bool _isLoading = false; // Loading cho save/fetch task details
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _commentController;
  bool _isSendingComment = false; // Loading khi gửi comment

  // Biến tạm lưu giá trị đang sửa task
  int? _editStatus;
  int? _editPriority;
  DateTime? _editDueDate;
  int? _editAssigneeId;
  bool _editIsRecurring = false;

  // Maps hiển thị
  final Map<int, String> _priorities = { 0: 'Thấp', 1: 'Trung bình', 2: 'Cao' };
  final Map<int, String> _statuses = { 0: 'Cần làm', 1: 'Đang làm', 2: 'Hoàn thành' };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();
    _commentController = TextEditingController();

    // Gọi APIs khi màn hình mở
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchUsers(); // Lấy danh sách user cho dropdown sửa
      _fetchDetails(); // Lấy chi tiết task
      Provider.of<CommentProvider>(context, listen: false).fetchComments(widget.taskId); // Lấy comments
    });
  }

  // Hàm tải chi tiết task
  Future<void> _fetchDetails() async {
    final provider = Provider.of<TaskProvider>(context, listen: false);
    // Chỉ bật loading nếu chưa có dữ liệu task hiện tại
    if (provider.currentTask == null) {
      setState(() { _isLoading = true; });
    }
    await provider.fetchTaskDetails(widget.taskId);
    // Tắt loading sau khi tải xong (kể cả lỗi)
    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  @override
  void dispose() {
    // Clear state providers
    Provider.of<TaskProvider>(context, listen: false).clearCurrentTask();
    Provider.of<CommentProvider>(context, listen: false).clearComments(widget.taskId);
    // Dispose controllers
    _nameController.dispose();
    _descController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  // --- Hàm xử lý sửa Task ---
  void _startEditing(Task task) {
    setState(() {
      _isEditing = true;
      _nameController.text = task.taskName;
      _descController.text = task.description ?? '';
      _editStatus = task.status;
      _editPriority = task.priority;
      _editDueDate = task.dueDate;
      _editAssigneeId = task.assigneeId;
      _editIsRecurring = task.isRecurring;
    });
  }
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) { return; }
    setState(() { _isLoading = true; });
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final originalTask = taskProvider.currentTask!;
    Map<String, dynamic> updates = {
      'taskName': _nameController.text,
      'description': _descController.text,
      'status': _editStatus,
      'priority': _editPriority,
      'dueDate': _editDueDate?.toIso8601String(),
      'assigneeId': _editAssigneeId,
      'isRecurring': _editIsRecurring,
      'recurrenceRule': _editIsRecurring ? "DAILY" : null,
    };
    bool success = await taskProvider.updateTask(originalTask.taskId, updates);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (success) {
          _isEditing = false;
          ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Cập nhật thành công!'), backgroundColor: Colors.green), );

          // ===== LÊN LỊCH/HỦY THÔNG BÁO KHI SỬA =====
          // Lấy task đã cập nhật từ provider
          final updatedTask = taskProvider.currentTask!;

          // Hủy thông báo cũ trước
          NotificationService().cancelNotification(updatedTask.taskId);

          // Lên lịch thông báo mới nếu có ngày giờ trong tương lai
          if (_editDueDate != null && _editDueDate!.isAfter(DateTime.now())) {
            NotificationService().scheduleNotification(
              id: updatedTask.taskId,
              title: 'Công việc đến hạn: ${updatedTask.taskName}',
              body: 'Dự án: ${updatedTask.projectName ?? "Việc cá nhân"}',
              scheduledDate: _editDueDate!,
            );
            print("Đã cập nhật lịch thông báo ${updatedTask.taskId} lúc $_editDueDate");
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Lỗi: ${taskProvider.errorMessage}'), backgroundColor: Colors.red), );
        }
      });
    }
  }
  void _cancelEditing() { setState(() { _isEditing = false; }); }
  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker( context: context, initialDate: _editDueDate ?? DateTime.now(), firstDate: DateTime.now().subtract(Duration(days: 365)), lastDate: DateTime(2030), );
    if (pickedDate == null) return; // Hủy

    // 2. Chọn Giờ
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_editDueDate ?? DateTime.now()),
    );
    if (pickedTime == null) return; // Hủy

    // 3. Gộp
    setState(() {
      _editDueDate = DateTime(
        pickedDate.year, pickedDate.month, pickedDate.day,
        pickedTime.hour, pickedTime.minute,
      );
    });
  }

  // --- Hàm xử lý Comment ---
  Future<void> _sendComment() async {
    final content = _commentController.text.trim(); if (content.isEmpty) return;
    setState(() { _isSendingComment = true; });
    final commentProvider = Provider.of<CommentProvider>(context, listen: false);
    bool success = await commentProvider.createComment(widget.taskId, content);
    if (mounted) {
      if (success) { _commentController.clear(); }
      else { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${commentProvider.errorMessage}'), backgroundColor: Colors.redAccent)); }
      setState(() { _isSendingComment = false; });
    }
  }
  Future<void> _showEditCommentDialog(BuildContext context, Comment comment) async {
    final _editCommentController = TextEditingController(text: comment.content);
    final _editFormKey = GlobalKey<FormState>();
    bool _isSavingEdit = false;

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text('Sửa bình luận'),
                content: Form(
                  key: _editFormKey,
                  child: TextFormField(
                    controller: _editCommentController,
                    decoration: InputDecoration(labelText: 'Nội dung'),
                    maxLines: 3,
                    validator: (value) => value!.trim().isEmpty ? 'Không được để trống' : null,
                  ),
                ),
                actions: <Widget>[
                  TextButton( child: Text('Hủy'), onPressed: _isSavingEdit ? null : () => Navigator.of(dialogContext).pop(), ),
                  ElevatedButton(
                    child: _isSavingEdit ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('Lưu'),
                    onPressed: _isSavingEdit ? null : () async {
                      if (_editFormKey.currentState!.validate()) {
                        setDialogState(() { _isSavingEdit = true; });
                        final commentProvider = Provider.of<CommentProvider>(context, listen: false);
                        bool success = await commentProvider.updateComment( widget.taskId, comment.commentId, _editCommentController.text.trim(), );
                        // Check if dialog is still mounted before interacting with Navigator or ScaffoldMessenger
                        if (Navigator.of(dialogContext).canPop()){
                          if (success) {
                            Navigator.of(dialogContext).pop();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${commentProvider.errorMessage}'), backgroundColor: Colors.redAccent));
                            setDialogState(() { _isSavingEdit = false; });
                          }
                        }
                      }
                    },
                  ),
                ],
              );
            }
        );
      },
    );
  }
  Future<void> _deleteComment(BuildContext context, Comment comment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa bình luận này?'),
        actions: [
          TextButton( child: Text('Hủy'), onPressed: () => Navigator.of(dialogCtx).pop(false), ),
          TextButton( child: Text('Xóa', style: TextStyle(color: Colors.red)), onPressed: () => Navigator.of(dialogCtx).pop(true), ),
        ],
      ),
    );
    if (confirm == true) {
      final commentProvider = Provider.of<CommentProvider>(context, listen: false);
      bool success = await commentProvider.deleteComment(widget.taskId, comment.commentId);
      if (mounted && !success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${commentProvider.errorMessage}'), backgroundColor: Colors.redAccent));
      }
    }
  }

  // --- WIDGETS BUILD ---

  // Build phần thông tin Task (Chế độ xem)
  Widget _buildInfoSection(Task task) {
    return Container( padding: EdgeInsets.all(16), margin: EdgeInsets.symmetric(horizontal:16, vertical: 8), decoration: BoxDecoration( color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [ BoxShadow( color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 3,) ], ),
      child: Column( crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chi tiết công việc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).primaryColor)),
          SizedBox(height: 15),
          if (task.description != null && task.description!.isNotEmpty) ...[ Text('Mô tả', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])), SizedBox(height: 5), Text(task.description!, style: TextStyle(height: 1.4)), Divider(height: 30), ],
          _buildInfoRow(Icons.flag_outlined, 'Trạng thái', _statuses[task.status] ?? 'N/A'),
          _buildInfoRow(Icons.person_outline, 'Người giao', task.reporterName),
          _buildInfoRow(Icons.person_add_alt_1_outlined, 'Người nhận', task.assigneeName ?? 'Chưa gán'),
          _buildInfoRow(Icons.priority_high, 'Ưu tiên', _priorities[task.priority] ?? 'N/A'),
          _buildInfoRow(Icons.repeat, 'Lặp lại', task.isRecurring ? 'Hàng ngày' : 'Không'),
          _buildInfoRow(Icons.calendar_today_outlined, 'Ngày tạo', DateFormat('dd/MM/yyyy HH:mm').format(task.createdAt)),
          _buildInfoRow(Icons.event_busy_outlined, 'Hết hạn', task.dueDate != null ? DateFormat('dd/MM/yyyy').format(task.dueDate!) : 'Không có' ),
        ],
      ),
    );
  }
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding( padding: const EdgeInsets.symmetric(vertical: 8.0), child: Row( children: [ Icon(icon, color: Colors.grey[600], size: 20), SizedBox(width: 15), Text('$label:', style: TextStyle(color: Colors.grey[700])), SizedBox(width: 10), Expanded( child: Text(value, style: TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.right), ), ], ), );
  }

  // Build Form chỉnh sửa Task
  Widget _buildEditForm(Task task) {
    return Container( padding: EdgeInsets.all(16), margin: EdgeInsets.all(16), decoration: BoxDecoration( color: Colors.white, borderRadius: BorderRadius.circular(12),),
      child: Form( key: _formKey,
        child: Column( crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Chỉnh sửa công việc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).primaryColor)), SizedBox(height: 20),
            TextFormField( controller: _nameController, decoration: InputDecoration(labelText: 'Tên công việc *', prefixIcon: Icon(Icons.title)), validator: (value) => value!.isEmpty ? 'Không được để trống' : null, ), SizedBox(height: 15),
            TextFormField( controller: _descController, decoration: InputDecoration(labelText: 'Mô tả', prefixIcon: Icon(Icons.description_outlined)), maxLines: 3, ), SizedBox(height: 15),
            DropdownButtonFormField<int>( value: _editStatus, decoration: InputDecoration(labelText: 'Trạng thái', prefixIcon: Icon(Icons.flag_outlined)), items: _statuses.entries.map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value))).toList(), onChanged: (value) { setState(() { _editStatus = value; }); }, ), SizedBox(height: 15),
            Consumer<UserProvider>( builder: (context, userProvider, child) { return DropdownButtonFormField<int>( value: _editAssigneeId, decoration: InputDecoration(labelText: 'Gán cho', prefixIcon: Icon(Icons.person_outline)), items: userProvider.users.map((AppUser user) => DropdownMenuItem(value: user.id, child: Text(user.fullName))).toList(), onChanged: (value) { setState(() { _editAssigneeId = value; }); }, hint: userProvider.isLoading ? Text('Đang tải...') : Text('Chọn người nhận'), ); } ), SizedBox(height: 15),
            DropdownButtonFormField<int>( value: _editPriority, decoration: InputDecoration(labelText: 'Ưu tiên', prefixIcon: Icon(Icons.priority_high)), items: _priorities.entries.map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value))).toList(), onChanged: (value) { setState(() { _editPriority = value; }); }, ), SizedBox(height: 15),
            Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Expanded(child: Text(_editDueDate == null ? 'Ngày hết hạn' : 'Hết hạn: ${DateFormat('dd/MM/yyyy').format(_editDueDate!)}', style: TextStyle(fontSize: 16))), TextButton(onPressed: _pickDate, child: Text('Chọn ngày')), ], ),
            CheckboxListTile( title: Text("Lặp lại hàng ngày"), value: _editIsRecurring, onChanged: (bool? value) { setState(() { _editIsRecurring = value ?? false; }); }, controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero, activeColor: Theme.of(context).primaryColor, ),
          ],
        ),
      ),
    );
  }

  // Build phần Bình luận (Đã cập nhật Sửa/Xóa)
  Widget _buildCommentsSection() {
    final currentUserId = context.read<AuthProvider>().getUserId(); // Lấy ID user hiện tại

    return Container(
      padding: EdgeInsets.all(16), margin: EdgeInsets.only(left: 16, right: 16, bottom: 16), decoration: BoxDecoration( color: Colors.white, borderRadius: BorderRadius.circular(12), ),
      child: Column( crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bình luận', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).primaryColor)), SizedBox(height: 15),
          // Ô nhập comment
          Row( children: [ Expanded( child: TextField( controller: _commentController, decoration: InputDecoration( hintText: 'Viết bình luận...', filled: true, fillColor: Colors.grey[100], contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10), border: OutlineInputBorder( borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none, ), ), enabled: !_isSendingComment, ), ), SizedBox(width: 8), IconButton( icon: _isSendingComment ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(Icons.send, color: Theme.of(context).primaryColor), onPressed: _isSendingComment ? null : _sendComment, tooltip: 'Gửi bình luận', ), ], ),
          SizedBox(height: 20),
          // Danh sách comment
          Consumer<CommentProvider>(
            builder: (context, commentProvider, child) {
              final comments = commentProvider.commentsForTask(widget.taskId);
              final status = commentProvider.status;
              if (status == CommentStatus.Loading && comments.isEmpty) { return Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: CircularProgressIndicator())); }
              if (status == CommentStatus.Error && comments.isEmpty) { return Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('Lỗi tải bình luận: ${commentProvider.errorMessage}'))); }
              if (comments.isEmpty) { return Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('Chưa có bình luận nào.', style: TextStyle(color: Colors.grey)))); }

              return ListView.separated(
                shrinkWrap: true, physics: NeverScrollableScrollPhysics(), itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  final bool isMyComment = comment.userId == currentUserId; // <-- Kiểm tra quyền

                  return ListTile(
                    contentPadding: EdgeInsets.only(left: 0, right: 0, top: 5, bottom: 5),
                    leading: CircleAvatar( backgroundColor: Colors.indigo[50], child: Text(comment.userFullName.isNotEmpty ? comment.userFullName[0] : '?') ),
                    title: Text(comment.userFullName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(comment.content, style: TextStyle(color: Colors.black87)),
                    // ===== THÊM TRAILING LÀ POPUP MENU =====
                    trailing: isMyComment
                        ? PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, size: 20, color: Colors.grey),
                      tooltip: 'Tùy chọn',
                      onSelected: (String result) {
                        if (result == 'edit') { _showEditCommentDialog(context, comment); } // Gọi hàm sửa
                        else if (result == 'delete') { _deleteComment(context, comment); } // Gọi hàm xóa
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>( value: 'edit', child: ListTile(dense: true, leading: Icon(Icons.edit_outlined, size: 20), title: Text('Sửa')), ),
                        const PopupMenuItem<String>( value: 'delete', child: ListTile(dense: true, leading: Icon(Icons.delete_outline, size: 20, color: Colors.red), title: Text('Xóa', style: TextStyle(color: Colors.red))), ),
                      ],
                    )
                        : Text( // Hiển thị thời gian nếu không phải comment của tôi
                      DateFormat('dd/MM HH:mm').format(comment.createdAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    // ======================================
                  ).animate().fadeIn(delay: (index * 50).ms);
                },
                separatorBuilder: (context, index) => Divider(height: 1, indent: 55, endIndent: 10),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  @override
  Widget build(BuildContext context) {
    // Dùng Selector (Không đổi)
    return Selector<TaskProvider, Tuple2<Task?, TaskStatus>>(
        selector: (_, provider) => Tuple2(provider.currentTask, provider.detailStatus),
        builder: (context, data, _) {
          // ... (code xử lý loading, error, task == null không đổi) ...
          final task = data.item1; final detailStatus = data.item2; if ((detailStatus == TaskStatus.Loading || _isLoading) && task == null) { return Scaffold(appBar: AppBar(title: Text(widget.taskName)), body: Center(child: CircularProgressIndicator())); } if (detailStatus == TaskStatus.Error && task == null) { return Scaffold(appBar: AppBar(title: Text(widget.taskName)), body: Center(child: Text('Lỗi: ${context.read<TaskProvider>().errorMessage}'))); } if (task == null) { return Scaffold(appBar: AppBar(title: Text(widget.taskName)), body: Center(child: Text('Không tìm thấy công việc.'))); }

          return Scaffold(
            backgroundColor: Colors.grey[100],
            appBar: AppBar(
              title: Text(_isEditing ? 'Chỉnh sửa: ${task.taskName}' : task.taskName),
              actions: [ /* ... Nút Edit/Save/Cancel không đổi ... */ if (_isEditing) ...[ IconButton( icon: Icon(Icons.cancel_outlined), tooltip: 'Hủy', onPressed: _isLoading ? null : _cancelEditing, ), IconButton( icon: _isLoading ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(Icons.save_outlined), tooltip: 'Lưu', onPressed: _isLoading ? null : _saveChanges, ), ] else ...[ IconButton( icon: Icon(Icons.edit_outlined), tooltip: 'Chỉnh sửa', onPressed: () => _startEditing(task), ), ] ],
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 10),
                  // Hiện form sửa hoặc thông tin xem (Không đổi)
                  _isEditing ? _buildEditForm(task).animate().fadeIn() : _buildInfoSection(task).animate().fadeIn(),
                  // Phần Bình luận (Đã cập nhật Sửa/Xóa)
                  _buildCommentsSection(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          );
        }
    );
  }
}