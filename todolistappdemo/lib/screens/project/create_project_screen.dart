// File: lib/screens/project/create_project_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/department_provider.dart';
import '../../models/department_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CreateProjectScreen extends StatefulWidget {
  @override
  _CreateProjectScreenState createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  int? _selectedDepartmentId;

  @override
  void initState() {
    super.initState();
    // Gọi API lấy phòng ban khi màn hình mở
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DepartmentProvider>(context, listen: false).fetchDepartments();
    });
  }

  // (Hàm _pickDate và _submitForm giữ nguyên)
  Future<void> _pickDate(bool isStartDate) async { /* ... code cũ ... */
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }
  Future<void> _submitForm() async { /* ... code cũ ... */
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng chọn ngày bắt đầu'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() { _isLoading = true; });

    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    bool success = await projectProvider.createProject(
      name: _nameController.text,
      description: _descController.text,
      startDate: _startDate!,
      endDate: _endDate,
      departmentId: _selectedDepartmentId,
    );

    if (mounted) {
      setState(() { _isLoading = false; });
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tạo dự án thành công!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(); // Quay lại HomeScreen
      } else {
        // Hiển thị lỗi từ provider
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${projectProvider.errorMessage}'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }


  // ===== 1. TẠO HÀM HIỂN THỊ DIALOG =====
  Future<void> _showCreateDepartmentDialog() async {
    final _dialogFormKey = GlobalKey<FormState>();
    final _deptNameController = TextEditingController();
    final _deptDescController = TextEditingController();
    bool _isCreating = false; // Trạng thái loading cho dialog

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Không đóng khi nhấn ra ngoài
      builder: (BuildContext dialogContext) {
        // Dùng StatefulBuilder để cập nhật trạng thái loading trong dialog
        return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text('Tạo phòng ban mới'),
                content: SingleChildScrollView(
                  child: Form(
                    key: _dialogFormKey,
                    child: ListBody(
                      children: <Widget>[
                        TextFormField(
                          controller: _deptNameController,
                          decoration: InputDecoration(labelText: 'Tên phòng ban *'),
                          validator: (value) => value!.isEmpty ? 'Không được để trống' : null,
                        ),
                        SizedBox(height: 15),
                        TextFormField(
                          controller: _deptDescController,
                          decoration: InputDecoration(labelText: 'Mô tả'),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('Hủy'),
                    onPressed: _isCreating ? null : () { // Vô hiệu hóa khi đang tạo
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                  ElevatedButton(
                    child: _isCreating ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('Tạo'),
                    onPressed: _isCreating ? null : () async { // Vô hiệu hóa khi đang tạo
                      if (_dialogFormKey.currentState!.validate()) {
                        setDialogState(() { _isCreating = true; }); // Bắt đầu loading

                        final deptProvider = Provider.of<DepartmentProvider>(context, listen: false);
                        bool success = await deptProvider.createDepartment(
                          _deptNameController.text,
                          _deptDescController.text,
                        );

                        if (mounted) { // Kiểm tra Widget chính còn tồn tại không
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Tạo phòng ban thành công!'), backgroundColor: Colors.green),
                            );
                            // Tải lại danh sách phòng ban
                            await deptProvider.fetchDepartments(forceRefresh: true);
                            // Tự động chọn phòng ban vừa tạo
                            if (deptProvider.departments.isNotEmpty) {
                              setState(() {
                                _selectedDepartmentId = deptProvider.departments.first.departmentId;
                              });
                            }
                            Navigator.of(dialogContext).pop(); // Đóng dialog
                          } else {
                            // Hiển thị lỗi trong dialog hoặc SnackBar
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi: ${deptProvider.errorMessage}'), backgroundColor: Colors.redAccent),
                            );
                            setDialogState(() { _isCreating = false; }); // Kết thúc loading
                          }
                        }
                      }
                    },
                  ),
                ],
              );
            }
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tạo dự án mới'),
        elevation: 1,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ... (TextFormFields cho Tên và Mô tả) ...
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Tên dự án *',
                  prefixIcon: Icon(Icons.folder_outlined),
                ),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên dự án' : null,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: 'Mô tả',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 20),

              // Dropdown phòng ban (đã có)
              Consumer<DepartmentProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.departments.isEmpty) { // Chỉ loading khi list trống
                    return Center(child: CircularProgressIndicator());
                  }

                  // Hiển thị dropdown kể cả khi list trống (để nút Tạo mới hiện ra)
                  return DropdownButtonFormField<int>(
                    value: _selectedDepartmentId,
                    decoration: InputDecoration(
                      labelText: 'Phòng ban (Tùy chọn)',
                      prefixIcon: Icon(Icons.corporate_fare_outlined),
                    ),
                    items: provider.departments.map((Department dept) {
                      return DropdownMenuItem<int>(
                        value: dept.departmentId,
                        child: Text(dept.departmentName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDepartmentId = value;
                      });
                    },
                    // Hiển thị gợi ý nếu list trống
                    hint: provider.departments.isEmpty ? Text('Chưa có phòng ban nào') : null,
                  );
                },
              ),

              // ===== 2. THÊM NÚT TẠO PHÒNG BAN =====
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: Icon(Icons.add_circle_outline, size: 18),
                  label: Text('Tạo phòng ban mới'),
                  onPressed: _showCreateDepartmentDialog, // Gọi hàm hiển thị dialog
                ),
              ),
              // ===================================

              SizedBox(height: 10), // Giảm khoảng cách sau nút
              // ... (Phần chọn ngày và nút Tạo dự án) ...
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _startDate == null
                          ? 'Ngày bắt đầu *'
                          : 'Bắt đầu: ${DateFormat('dd/MM/yyyy').format(_startDate!)}',
                    ),
                  ),
                  TextButton(
                    onPressed: () => _pickDate(true),
                    child: Text('Chọn ngày'),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _endDate == null
                          ? 'Ngày kết thúc'
                          : 'Kết thúc: ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                    ),
                  ),
                  TextButton(
                    onPressed: () => _pickDate(false),
                    child: Text('Chọn ngày'),
                  ),
                ],
              ),
              SizedBox(height: 30),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _submitForm,
                child: Text('Tạo dự án'),
              )
            ],
          ).animate().fadeIn(duration: 400.ms),
        ),
      ),
    );
  }
}