// File: lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart'; // Cần AuthProvider để lấy thông tin user và gọi hàm đổi MK
import 'package:flutter_animate/flutter_animate.dart';

class SettingsScreen extends StatelessWidget {

  // ===== THÊM HÀM HIỂN THỊ DIALOG ĐỔI MẬT KHẨU =====
  void _showChangePasswordDialog(BuildContext context) { // Thêm context làm tham số
    final _dialogFormKey = GlobalKey<FormState>();
    final _currentPasswordController = TextEditingController();
    final _newPasswordController = TextEditingController();
    final _confirmPasswordController = TextEditingController();
    bool _dialogIsLoading = false;

    showDialog(
        context: context,
        barrierDismissible: !_dialogIsLoading, // Không đóng khi đang loading
        builder: (dialogContext) {
          // Dùng StatefulBuilder để cập nhật loading bên trong dialog
          return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  title: Text('Đổi mật khẩu'),
                  content: Form(
                    key: _dialogFormKey,
                    child: SingleChildScrollView( // Cho phép cuộn nếu bàn phím che
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // Thu gọn chiều cao dialog
                        children: [
                          TextFormField(
                            controller: _currentPasswordController,
                            decoration: InputDecoration(labelText: 'Mật khẩu hiện tại *'),
                            obscureText: true, // Ẩn mật khẩu
                            validator: (value) => value!.isEmpty ? 'Không được để trống' : null,
                          ),
                          SizedBox(height: 15),
                          TextFormField(
                            controller: _newPasswordController,
                            decoration: InputDecoration(labelText: 'Mật khẩu mới *'),
                            obscureText: true,
                            validator: (value) => (value?.length ?? 0) < 6 ? 'Ít nhất 6 ký tự' : null,
                          ),
                          SizedBox(height: 15),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(labelText: 'Xác nhận mật khẩu mới *'),
                            obscureText: true,
                            validator: (value) {
                              if (value != _newPasswordController.text) {
                                return 'Mật khẩu không khớp';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: Text('Hủy'),
                      // Vô hiệu hóa nút Hủy khi đang loading
                      onPressed: _dialogIsLoading ? null : () => Navigator.of(dialogContext).pop(),
                    ),
                    ElevatedButton(
                      // Hiển thị loading indicator hoặc chữ 'Lưu'
                      child: _dialogIsLoading ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('Lưu'),
                      // Vô hiệu hóa nút Lưu khi đang loading
                      onPressed: _dialogIsLoading ? null : () async {
                        // Validate form trước khi gửi
                        if (_dialogFormKey.currentState!.validate()) {
                          setDialogState(() { _dialogIsLoading = true; }); // Bật loading

                          // Lấy AuthProvider (không listen) để gọi hàm đổi mật khẩu
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          bool success = await authProvider.changePassword(
                              currentPassword: _currentPasswordController.text,
                              newPassword: _newPasswordController.text,
                              confirmNewPassword: _confirmPasswordController.text
                          );

                          // Chỉ thực hiện thao tác UI nếu dialog còn hiển thị
                          if (Navigator.of(dialogContext).canPop()){
                            setDialogState(() { _dialogIsLoading = false; }); // Tắt loading
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đổi mật khẩu thành công!'), backgroundColor: Colors.green));
                              Navigator.of(dialogContext).pop(); // Đóng dialog nếu thành công
                            } else {
                              // Hiển thị lỗi ngay trên dialog hoặc SnackBar
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${authProvider.authMessage}'), backgroundColor: Colors.redAccent));
                              // Không đóng dialog nếu lỗi để người dùng sửa lại
                            }
                          }
                        }
                      },
                    ),
                  ],
                );
              }
          );
        }
    );
  }
  // ============================================

  @override
  Widget build(BuildContext context) {
    // Lấy thông tin user từ AuthProvider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final fullName = authProvider.fullName ?? 'Chưa cập nhật';
    final username = authProvider.username ?? 'N/A';
    final email = authProvider.email ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: Text('Cài đặt tài khoản'),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ảnh đại diện và tên (Không đổi)
            Center( /* ... code cũ ... */
              child: Column(
                children: [
                  CircleAvatar( radius: 50, backgroundColor: Theme.of(context).primaryColorLight, child: Icon( Icons.person_outline, size: 60, color: Theme.of(context).primaryColor, ), ),
                  SizedBox(height: 15),
                  Text( fullName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), ),
                  SizedBox(height: 5),
                  Text( username, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]), ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).scale(begin: Offset(0.8, 0.8)),
            SizedBox(height: 30),

            // Card thông tin (Không đổi)
            Text('Thông tin cá nhân', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Card( /* ... code cũ ... */
              elevation: 0, shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200) ),
              child: Padding( padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column( children: [ _buildInfoRow(Icons.badge_outlined, 'Họ và Tên', fullName), Divider(indent: 16, endIndent: 16), _buildInfoRow(Icons.email_outlined, 'Email', email), ], ),
              ),
            ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1),
            SizedBox(height: 30),

            Text('Bảo mật', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

            // ===== SỬA NÚT ĐỔI MẬT KHẨU =====
            _buildSettingItem( // Dùng lại hàm build item cho đẹp
                context: context,
                icon: Icons.lock_outline,
                title: 'Đổi mật khẩu',
                onTap: () {
                  _showChangePasswordDialog(context); // Gọi hàm hiển thị dialog
                },
                delay: 600.ms
            ),
            // ===============================

            SizedBox(height: 30),

            // Nút Đăng xuất (Đã thêm dialog xác nhận)
            ElevatedButton.icon(
              icon: Icon(Icons.logout, color: Colors.red[700]),
              label: Text('Đăng xuất', style: TextStyle(color: Colors.red[700])),
              onPressed: () {
                showDialog( context: context, builder: (ctx) => AlertDialog( title: Text('Xác nhận đăng xuất'), content: Text('Bạn có chắc muốn đăng xuất khỏi tài khoản?'), actions: [ TextButton( child: Text('Hủy'), onPressed: () => Navigator.of(ctx).pop(), ), TextButton( child: Text('Đăng xuất', style: TextStyle(color: Colors.red)), onPressed: (){ Navigator.of(ctx).pop(); Provider.of<AuthProvider>(context, listen: false).logout(); }, ), ], ) );
              },
              style: ElevatedButton.styleFrom( backgroundColor: Colors.red[50], elevation: 0, padding: EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), ),
            ).animate().fadeIn(delay: 800.ms),

          ],
        ),
      ),
    );
  }

  // Widget con để hiển thị 1 dòng thông tin trong Card (Không đổi)
  Widget _buildInfoRow(IconData icon, String label, String value) {
    // ... code cũ ...
    return ListTile( leading: Icon(icon, color: Colors.grey[600], size: 22), title: Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 14)), subtitle: Text( value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87), ), dense: true, );
  }

  // Widget con cho các mục cài đặt (Không đổi)
  Widget _buildSettingItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Duration delay = Duration.zero
  }) {
    // ... code cũ ...
    return Card( elevation: 0, shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200) ), child: ListTile( leading: Icon(icon, color: Colors.grey[600]), title: Text(title), trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey), onTap: onTap, ), ).animate().fadeIn(delay: delay).slideX(begin: 0.1);
  }
}