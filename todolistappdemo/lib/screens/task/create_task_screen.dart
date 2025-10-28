// File: lib/screens/task/create_task_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart'; // <-- Import Task Model
import '../../providers/task_provider.dart';
import '../../providers/project_member_provider.dart';
import '../../models/user_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/notification_service.dart'; // <-- Import Notification Service

class CreateTaskScreen extends StatefulWidget {
  final int? projectId; // Đã là int?

  CreateTaskScreen({required this.projectId});

  @override
  _CreateTaskScreenState createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  DateTime? _dueDate; // Biến này giờ sẽ lưu cả Ngày và Giờ
  bool _isLoading = false;

  int? _selectedAssigneeId;
  int _selectedStatus = 0; // 0 = ToDo
  int _selectedPriority = 1; // 1 = Medium
  bool _isRecurring = false;
  late bool isPersonalTask;

  @override
  void initState() {
    super.initState();
    isPersonalTask = widget.projectId == null;

    if (!isPersonalTask) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<ProjectMemberProvider>(context, listen: false)
            .fetchMembers(widget.projectId!);
      });
    }
  }

  // ===== HÀM CHỌN NGÀY/GIỜ =====
  Future<void> _pickDateTime() async {
    // 1. Chọn Ngày
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(Duration(days: 1)), // Cho phép chọn từ hôm qua
      lastDate: DateTime(2030),
    );

    if (pickedDate == null) {
      return; // Người dùng hủy chọn ngày
    }

    // 2. Chọn Giờ
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate ?? DateTime.now()),
    );

    if (pickedTime == null) {
      return; // Người dùng hủy chọn giờ
    }

    // 3. Gộp Ngày và Giờ
    setState(() {
      _dueDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }
  // ===================================

  // ===== HÀM SUBMIT (ĐỂ LÊN LỊCH THÔNG BÁO) =====
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) { return; }
    setState(() { _isLoading = true; });

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    bool success = await taskProvider.createTask(
      taskName: _nameController.text,
      description: _descController.text,
      projectId: widget.projectId,
      status: _selectedStatus,
      priority: _selectedPriority,
      dueDate: _dueDate, // Gửi DateTime (đã có giờ)
      assigneeId: _selectedAssigneeId,
      isRecurring: _isRecurring,
      recurrenceRule: _isRecurring ? "DAILY" : null,
    );

    if (mounted) {
      setState(() { _isLoading = false; });
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Tạo công việc thành công!'), backgroundColor: Colors.green), );

        // ===== LÊN LỊCH THÔNG BÁO NẾU CÓ NGÀY GIỜ =====
        if (_dueDate != null && _dueDate!.isAfter(DateTime.now())) {

          // Lấy ID Task thực sự (cách an toàn hơn)
          Task? createdTask;
          try {
            // Tìm task vừa tạo trong provider (dựa trên tên và projectId)
            if (isPersonalTask && taskProvider.myTasks.isNotEmpty) {
              createdTask = taskProvider.myTasks.firstWhere(
                      (t) => t.taskName == _nameController.text && (t.projectId == 0 || t.projectId == null),
                  orElse: () => taskProvider.myTasks.first // Fallback
              );
            } else if (!isPersonalTask && taskProvider.tasksForProject(widget.projectId!).isNotEmpty) {
              createdTask = taskProvider.tasksForProject(widget.projectId!).firstWhere(
                      (t) => t.taskName == _nameController.text,
                  orElse: () => taskProvider.tasksForProject(widget.projectId!).first // Fallback
              );
            }
          } catch(e) {
            print("Lỗi tìm task vừa tạo: $e");
          }

          // Dùng TaskId (an toàn) hoặc hashCode (dự phòng)
          int notificationId = createdTask?.taskId ?? _nameController.text.hashCode;

          NotificationService().scheduleNotification(
            id: notificationId,
            title: 'Công việc đến hạn: ${_nameController.text}',
            body: isPersonalTask ? 'Việc cá nhân của bạn đã đến hạn.' : 'Một công việc dự án đã đến hạn.',
            scheduledDate: _dueDate!,
          );
          print("Đã lên lịch thông báo $notificationId lúc $_dueDate");
        }
        // =============================================

        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Lỗi: ${taskProvider.errorMessage}'), backgroundColor: Colors.redAccent), );
      }
    }
  }
  // ===============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isPersonalTask ? 'Tạo việc cá nhân' : 'Tạo công việc mới'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ... (Tên, Mô tả, Gán cho, Trạng thái, Ưu tiên) ...
              TextFormField( controller: _nameController, decoration: InputDecoration( labelText: 'Tên công việc *', prefixIcon: Icon(Icons.title), ), validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên' : null, ),
              SizedBox(height: 20),
              TextFormField( controller: _descController, decoration: InputDecoration( labelText: 'Mô tả chi tiết', prefixIcon: Icon(Icons.description_outlined), ), maxLines: 4, ),
              SizedBox(height: 20),
              if (!isPersonalTask) ...[
                Consumer<ProjectMemberProvider>(
                  builder: (context, memberProvider, child) {
                    // ... (code dropdown Gán cho) ...
                    final members = memberProvider.membersForProject(widget.projectId!);
                    return DropdownButtonFormField<int>( value: _selectedAssigneeId, decoration: InputDecoration( labelText: 'Gán cho (Assignee)', prefixIcon: Icon(Icons.person_outline), ), items: members.map((AppUser member) { return DropdownMenuItem<int>( value: member.id, child: Text(member.fullName), ); }).toList(), onChanged: (value) { setState(() { _selectedAssigneeId = value; }); }, hint: Text(members.isEmpty ? 'Không có thành viên nào' : 'Chọn người nhận'), disabledHint: memberProvider.status == MemberStatus.Loading ? Text('Đang tải...') : null, );
                  },
                ),
                SizedBox(height: 20),
              ],
              DropdownButtonFormField<int>( value: _selectedStatus, decoration: InputDecoration( labelText: 'Trạng thái', prefixIcon: Icon(Icons.work_history_outlined), ), items: [ DropdownMenuItem(value: 0, child: Text('Cần làm (ToDo)')), DropdownMenuItem(value: 1, child: Text('Đang làm (In Progress)')), DropdownMenuItem(value: 2, child: Text('Hoàn thành (Done)')), ], onChanged: (value) { setState(() { _selectedStatus = value ?? 0; }); }, ),
              SizedBox(height: 20),
              DropdownButtonFormField<int>( value: _selectedPriority, decoration: InputDecoration( labelText: 'Mức ưu tiên', prefixIcon: Icon(Icons.priority_high), ), items: [ DropdownMenuItem(value: 0, child: Text('Thấp')), DropdownMenuItem(value: 1, child: Text('Trung bình')), DropdownMenuItem(value: 2, child: Text('Cao')), ], onChanged: (value) { setState(() { _selectedPriority = value ?? 1; }); }, ),
              SizedBox(height: 20),

              // ===== 4. SỬA HIỂN THỊ NGÀY HẾT HẠN =====
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _dueDate == null
                          ? 'Ngày & Giờ hết hạn' // Sửa text
                      // Format để hiển thị cả Giờ:Phút
                          : 'Hết hạn: ${DateFormat('dd/MM/yyyy HH:mm').format(_dueDate!)}',
                    ),
                  ),
                  TextButton(
                    onPressed: _pickDateTime, // Gọi hàm mới
                    child: Text('Chọn'), // Sửa text
                  ),
                ],
              ),
              // =====================================

              // ... (Checkbox Lặp lại, Nút bấm) ...
              CheckboxListTile( title: Text("Lặp lại hàng ngày"), value: _isRecurring, onChanged: (bool? value) { setState(() { _isRecurring = value ?? false; }); }, controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero, activeColor: Theme.of(context).primaryColor, ),
              SizedBox(height: 20),
              _isLoading ? Center(child: CircularProgressIndicator()) : ElevatedButton( onPressed: _submitForm, child: Text(isPersonalTask ? 'Lưu việc cá nhân' : 'Tạo công việc'), )
            ],
          ).animate().fadeIn(duration: 400.ms),
        ),
      ),
    );
  }
}