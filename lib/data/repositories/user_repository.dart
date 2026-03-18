import '../../core/database/database_helper.dart';
import '../../core/constants/db_schema.dart';
import '../../core/utils/date_formatter.dart';
import '../models/user_model.dart';
import '../../core/constants/app_enums.dart';

/// Manages staff user CRUD for the admin panel.
/// Owner: Member 4
class UserRepository {
  final DatabaseHelper _dbHelper;
  UserRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<UserModel>> getAllUsers() async {
    final db = await _dbHelper.database;
    final result = await db.query(DbSchema.tableUsers, orderBy: 'fullName ASC');
    return result.map(UserModel.fromMap).toList();
  }

  Future<UserModel?> getUserById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      DbSchema.tableUsers,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return UserModel.fromMap(result.first);
  }

  Future<int> createUser(UserModel user) async {
    final db = await _dbHelper.database;
    return await db.insert(DbSchema.tableUsers, user.toMap());
  }

  Future<int> updateUser(UserModel user) async {
    final db = await _dbHelper.database;
    return await db.update(
      DbSchema.tableUsers,
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  /// Soft-deactivate a user. Users are never hard-deleted.
  Future<int> deactivateUser(int userId) async {
    final db = await _dbHelper.database;
    return await db.update(
      DbSchema.tableUsers,
      {'isActive': 0},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}
