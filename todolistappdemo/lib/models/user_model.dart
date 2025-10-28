import 'dart:convert';
import 'package:flutter/material.dart';

class AppUser {
  final int id;
  final String fullName;
  final String userName;
  final String email;
  final String? phoneNumber;
  final List<String> roles; // <-- ĐÃ THÊM: Khắc phục lỗi biên dịch

  AppUser({
    required this.id,
    required this.fullName,
    required this.userName,
    required this.email,
    this.phoneNumber,
    this.roles = const [], // Khởi tạo mặc định
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      fullName: json['fullName'] as String,
      userName: json['userName'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      // FIX LỖI: Map Roles từ List<dynamic>
      roles: (json['roles'] as List<dynamic>?)?.map((r) => r.toString()).toList() ?? const [],
    );
  }
}