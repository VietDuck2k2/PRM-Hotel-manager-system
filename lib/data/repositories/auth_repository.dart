import '../../core/database/database_helper.dart';
import '../../core/constants/db_schema.dart';
import '../models/user_model.dart';


/// Handles authentication queries against the local SQLite database.
/// Owner: Member 1
class AuthRepository {
  final DatabaseHelper _dbHelper;
  AuthRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Verify credentials and return the matching [UserModel], or null if invalid.
  Future<UserModel?> login(String username, String password) async {
    final db = await _dbHelper.database;
    final hash = UserModel.hashPassword(password);
    final result = await db.query(
      DbSchema.tableUsers,
      where: 'username = ? AND passwordHash = ? AND isActive = 1',
      whereArgs: [username, hash],
    );
    if (result.isEmpty) return null;
    return UserModel.fromMap(result.first);
  }
}
