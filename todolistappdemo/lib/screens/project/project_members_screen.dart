// File: lib/screens/project/project_members_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/project_model.dart'; // Cần Project để biết tên
import '../../models/user_model.dart';
import '../../providers/project_member_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProjectMembersScreen extends StatefulWidget {
  final Project project;

  ProjectMembersScreen({required this.project});

  @override
  _ProjectMembersScreenState createState() => _ProjectMembersScreenState();
}

class _ProjectMembersScreenState extends State<ProjectMembersScreen> {
  @override
  void initState() {
    super.initState();
    // Tải danh sách thành viên khi mở
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProjectMemberProvider>(context, listen: false)
          .fetchMembers(widget.project.projectId);
    });
  }
  @override
  void dispose() {
    // Clear state khi đóng màn hình
    Provider.of<ProjectMemberProvider>(context, listen: false)
        .clearMembers(widget.project.projectId);
    super.dispose();
  }


  // Hàm hiển thị Dialog thêm thành viên (Không đổi)
  Future<void> _showAddMemberDialog() async {
    // ... (code hàm này giữ nguyên) ...
    final _emailController = TextEditingController();
    final _dialogFormKey = GlobalKey<FormState>();
    bool _isAdding = false;

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text('Thêm thành viên mới'),
                content: Form(
                  key: _dialogFormKey,
                  child: TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Nhập Email thành viên',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty || !value.contains('@')) {
                        return 'Vui lòng nhập email hợp lệ';
                      }
                      return null;
                    },
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('Hủy'),
                    onPressed: _isAdding ? null : () => Navigator.of(dialogContext).pop(),
                  ),
                  ElevatedButton(
                    child: _isAdding ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('Thêm'),
                    onPressed: _isAdding ? null : () async {
                      if (_dialogFormKey.currentState!.validate()) {
                        setDialogState(() { _isAdding = true; });

                        final memberProvider = Provider.of<ProjectMemberProvider>(context, listen: false);
                        bool success = await memberProvider.addMember(
                          widget.project.projectId,
                          _emailController.text,
                        );

                        if (mounted) {
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Thêm thành viên thành công!'), backgroundColor: Colors.green));
                            Navigator.of(dialogContext).pop();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${memberProvider.errorMessage}'), backgroundColor: Colors.redAccent));
                            setDialogState(() { _isAdding = false; });
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

  @override
  Widget build(BuildContext context) {
    // Lấy provider mà không lắng nghe (dùng cho hàm xóa)
    final memberProvider = Provider.of<ProjectMemberProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Thành viên: ${widget.project.projectName}'),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add_alt_1),
            tooltip: 'Thêm thành viên',
            onPressed: _showAddMemberDialog, // Mở dialog
          ),
        ],
      ),
      body: Consumer<ProjectMemberProvider>( // Dùng Consumer để rebuild khi list thay đổi
        builder: (context, provider, child) {
          final members = provider.membersForProject(widget.project.projectId);

          // Xử lý loading, error, list trống (Không đổi)
          if (provider.status == MemberStatus.Loading && members.isEmpty) { return Center(child: CircularProgressIndicator()); }
          if (provider.status == MemberStatus.Error && members.isEmpty) { return Center(child: Text('Lỗi: ${provider.errorMessage}')); }
          if (members.isEmpty) { return Center(child: Text('Chưa có thành viên nào trong dự án.')); }

          // Hiển thị danh sách thành viên
          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (ctx, index) {
              final member = members[index];
              // Lấy ký tự đầu tiên (đảm bảo không lỗi nếu tên trống)
              final initial = member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : '?';

              return ListTile(
                leading: CircleAvatar(child: Text(initial)),
                title: Text(member.fullName),
                subtitle: Text(member.email ?? member.userName ?? 'N/A'),

                // ===== THÊM NÚT XÓA VÀO ĐÂY =====
                trailing: IconButton(
                  icon: Icon(Icons.remove_circle_outline, color: Colors.red[400]),
                  tooltip: 'Xóa thành viên',
                  // Vô hiệu hóa nút nếu đang loading
                  onPressed: provider.status == MemberStatus.Loading ? null : () async {
                    // Hiển thị dialog xác nhận trước khi xóa
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        title: Text('Xác nhận xóa'),
                        content: Text('Bạn có chắc muốn xóa thành viên "${member.fullName}" khỏi dự án?'),
                        actions: [
                          TextButton(
                            child: Text('Hủy'),
                            onPressed: () => Navigator.of(dialogCtx).pop(false),
                          ),
                          TextButton(
                            child: Text('Xóa', style: TextStyle(color: Colors.red)),
                            onPressed: () => Navigator.of(dialogCtx).pop(true),
                          ),
                        ],
                      ),
                    );

                    // Nếu người dùng xác nhận
                    if (confirm == true) {
                      // Gọi hàm xóa từ provider (dùng biến memberProvider đã lấy ở ngoài Consumer)
                      final success = await memberProvider.removeMember(widget.project.projectId, member.id);
                      if (mounted && !success) {
                        // Hiển thị lỗi nếu xóa thất bại
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${memberProvider.errorMessage}'), backgroundColor: Colors.redAccent));
                      }
                      // Nếu thành công thì Consumer sẽ tự rebuild list
                    }
                  },
                ),
                // ===================================

              ).animate().fadeIn(delay: (index * 50).ms);
            },
          );
        },
      ),
    );
  }
}