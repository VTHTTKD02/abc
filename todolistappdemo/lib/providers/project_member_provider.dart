// File: lib/providers/project_member_provider.dart
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/project_member_service.dart';

enum MemberStatus { Idle, Loading, Success, Error }

class ProjectMemberProvider with ChangeNotifier {
  final ProjectMemberService _memberService = ProjectMemberService();

  // Dùng Map để lưu thành viên theo projectId
  Map<int, List<AppUser>> _membersByProject = {};
  MemberStatus _status = MemberStatus.Idle;
  String _errorMessage = '';

  // Getters
  List<AppUser> membersForProject(int projectId) => _membersByProject[projectId] ?? [];
  MemberStatus get status => _status;
  String get errorMessage => _errorMessage;

  // Lấy thành viên
  Future<void> fetchMembers(int projectId) async {
    // Không tải lại nếu đang tải
    if (_status == MemberStatus.Loading) return;

    _status = MemberStatus.Loading;
    notifyListeners();
    try {
      final members = await _memberService.getProjectMembers(projectId);
      _membersByProject[projectId] = members;
      _status = MemberStatus.Success;
      _errorMessage = '';
    } catch (e) {
      _status = MemberStatus.Error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  // Thêm thành viên
  Future<bool> addMember(int projectId, String email) async {
    _status = MemberStatus.Loading; // Có thể dùng trạng thái loading riêng
    _errorMessage = '';
    notifyListeners();
    try {
      final newMember = await _memberService.addMemberByEmail(projectId, email);
      // Thêm vào danh sách hiện tại
      if (_membersByProject.containsKey(projectId)) {
        // Kiểm tra nếu chưa có trong list (tránh trùng lặp)
        if (!_membersByProject[projectId]!.any((m) => m.id == newMember.id)){
          _membersByProject[projectId]!.add(newMember);
        }
      } else {
        _membersByProject[projectId] = [newMember]; // Tạo list mới nếu chưa có
      }
      _status = MemberStatus.Success;
      notifyListeners();
      return true;
    } catch (e) {
      _status = MemberStatus.Error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeMember(int projectId, int userId) async {
    _status = MemberStatus.Loading; // Có thể dùng loading riêng
    _errorMessage = '';
    notifyListeners();
    try {
      bool success = await _memberService.removeMember(projectId, userId);
      if (success) {
        // Xóa thành viên khỏi danh sách hiện tại
        if (_membersByProject.containsKey(projectId)) {
          _membersByProject[projectId]!.removeWhere((m) => m.id == userId);
        }
        _status = MemberStatus.Success;
        notifyListeners();
        return true;
      } else {
        // Trường hợp này ít xảy ra vì service sẽ ném lỗi 404
        _errorMessage = 'Xóa thất bại (không rõ lý do).';
        _status = MemberStatus.Error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = MemberStatus.Error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Hàm clear khi đóng màn hình
  void clearMembers(int projectId) {
    _membersByProject.remove(projectId);
    _status = MemberStatus.Idle;
    _errorMessage = '';
  }
}