// File: lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_provider.dart';
import '../../models/project_model.dart';
import 'package:intl/intl.dart';
import '../../services/signalr_service.dart';
import '../project/create_project_screen.dart';
import '../project/project_detail_screen.dart';
import '../task/my_tasks_screen.dart';
// ===== 1. THÊM IMPORT CHO MÀN HÌNH SETTINGS =====
import '../settings/settings_screen.dart';


class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      Provider.of<ProjectProvider>(context, listen: false).fetchProjects();
      // ===== 3. THÊM KHỞI TẠO SIGNALR VÀO ĐÂY =====
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token != null) {
        // Dùng context của HomeScreen để init SignalR
        // (Việc này sẽ xử lý cho trường hợp tự động đăng nhập)
        print("HomeScreen: Đang khởi tạo SignalR cho tự động đăng nhập...");
        SignalRService().init(token, context);
      }
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  // Hàm build phần thân (body) - Không đổi
  Widget _buildBody(ProjectProvider projectProvider) {
    // ... code cũ ...
    switch (projectProvider.status) {
      case ProjectStatus.Loading: return Center(child: CircularProgressIndicator());
      case ProjectStatus.Error: return Center( child: Padding( padding: const EdgeInsets.all(20.0), child: Text( 'Lỗi tải dự án: ${projectProvider.errorMessage}\n\n(Token có thể đã hết hạn, vui lòng đăng xuất và đăng nhập lại)', textAlign: TextAlign.center, style: TextStyle(color: Colors.red[700]), ), ), );
      case ProjectStatus.Success: return _buildProjectList(projectProvider.projects);
      default: return Center(child: Text('Chào mừng!'));
    }
  }

  // Hàm build danh sách dự án - Không đổi
  Widget _buildProjectList(List<Project> projects) {
    if (projects.isEmpty) {
      return Center( /* ... code list rỗng ... */ child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.folder_off_outlined, size: 80, color: Colors.grey[400]), SizedBox(height: 16), Text( 'Bạn chưa có dự án nào', style: TextStyle(fontSize: 18, color: Colors.grey[600]), ), ], ).animate().fadeIn(duration: 500.ms), );
    }
    return ListView.builder( /* ... code cũ ... */
      padding: EdgeInsets.all(10), itemCount: projects.length,
      itemBuilder: (ctx, index) {
        final project = projects[index];
        final formattedDate = DateFormat('dd/MM/yyyy').format(project.startDate);
        return Card(
          elevation: 3, margin: EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            leading: CircleAvatar( backgroundColor: Colors.blue[50], child: Icon(Icons.folder_open_rounded, color: Colors.blue[600]), ),
            title: Text( project.projectName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17), ),
            subtitle: Text( 'Bắt đầu: $formattedDate\n${project.departmentName ?? 'Không thuộc phòng ban'}', style: TextStyle(color: Colors.grey[700]), ),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
            onTap: () { print('>>> TAPPED on Project ID: ${project.projectId}'); Navigator.of(context).push( MaterialPageRoute( builder: (ctx) => ProjectDetailScreen(project: project), ), ); },
          ),
        ).animate().fadeIn(delay: (index * 100).ms, duration: 400.ms).slideX(begin: -0.1);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Dự án của bạn'),
        elevation: 1,
        actions: [
          // Nút "Công việc của tôi" (Đã có)
          IconButton(
            icon: Icon(Icons.person_pin_circle_outlined),
            tooltip: 'Công việc của tôi',
            onPressed: () {
              Navigator.of(context).push( MaterialPageRoute(builder: (ctx) => MyTasksScreen()), );
            },
          ),

          // ===== 2. THÊM NÚT "CÀI ĐẶT" VÀO ĐÂY =====
          IconButton(
            icon: Icon(Icons.settings_outlined), // Icon bánh răng
            tooltip: 'Cài đặt',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => SettingsScreen()), // Mở màn hình Cài đặt
              );
            },
          ),
          // ======================================

          // Nút Đăng xuất (Đã có)
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          )
        ],
      ),
      body: _buildBody(projectProvider),
      floatingActionButton: FloatingActionButton( // Nút Tạo Dự án (Không đổi)
        onPressed: () { Navigator.of(context).push( MaterialPageRoute(builder: (ctx) => CreateProjectScreen()), ); },
        child: Icon(Icons.add), tooltip: 'Tạo dự án mới', backgroundColor: Colors.blue,
      ).animate().scale(delay: 500.ms),
    );
  }
}