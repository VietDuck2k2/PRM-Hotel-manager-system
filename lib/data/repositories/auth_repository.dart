import '../../core/database/database_helper.dart';
import '../../core/constants/db_schema.dart';
import '../models/user_model.dart';

class AuthRepository {
  Future<UserModel?> login(String username, String password) async {
    final db = await DatabaseHelper.instance.database;
    final hashedPassword = UserModel.hashPassword(password);

    final List<Map<String, dynamic>> maps = await db.query(
      DbSchema.usersTable,
      where: 'username = ? AND password = ? AND isActive = 1',
      whereArgs: [username, hashedPassword],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }
}
