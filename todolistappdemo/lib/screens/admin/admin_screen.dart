import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart'; // Thêm AuthProvider để lấy ID user hiện tại

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> { // <-- ĐÃ SỬA TÊN CLASS STATE
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      // Bắt đầu tải danh sách người dùng
      Provider.of<UserProvider>(context, listen: false).fetchUsers();
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  // Hàm hiển thị hộp thoại Sửa User
  Future<void> _showEditUserDialog(AppUser user) async {
    final _fullNameController = TextEditingController(text: user.fullName);
    final _emailController = TextEditingController(text: user.email);
    final _phoneController = TextEditingController(text: user.phoneNumber);
    final _formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Sửa User: ${user.userName}'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: ListBody(
                children: <Widget>[
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(labelText: 'Họ và tên'),
                    validator: (value) => value!.isEmpty ? 'Không được để trống' : null,
                  ),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value!.isEmpty ? 'Không được để trống' : (value.contains('@') ? null : 'Email không hợp lệ'),
                  ),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Số điện thoại (Optional)'),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('Lưu'),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop();
                  // Gọi API cập nhật
                  final provider = Provider.of<UserProvider>(context, listen: false);
                  bool success = await provider.updateUser(
                    user.id,
                    _fullNameController.text,
                    _emailController.text,
                    _phoneController.text.isEmpty ? null : _phoneController.text,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(success ? 'Cập nhật thành công!' : 'Lỗi: ${provider.errorMessage}'), backgroundColor: success ? Colors.green : Colors.red),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Hàm xác nhận Xóa User
  Future<void> _deleteUser(AppUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa user "${user.fullName}"? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(child: const Text('Hủy'), onPressed: () => Navigator.of(dialogCtx).pop(false)),
          TextButton(child: const Text('Xóa', style: TextStyle(color: Colors.red)), onPressed: () => Navigator.of(dialogCtx).pop(true)),
        ],
      ),
    );

    if (confirm == true) {
      final provider = Provider.of<UserProvider>(context, listen: false);
      bool success = await provider.deleteUser(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Xóa user thành công.' : 'Lỗi: ${provider.errorMessage}'), backgroundColor: success ? Colors.green : Colors.red),
        );
      }
    }
  }

  // Hàm Gán/Hủy quyền Admin
  Future<void> _toggleAdminRole(AppUser user, bool isAdmin) async {
    final provider = Provider.of<UserProvider>(context, listen: false);
    final action = isAdmin ? 'Cấp' : 'Thu hồi';
    final role = 'Admin';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$action quyền $role...')));

    bool success = await provider.toggleAdminRole(user.id, isAdmin);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? '$action quyền $role thành công!' : 'Lỗi: ${provider.errorMessage}'), backgroundColor: success ? Colors.green : Colors.red),
      );
    }
  }


  Widget _buildUserList(List<AppUser> users) {
    // Lấy ID user đang đăng nhập hiện tại
    final currentLoggedInUserId = Provider.of<AuthProvider>(context, listen: false).getUserId();

    if (users.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Text('Không có người dùng nào được tìm thấy.'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: users.length,
      itemBuilder: (ctx, index) {
        final user = users[index];
        final isAdmin = user.roles.contains("Admin");
        final isSelf = user.id == currentLoggedInUserId; // SỬA: Kiểm tra ID user đang đăng nhập

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isAdmin ? Colors.red[100] : Colors.blue[100],
              child: Icon(Icons.person_outline, color: isAdmin ? Colors.red : Colors.blue),
            ),
            title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email),
                Text(isAdmin ? 'ROLE: Admin' : 'ROLE: User thường', style: TextStyle(color: isAdmin ? Colors.red : Colors.grey)),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showEditUserDialog(user);
                    break;
                  case 'delete':
                    _deleteUser(user);
                    break;
                  case 'toggle_admin':
                    _toggleAdminRole(user, !isAdmin);
                    break;
                }
              },
              itemBuilder: (BuildContext context) {
                return <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: ListTile(leading: Icon(Icons.edit), title: Text('Sửa thông tin')),
                  ),
                  // Không cho phép xóa chính mình
                  PopupMenuItem<String>(
                    value: 'delete',
                    enabled: !isSelf,
                    child: ListTile(leading: Icon(Icons.delete, color: isSelf ? Colors.grey : Colors.red), title: Text('Xóa User', style: TextStyle(color: isSelf ? Colors.grey : Colors.red))),
                  ),
                  const PopupMenuDivider(),
                  // Nút Gán/Hủy quyền Admin
                  PopupMenuItem<String>(
                    value: 'toggle_admin',
                    enabled: !isSelf, // Không cho tự quản lý quyền của mình
                    child: ListTile(
                      leading: Icon(isAdmin ? Icons.person_remove : Icons.security, color: isAdmin ? Colors.orange : Colors.green),
                      title: Text(isAdmin ? 'Thu hồi quyền Admin' : 'Cấp quyền Admin'),
                    ),
                  ),
                ];
              },
            ),
          ),
        ).animate().fadeIn(delay: (index * 50).ms);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.red[700],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (userProvider.status == UserStatus.Error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text('Lỗi tải dữ liệu: ${userProvider.errorMessage}\n\nVui lòng kiểm tra quyền Admin của bạn.', textAlign: TextAlign.center, style: TextStyle(color: Colors.red[700])),
              ),
            );
          }
          return _buildUserList(userProvider.users);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Provider.of<UserProvider>(context, listen: false).fetchUsers(),
        tooltip: 'Refresh Users',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
