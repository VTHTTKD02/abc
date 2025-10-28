// File: lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart'; // Import màn hình Đăng ký
import 'forgot_password_screen.dart'; // Import màn hình Quên mật khẩu

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    // 1. Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() { _isLoading = true; });

    // 2. Lấy provider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 3. Gọi hàm login, truyền 'context' vào để AuthProvider dùng cho SignalR
    bool success = await authProvider.login(
      _usernameController.text,
      _passwordController.text,
      context, // <-- Truyền context vào đây
    );

    // 4. Xử lý kết quả
    if (mounted) { // Kiểm tra xem widget còn tồn tại không
      setState(() { _isLoading = false; });
      if (!success) {
        // Nếu login thất bại, hiển thị SnackBar lỗi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.authMessage),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      // Nếu login thành công, Consumer trong main.dart sẽ tự động điều hướng
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Sử dụng màu nền từ theme (nếu có) hoặc trắng
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tiêu đề
                  Text(
                    'Chào mừng trở lại!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

                  SizedBox(height: 10),
                  Text(
                    'Đăng nhập để tiếp tục',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ).animate().fadeIn(delay: 500.ms, duration: 500.ms),

                  SizedBox(height: 40),

                  // Form Fields
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Tên tài khoản',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) => value!.isEmpty ? 'Không được để trống' : null,
                  ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.5),

                  SizedBox(height: 20),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) => value!.isEmpty ? 'Không được để trống' : null,
                  ).animate().fadeIn(delay: 900.ms).slideX(begin: 0.5),

                  // Nút Quên mật khẩu
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Điều hướng đến màn hình Forgot Password
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (ctx) => ForgotPasswordScreen()),
                        );
                      },
                      child: Text('Quên mật khẩu?'),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Nút Đăng nhập
                  _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: _login,
                    child: Text('Đăng nhập'),
                  ).animate().fadeIn(delay: 1100.ms).slideY(begin: 0.5),

                  SizedBox(height: 30),

                  // Text Đăng ký
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Bạn chưa có tài khoản? '),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => RegisterScreen(),
                          ));
                        },
                        child: Text('Đăng ký ngay'),
                      ),
                    ],
                  ).animate().fadeIn(delay: 1300.ms),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}