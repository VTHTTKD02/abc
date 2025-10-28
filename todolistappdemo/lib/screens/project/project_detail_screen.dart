// File: lib/screens/project/project_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../models/project_model.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../task/create_task_screen.dart';
import '../task/task_detail_screen.dart';
import 'project_members_screen.dart'; // <-- ĐẢM BẢO ĐÃ IMPORT FILE NÀY

enum StatusFilter { All, ToDo, InProgress, Done }

class ProjectDetailScreen extends StatefulWidget {
  final Project project;

  ProjectDetailScreen({required this.project});

  @override
  _ProjectDetailScreenState createState() => _ProjectDetailScreenState();
}

// ===== BẮT ĐẦU CLASS STATE =====
class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  StatusFilter _selectedFilter = StatusFilter.All;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false)
          .fetchTasks(widget.project.projectId);
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Hàm build cột (Không đổi)
  Widget _buildTaskColumn(BuildContext context, String title, List<Task> tasks, Color headerColor) {
    return Container( /* ... code cũ ... */
      width: 280, margin: EdgeInsets.all(8), padding: EdgeInsets.all(10), decoration: BoxDecoration( color: Colors.grey[200], borderRadius: BorderRadius.circular(12), ),
      child: Column( crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container( padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12), decoration: BoxDecoration( color: headerColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8), ),
            child: Text( "$title (${tasks.length})", style: TextStyle( fontWeight: FontWeight.bold, fontSize: 16, color: headerColor, ), ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: ListView.builder( itemCount: tasks.length,
              itemBuilder: (ctx, index) {
                final task = tasks[index];
                return _buildTaskCard(task).animate().fadeIn(delay: (index * 100).ms, duration: 400.ms).slideY(begin: 0.2);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Hàm build thẻ Task (Không đổi)
  Widget _buildTaskCard(Task task) {
    return Card( margin: EdgeInsets.only(bottom: 10), elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(task.taskName, style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Giao cho: ${task.assigneeName ?? "Chưa gán"}'),
        trailing: task.isRecurring ? Icon(Icons.repeat, size: 18, color: Colors.blue) : null,
        onTap: () {
          print('>>> TAPPED on Task ID: ${task.taskId}');
          Navigator.of(context).push( MaterialPageRoute( builder: (ctx) => TaskDetailScreen( taskId: task.taskId, taskName: task.taskName, ), ), );
        },
      ),
    );
  }

  // Hàm build bộ lọc (Không đổi)
  Widget _buildFilterChips() {
    return Padding( /* ... code cũ ... */
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SingleChildScrollView( scrollDirection: Axis.horizontal, padding: EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: StatusFilter.values.map((filter) {
            bool isSelected = _selectedFilter == filter;
            String label; IconData? icon;
            switch (filter) { case StatusFilter.All: label = 'Tất cả'; icon = Icons.list_alt; break; case StatusFilter.ToDo: label = 'Cần làm'; icon = Icons.assignment_late_outlined; break; case StatusFilter.InProgress: label = 'Đang làm'; icon = Icons.hourglass_top_rounded; break; case StatusFilter.Done: label = 'Hoàn thành'; icon = Icons.check_circle_outline; break; }
            return Padding( padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ChoiceChip( label: Text(label), avatar: icon != null ? Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.black54) : null, selected: isSelected, onSelected: (selected) { setState(() { _selectedFilter = filter; }); }, selectedColor: Theme.of(context).primaryColor, labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87), backgroundColor: Colors.white, elevation: isSelected ? 2 : 0, shape: StadiumBorder(side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300)), ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final allTasks = taskProvider.tasksForProject(widget.project.projectId);
    final filteredTasks = allTasks.where((task) { /* ... code lọc ... */
      final nameMatches = task.taskName.toLowerCase().contains(_searchQuery.toLowerCase());
      bool statusMatches = false;
      switch (_selectedFilter) { case StatusFilter.All: statusMatches = true; break; case StatusFilter.ToDo: statusMatches = task.status == 0; break; case StatusFilter.InProgress: statusMatches = task.status == 1; break; case StatusFilter.Done: statusMatches = task.status == 2; break; }
      return nameMatches && statusMatches;
    }).toList();
    final todoTasks = filteredTasks.where((t) => t.status == 0).toList();
    final inProgressTasks = filteredTasks.where((t) => t.status == 1).toList();
    final doneTasks = filteredTasks.where((t) => t.status == 2).toList();

    return Scaffold(
      appBar: AppBar(
        title: Container( /* ... code ô tìm kiếm ... */
          height: 40, decoration: BoxDecoration( color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(20), ),
          child: TextField( controller: _searchController, decoration: InputDecoration( contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 15), hintText: 'Tìm công việc...', border: InputBorder.none, prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20), suffixIcon: _searchQuery.isNotEmpty ? IconButton( icon: Icon(Icons.clear, color: Colors.grey, size: 20), onPressed: () { _searchController.clear(); }, ) : null, ), ),
        ),
        elevation: 1,
        // ===== THÊM NÚT "XEM THÀNH VIÊN" VÀO ACTIONS =====
        actions: [
          IconButton(
            icon: Icon(Icons.group_outlined), // Icon nhóm người
            tooltip: 'Xem thành viên',
            onPressed: () {
              // Điều hướng đến màn hình thành viên
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => ProjectMembersScreen(project: widget.project), // Truyền project sang
                ),
              );
            },
          ),
        ],
        // ===============================================
        bottom: PreferredSize( preferredSize: Size.fromHeight(50.0), child: _buildFilterChips(), ),
      ),
      body: Consumer<TaskProvider>(
        builder: (context, provider, child) {
          // ... (code xử lý loading, error) ...
          if (provider.status == TaskStatus.Loading) { return Center(child: CircularProgressIndicator()); }
          if (provider.status == TaskStatus.Error) { return Center(child: Text('Lỗi: ${provider.errorMessage}')); }

          List<Widget> columnsToShow = [];
          // ... (code thêm cột vào columnsToShow dựa trên filter và list task) ...
          if ((_selectedFilter == StatusFilter.All || _selectedFilter == StatusFilter.ToDo) && todoTasks.isNotEmpty) { columnsToShow.add(_buildTaskColumn(context, 'Cần làm (ToDo)', todoTasks, Colors.blue)); }
          if ((_selectedFilter == StatusFilter.All || _selectedFilter == StatusFilter.InProgress) && inProgressTasks.isNotEmpty) { columnsToShow.add(_buildTaskColumn(context, 'Đang làm (In Progress)', inProgressTasks, Colors.orange)); }
          if ((_selectedFilter == StatusFilter.All || _selectedFilter == StatusFilter.Done) && doneTasks.isNotEmpty) { columnsToShow.add(_buildTaskColumn(context, 'Hoàn thành (Done)', doneTasks, Colors.green)); }

          // ... (code xử lý khi columnsToShow rỗng) ...
          if (columnsToShow.isEmpty && allTasks.isNotEmpty) { return Center( child: Text( 'Không tìm thấy công việc nào khớp.', style: TextStyle(fontSize: 16, color: Colors.grey[600]), ).animate().fadeIn(), ); }

          return ListView( scrollDirection: Axis.horizontal, padding: EdgeInsets.all(8), children: columnsToShow, ).animate().fadeIn(duration: 400.ms);
        },
      ),
      floatingActionButton: FloatingActionButton( // Nút Tạo Task (Không đổi)
        onPressed: () { Navigator.of(context).push( MaterialPageRoute( builder: (ctx) => CreateTaskScreen( projectId: widget.project.projectId, ), ), ); },
        child: Icon(Icons.add), tooltip: 'Tạo công việc mới',
      ),
    );
  }
}