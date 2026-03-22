import '../../core/database/database_helper.dart';
import '../../core/constants/db_schema.dart';
import '../models/user_model.dart';

/// Manages staff user CRUD for the admin panel.
/// Owner: Member 4
class UserRepository {
  final DatabaseHelper _dbHelper;
  UserRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<UserModel>> getAllUsers() => getUsers(includeInactive: true);

  Future<List<UserModel>> getUsers({bool includeInactive = true}) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      DbSchema.tableUsers,
      where: includeInactive ? null : 'isActive = 1',
      orderBy: 'fullName ASC',
    );
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
    return setActiveStatus(userId, false);
  }

  Future<int> reactivateUser(int userId) async {
    return setActiveStatus(userId, true);
  }

  Future<int> setActiveStatus(int userId, bool isActive) async {
    final db = await _dbHelper.database;
    return db.update(
      DbSchema.tableUsers,
      {'isActive': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<bool> usernameExists(String username, {int? excludeUserId}) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      DbSchema.tableUsers,
      columns: const ['id'],
      where: excludeUserId == null
          ? 'LOWER(username) = LOWER(?)'
          : 'LOWER(username) = LOWER(?) AND id != ?',
      whereArgs: excludeUserId == null ? [username] : [username, excludeUserId],
      limit: 1,
    );
    return result.isNotEmpty;
  }
}
