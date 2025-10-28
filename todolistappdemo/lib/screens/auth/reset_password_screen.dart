// File: lib/screens/auth/reset_password_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart'; // Để quay về Login
import 'package:flutter_animate/flutter_animate.dart';


class ResetPasswordScreen extends StatefulWidget {
  // Nhận email và token từ link (hoặc Navigator arguments)
  final String email;
  final String token;

  ResetPasswordScreen({required this.email, required this.token});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitReset() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() { _isLoading = true; });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = await authProvider.resetPassword(
        email: widget.email, // Lấy từ widget
        token: widget.token, // Lấy từ widget
        newPassword: _newPasswordController.text,
        confirmNewPassword: _confirmPasswordController.text
    );

    if (mounted) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.authMessage),
          backgroundColor: success ? Colors.green : Colors.redAccent,
        ),
      );
      if (success) {
        // Đặt lại thành công, quay về màn hình Login
        Navigator.of(context).popUntil((route) => route.isFirst); // Quay về màn hình đầu tiên (Login)
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đặt lại mật khẩu'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(30.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Nhập mật khẩu mới cho tài khoản:\n${widget.email}', // Hiển thị email
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ).animate().fadeIn(),
                SizedBox(height: 20),
                // Ô nhập Token (Tạm thời để test, sau này sẽ ẩn đi)
                // TextFormField(
                //   initialValue: widget.token, // Hiển thị token nhận được
                //   decoration: InputDecoration(labelText: 'Token (Từ Email)'),
                //   readOnly: true, // Không cho sửa
                // ),
                // SizedBox(height: 20),
                TextFormField(
                  controller: _newPasswordController,
                  decoration: InputDecoration(labelText: 'Mật khẩu mới *', prefixIcon: Icon(Icons.lock_outline)),
                  obscureText: true,
                  validator: (value) => (value?.length ?? 0) < 6 ? 'Ít nhất 6 ký tự' : null,
                ).animate().fadeIn(delay: 200.ms),
                SizedBox(height: 20),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(labelText: 'Xác nhận mật khẩu *', prefixIcon: Icon(Icons.lock_reset_outlined)),
                  obscureText: true,
                  validator: (value) => value != _newPasswordController.text ? 'Mật khẩu không khớp' : null,
                ).animate().fadeIn(delay: 400.ms),
                SizedBox(height: 30),
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _submitReset,
                  child: Text('Đặt lại mật khẩu'),
                ).animate().fadeIn(delay: 600.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}