import 'dart:convert';
import 'package:crypto/crypto.dart' show md5;  
import '../../core/constants/app_enums.dart';
import '../../core/constants/db_schema.dart';

/// User entity model. Maps 1:1 to the [DbSchema.tableUsers] table.
/// Owner: Member 1
///
/// Password is stored as an MD5 hash. This is sufficient for a local
/// student demo — not production cryptography.
class UserModel {
  final int? id;
  final String username;
  final String passwordHash;
  final String fullName;
  final StaffRole role;
  final bool isActive;
  final int createdAt; // Unix ms

  const UserModel({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  /// Hash a plaintext password for storage. Used during seeding and user creation.
  static String hashPassword(String plainText) {
    final bytes = utf8.encode(plainText);
    return md5.convert(bytes).toString();
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'username': username,
      'passwordHash': passwordHash,
      'fullName': fullName,
      'role': role.name, // stores 'admin' | 'receptionist' | 'housekeeping'
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      username: map['username'] as String,
      passwordHash: map['passwordHash'] as String,
      fullName: map['fullName'] as String,
      role: StaffRole.fromString(map['role'] as String),
      isActive: (map['isActive'] as int) == 1,
      createdAt: map['createdAt'] as int,
    );
  }

  UserModel copyWith({
    int? id,
    String? username,
    String? passwordHash,
    String? fullName,
    StaffRole? role,
    bool? isActive,
    int? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'UserModel(id: $id, username: $username, role: $role, isActive: $isActive)';
}
