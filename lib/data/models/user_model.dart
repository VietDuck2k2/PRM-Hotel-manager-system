import 'dart:convert';
import 'package:crypto/crypto.dart';

class UserModel {
  final int? id;
  final String username;
  final String password;
  final String role;
  final int isActive;

  UserModel({
    this.id,
    required this.username,
    required this.password,
    required this.role,
    this.isActive = 1,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      username: map['username'] as String,
      password: map['password'] as String,
      role: map['role'] as String,
      isActive: map['isActive'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'role': role,
      'isActive': isActive,
    };
  }

  static String hashPassword(String input) {
    final bytes = utf8.encode(input);
    final digest = md5.convert(bytes);
    return digest.toString();
  }
}
