// File: lib/screens/auth/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() { _isLoading = true; });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = await authProvider.forgotPassword(_emailController.text);

    if (mounted) {
      setState(() { _isLoading = false; });
      // Luôn hiển thị message trả về từ provider (thành công hay thất bại đều có message)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.authMessage),
          backgroundColor: success ? Colors.green : Colors.orangeAccent, // Cam nếu chỉ là thông báo chung
        ),
      );
      // Không tự động quay lại, để người dùng đọc thông báo
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quên mật khẩu'),
        elevation: 0, // Bỏ đổ bóng
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
                  'Nhập email đã đăng ký của bạn để nhận hướng dẫn đặt lại mật khẩu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ).animate().fadeIn(delay: 200.ms),
                SizedBox(height: 30),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value!.isEmpty || !value.contains('@') ? 'Email không hợp lệ' : null,
                ).animate().fadeIn(delay: 400.ms),
                SizedBox(height: 30),
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _submitRequest,
                  child: Text('Gửi yêu cầu'),
                ).animate().fadeIn(delay: 600.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}