// File: lib/screens/task/my_tasks_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/project_provider.dart'; // Vẫn cần để lọc dự án
import '../../models/task_model.dart';
import '../../models/project_model.dart';
import 'create_task_screen.dart';
import 'task_detail_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

// ===== 1. ĐỊNH NGHĨA ENUM SẮP XẾP =====
enum SortCriteria {
  CreatedDateDesc, // Mới nhất (Mặc định)
  CreatedDateAsc,  // Cũ nhất
  DueDateAsc,      // Hết hạn gần nhất
  PriorityDesc     // Ưu tiên cao nhất
}
// =====================================

class MyTasksScreen extends StatefulWidget {
  @override
  _MyTasksScreenState createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  // State cho bộ lọc (giữ nguyên)
  int? _selectedProjectId;
  int? _selectedStatusFilter;

  // ===== 2. THÊM STATE CHO SẮP XẾP =====
  SortCriteria _sortBy = SortCriteria.CreatedDateDesc; // Mặc định
  // ===================================

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).fetchMyTasks();
      Provider.of<ProjectProvider>(context, listen: false).fetchProjects();
    });
  }

  // Hàm build thẻ Task (Không đổi)
  Widget _buildMyTaskCard(BuildContext context, Task task) { /* ... code cũ ... */
    final formattedDate = task.dueDate != null ? DateFormat('dd/MM').format(task.dueDate!) : null;
    final statusMap = { 0: {'text': 'Cần làm', 'color': Colors.blue.shade600}, 1: {'text': 'Đang làm', 'color': Colors.orange.shade700}, 2: {'text': 'Hoàn thành', 'color': Colors.green.shade600}, };
    final statusInfo = statusMap[task.status] ?? {'text': '?', 'color': Colors.grey};
    return Card( margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6), elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon( task.status == 2 ? Icons.check_circle : Icons.radio_button_unchecked, color: statusInfo['color'] as Color, ),
        title: Text(task.taskName, style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text( 'Dự án: ${task.projectName ?? "N/A"}\nNgười giao: ${task.reporterName}', style: TextStyle(color: Colors.grey[700], fontSize: 13), ),
        trailing: Column( mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end,
          children: [ Text( statusInfo['text'] as String, style: TextStyle(color: statusInfo['color'] as Color, fontWeight: FontWeight.bold, fontSize: 13) ), if(formattedDate != null) ...[ SizedBox(height: 4), Text('Hạn: $formattedDate', style: TextStyle(fontSize: 12, color: Colors.grey[600])), ] ],
        ),
        onTap: () { Navigator.of(context).push( MaterialPageRoute( builder: (ctx) => TaskDetailScreen( taskId: task.taskId, taskName: task.taskName, ), ), ); },
      ),
    );
  }

  // Hàm build thanh lọc (Không đổi)
  Widget _buildFilterBar() { /* ... code cũ ... */
    final projects = Provider.of<ProjectProvider>(context, listen: false).projects;
    return Container( padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5), color: Theme.of(context).appBarTheme.backgroundColor ?? Colors.white,
      child: Row(
        children: [
          Expanded( child: DropdownButtonHideUnderline( child: DropdownButton<int?>( value: _selectedProjectId, isExpanded: true, hint: Text('Tất cả dự án', style: TextStyle(fontSize: 14)), icon: Icon(Icons.filter_list_alt), items: [ DropdownMenuItem<int?>( value: null, child: Text('Tất cả dự án', style: TextStyle(fontWeight: FontWeight.bold)), ), ...projects.map((Project project) { return DropdownMenuItem<int?>( value: project.projectId, child: Text(project.projectName, overflow: TextOverflow.ellipsis), ); }).toList(), ], onChanged: (value) { setState(() { _selectedProjectId = value; }); }, ), ), ),
          VerticalDivider(width: 20, thickness: 1, indent: 10, endIndent: 10),
          Expanded( child: DropdownButtonHideUnderline( child: DropdownButton<int?>( value: _selectedStatusFilter, isExpanded: true, hint: Text('Trạng thái', style: TextStyle(fontSize: 14)), icon: Icon(Icons.flag_outlined), items: [ DropdownMenuItem<int?>(value: null, child: Text('Tất cả trạng thái', style: TextStyle(fontWeight: FontWeight.bold))), DropdownMenuItem<int?>(value: 0, child: Text('🔵 Cần làm')), DropdownMenuItem<int?>(value: 1, child: Text('🟠 Đang làm')), DropdownMenuItem<int?>(value: 2, child: Text('🟢 Hoàn thành')), ], onChanged: (value) { setState(() { _selectedStatusFilter = value; }); }, ), ), ),
        ],
      ),
    );
  }

  // ===== 3. HÀM LẤY TEXT CHO NÚT SẮP XẾP =====
  String _getSortLabel(SortCriteria criteria) {
    switch (criteria) {
      case SortCriteria.CreatedDateDesc: return 'Mới nhất';
      case SortCriteria.CreatedDateAsc: return 'Cũ nhất';
      case SortCriteria.DueDateAsc: return 'Hạn gần nhất';
      case SortCriteria.PriorityDesc: return 'Ưu tiên cao nhất';
      default: return '';
    }
  }
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Công việc của tôi'),
        elevation: 1,
        bottom: PreferredSize( preferredSize: Size.fromHeight(50.0), child: _buildFilterBar(), ),
        // ===== 4. THÊM NÚT SẮP XẾP VÀO ACTIONS =====
        actions: [
          PopupMenuButton<SortCriteria>(
            initialValue: _sortBy, // Hiển thị giá trị đang chọn
            onSelected: (SortCriteria result) {
              setState(() { _sortBy = result; }); // Cập nhật state khi chọn
            },
            icon: Icon(Icons.sort), // Icon sắp xếp
            tooltip: 'Sắp xếp theo',
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortCriteria>>[
              // Tạo các lựa chọn sắp xếp
              PopupMenuItem<SortCriteria>( value: SortCriteria.CreatedDateDesc, child: Text(_getSortLabel(SortCriteria.CreatedDateDesc)), ),
              PopupMenuItem<SortCriteria>( value: SortCriteria.CreatedDateAsc, child: Text(_getSortLabel(SortCriteria.CreatedDateAsc)), ),
              PopupMenuItem<SortCriteria>( value: SortCriteria.DueDateAsc, child: Text(_getSortLabel(SortCriteria.DueDateAsc)), ),
              PopupMenuItem<SortCriteria>( value: SortCriteria.PriorityDesc, child: Text(_getSortLabel(SortCriteria.PriorityDesc)), ),
            ],
            // Hiển thị text của lựa chọn hiện tại bên cạnh icon (tùy chọn)
            // child: Padding(
            //    padding: const EdgeInsets.only(right: 8.0),
            //    child: Text(_getSortLabel(_sortBy), style: TextStyle(fontSize: 12)),
            //  ),
          ),
        ],
        // =======================================
      ),
      body: Consumer<TaskProvider>(
        builder: (context, provider, child) {
          final status = provider.myTasksStatus;
          final allMyTasks = provider.myTasks;

          // Lọc danh sách (Không đổi)
          final filteredTasks = allMyTasks.where((task) { /* ... code lọc ... */
            final projectMatch = _selectedProjectId == null || task.projectId == _selectedProjectId;
            final statusMatch = _selectedStatusFilter == null || task.status == _selectedStatusFilter;
            return projectMatch && statusMatch;
          }).toList();

          // ===== 5. SẮP XẾP DANH SÁCH ĐÃ LỌC =====
          filteredTasks.sort((a, b) {
            switch (_sortBy) {
              case SortCriteria.CreatedDateAsc:
                return a.createdAt.compareTo(b.createdAt);
              case SortCriteria.DueDateAsc:
              // Xử lý trường hợp DueDate là null (để cuối)
                if (a.dueDate == null && b.dueDate == null) return 0;
                if (a.dueDate == null) return 1; // a null -> để sau b
                if (b.dueDate == null) return -1; // b null -> để sau a
                return a.dueDate!.compareTo(b.dueDate!);
              case SortCriteria.PriorityDesc:
              // Ưu tiên cao (2) lên đầu, thấp (0) xuống cuối
                return b.priority.compareTo(a.priority);
              case SortCriteria.CreatedDateDesc: // Mặc định
              default:
                return b.createdAt.compareTo(a.createdAt);
            }
          });
          // ========================================


          // Hiển thị loading/error/empty (Không đổi)
          if (status == TaskStatus.Loading && allMyTasks.isEmpty) { /* ... loading ... */ }
          if (status == TaskStatus.Error && allMyTasks.isEmpty) { /* ... error ... */ }
          if (filteredTasks.isEmpty) { /* ... empty ... */ }

          // Hiển thị danh sách đã lọc VÀ sắp xếp
          return RefreshIndicator(
            onRefresh: () => Provider.of<TaskProvider>(context, listen: false).fetchMyTasks(forceRefresh: true),
            child: ListView.builder(
              padding: EdgeInsets.only(top: 10, bottom: 80),
              itemCount: filteredTasks.length, // Dùng list đã lọc và sắp xếp
              itemBuilder: (ctx, index) {
                // Build thẻ task với dữ liệu đã lọc và sắp xếp
                return _buildMyTaskCard(context, filteredTasks[index])
                    .animate().fadeIn(delay: (index * 50).ms, duration: 300.ms).slideX(begin: -0.05);
              },
            ),
          );
        },
      ),
      // ===== THÊM FloatingActionButton VÀO ĐÂY =====
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Mở CreateTaskScreen và truyền projectId là null
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => CreateTaskScreen(projectId: null), // <-- QUAN TRỌNG
            ),
          );
        },
        child: Icon(Icons.add_task_outlined), // Icon khác
        tooltip: 'Tạo việc cá nhân',
      ),
    );
  }
}