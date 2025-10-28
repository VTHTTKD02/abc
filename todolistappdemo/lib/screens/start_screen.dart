import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'admin/admin_screen.dart'; // Import màn hình Admin
import 'home/home_screen.dart'; // Import màn hình Home

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lắng nghe AuthProvider để xác định roles
    final authProvider = Provider.of<AuthProvider>(context);

    // Lấy roles (Chúng ta giả định AuthProvider đã được cập nhật để có getter roles)
    final List<String> userRoles = authProvider.roles ?? [];

    // Kiểm tra quyền Admin
    if (userRoles.contains('Admin')) {
      print("INFO: User is Admin. Redirecting to AdminScreen.");
      return AdminScreen();
    } else {
      print("INFO: User is regular User. Redirecting to HomeScreen.");
      return HomeScreen();
    }
  }
}