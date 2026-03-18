import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants/db_schema.dart';
import '../../data/models/user_model.dart';
import '../constants/app_enums.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hms_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    // Create all tables defined in DbSchema
    await db.execute(DbSchema.createUsersTable);
    await db.execute(DbSchema.createRoomsTable);
    await db.execute(DbSchema.createRoomTypesTable);
    await db.execute(DbSchema.createBookingsTable);
    await db.execute(DbSchema.createInvoicesTable);
    await db.execute(DbSchema.createSurchargesTable);
    await db.execute(DbSchema.createCleaningTasksTable);

    // Seed Demo Users
    final adminPassword = UserModel.hashPassword('admin123');
    final recepPassword = UserModel.hashPassword('recep123');
    final housePassword = UserModel.hashPassword('house123');

    await db.insert(DbSchema.usersTable, {
      'username': 'admin',
      'password': adminPassword,
      'role': StaffRole.admin.name,
      'isActive': 1,
    });

    await db.insert(DbSchema.usersTable, {
      'username': 'receptionist',
      'password': recepPassword,
      'role': StaffRole.receptionist.name,
      'isActive': 1,
    });

    await db.insert(DbSchema.usersTable, {
      'username': 'housekeeping',
      'password': housePassword,
      'role': StaffRole.housekeeping.name,
      'isActive': 1,
    });
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
