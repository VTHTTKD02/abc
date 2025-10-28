// File: lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart'; // 1. Import animation
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() { _isLoading = true; });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = await authProvider.register(
      fullName: _fullNameController.text,
      email: _emailController.text,
      phoneNumber: _phoneController.text,
      username: _usernameController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (mounted) {
      setState(() { _isLoading = false; });
      // Hiển thị thông báo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.authMessage),
          backgroundColor: success ? Colors.green : Colors.redAccent,
        ),
      );

      if (success) {
        // Đăng ký thành công, quay lại màn hình đăng nhập
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 2. Thêm hiệu ứng cho các Widget
    final fields = [
      Text(
        'Tạo tài khoản mới',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(height: 30),
      TextFormField(
        controller: _fullNameController,
        decoration: InputDecoration(labelText: 'Họ và Tên', prefixIcon: Icon(Icons.person_outline)),
        validator: (value) => value!.isEmpty ? 'Không được để trống' : null,
      ),
      SizedBox(height: 15),
      TextFormField(
        controller: _phoneController,
        decoration: InputDecoration(labelText: 'Số điện thoại', prefixIcon: Icon(Icons.phone_outlined)),
        keyboardType: TextInputType.phone,
        validator: (value) => value!.isEmpty ? 'Không được để trống' : null,
      ),
      SizedBox(height: 15),
      TextFormField(
        controller: _emailController,
        decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
        keyboardType: TextInputType.emailAddress,
        validator: (value) =>
        value!.isEmpty || !value.contains('@') ? 'Email không hợp lệ' : null,
      ),
      SizedBox(height: 15),
      TextFormField(
        controller: _usernameController,
        decoration: InputDecoration(labelText: 'Tên tài khoản', prefixIcon: Icon(Icons.account_circle_outlined)),
        validator: (value) => value!.isEmpty ? 'Không được để trống' : null,
      ),
      SizedBox(height: 15),
      TextFormField(
        controller: _passwordController,
        obscureText: true,
        decoration: InputDecoration(labelText: 'Mật khẩu', prefixIcon: Icon(Icons.lock_outline)),
        validator: (value) =>
        value!.length < 6 ? 'Mật khẩu cần ít nhất 6 ký tự' : null,
      ),
      SizedBox(height: 15),
      TextFormField(
        controller: _confirmPasswordController,
        obscureText: true,
        decoration: InputDecoration(labelText: 'Nhập lại mật khẩu', prefixIcon: Icon(Icons.lock_reset_outlined)),
        validator: (value) {
          if (value != _passwordController.text) {
            return 'Mật khẩu không khớp';
          }
          return null;
        },
      ),
      SizedBox(height: 30),
      _isLoading
          ? Center(child: CircularProgressIndicator())
          : ElevatedButton(
        onPressed: _register,
        child: Text('Đăng ký'),
      ),
      SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Bạn đã có tài khoản? '),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Quay lại trang đăng nhập
            },
            child: Text('Đăng nhập ngay'),
          ),
        ],
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // AppBar trong suốt
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Nút back màu đen
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                // 3. Sử dụng list `fields` và thêm hiệu ứng
                children: fields.animate(
                  // Thêm hiệu ứng cho TẤT CẢ widget trong list
                  interval: 100.ms, // Mỗi item cách nhau 100ms
                  effects: [
                    FadeEffect(duration: 400.ms, delay: 200.ms),
                    SlideEffect(begin: Offset(0, 0.2), duration: 400.ms)
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}