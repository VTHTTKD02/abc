// File: lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/project_provider.dart';
import 'providers/task_provider.dart';
import 'providers/department_provider.dart';
import 'providers/user_provider.dart';
import 'providers/project_member_provider.dart';
import 'providers/comment_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/notification_service.dart'; // <-- 1. IMPORT

// ===== 2. SỬA HÀM MAIN THÀNH ASYNC =====
Future<void> main() async {
  // Đảm bảo Flutter đã sẵn sàng
  WidgetsFlutterBinding.ensureInitialized();
  // Khởi tạo Notification Service TRƯỚC KHI CHẠY APP
  await NotificationService().init();
  // =====================================

  runApp(MyApp()); // Chạy app sau khi đã init
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // --- Bảng màu Wework (Ví dụ) ---
    const weworkPrimaryColor = Color(0xFF007BFF);
    const weworkAccentColor = Color(0xFF6C757D);
    const weworkBackgroundColor = Color(0xFFF8F9FA);
    const weworkCardColor = Colors.white;
    // --- Kết thúc Bảng màu ---

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => AuthProvider()),
        ChangeNotifierProvider(create: (ctx) => ProjectProvider()),
        ChangeNotifierProvider(create: (ctx) => TaskProvider()),
        ChangeNotifierProvider(create: (ctx) => DepartmentProvider()),
        ChangeNotifierProvider(create: (ctx) => UserProvider()),
        ChangeNotifierProvider(create: (ctx) => ProjectMemberProvider()),
        ChangeNotifierProvider(create: (ctx) => CommentProvider()),
      ],
      child: MaterialApp(
        title: 'Quản lý công việc',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: weworkPrimaryColor,
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(
            secondary: weworkAccentColor,
            background: weworkBackgroundColor,
          ),
          scaffoldBackgroundColor: weworkBackgroundColor,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 1,
            titleTextStyle: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
            iconTheme: IconThemeData(color: Colors.black54),
          ),
          textTheme: GoogleFonts.latoTextTheme(Theme.of(context).textTheme),
          cardTheme: CardThemeData(
            color: weworkCardColor,
            elevation: 1.5,
            shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(8), ),
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          ),
          inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder( borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300, width: 1), ),
              enabledBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300, width: 1), ),
              focusedBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: weworkPrimaryColor, width: 1.5), ),
              prefixIconColor: Colors.grey[600],
              hintStyle: TextStyle(color: Colors.grey[500])
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: weworkPrimaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(8), ),
              textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              elevation: 2,
            ),
          ),
          textButtonTheme: TextButtonThemeData( style: TextButton.styleFrom( foregroundColor: weworkPrimaryColor, textStyle: TextStyle(fontWeight: FontWeight.w600) ) ),
          floatingActionButtonTheme: FloatingActionButtonThemeData( backgroundColor: weworkPrimaryColor, foregroundColor: Colors.white, ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Consumer<AuthProvider>(
          builder: (ctx, auth, _) => auth.isAuthenticated
              ? HomeScreen()
              : LoginScreen(),
        ),
      ),
    );
  }
}