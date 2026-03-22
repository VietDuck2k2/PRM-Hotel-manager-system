import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../constants/db_schema.dart';
import '../../data/models/user_model.dart';
import '../constants/app_enums.dart';
import '../utils/date_formatter.dart';

/// Singleton wrapper around the sqflite database.
/// OWNERSHIP: Module A (Core & DB Foundation)
/// Other modules must not modify this file.
///
/// All table creation happens via [DbSchema.allCreateStatements].
/// Seed data is inserted via [_seedData].
class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'hms.db');

    return await openDatabase(
      path,
      version: DbSchema.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create all tables
    for (final sql in DbSchema.allCreateStatements) {
      await db.execute(sql);
    }
    // Insert seed data for demo
    await _seedData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2 && newVersion >= 2) {
      await _migrateToV2(db);
    }
  }

  Future<void> _migrateToV2(Database db) async {
    await db.execute(
      'ALTER TABLE ${DbSchema.tableRooms} ADD COLUMN checkoutSinceLastFloorClean INTEGER NOT NULL DEFAULT 0',
    );
    await db.execute(DbSchema.createHousekeepingTasks);
  }

  /// Inserts demo data so the app works on first launch without manual setup.
  Future<void> _seedData(Database db) async {
    final now = DateFormatter.toMs(DateTime.now());

    // Seed room types
    final deluxeId = await db.insert(DbSchema.tableRoomTypes, {
      'name': 'Deluxe',
      'pricePerNight': 150.0,
      'description': 'Comfortable room with city view',
    });
    final suiteId = await db.insert(DbSchema.tableRoomTypes, {
      'name': 'Suite',
      'pricePerNight': 300.0,
      'description': 'Luxury suite with living area',
    });

    // Seed rooms (5 rooms)
    for (int i = 1; i <= 3; i++) {
      await db.insert(DbSchema.tableRooms, {
        'roomNumber': '10$i',
        'roomTypeId': deluxeId,
        'status': RoomStatus.available.toDbString(),
      });
    }
    for (int i = 1; i <= 2; i++) {
      await db.insert(DbSchema.tableRooms, {
        'roomNumber': '20$i',
        'roomTypeId': suiteId,
        'status': RoomStatus.available.toDbString(),
      });
    }

    // Seed users — one per role
    await db.insert(
        DbSchema.tableUsers,
        UserModel(
          id: null,
          username: 'admin',
          passwordHash: UserModel.hashPassword('admin123'),
          fullName: 'Admin User',
          role: StaffRole.admin,
          isActive: true,
          createdAt: now,
        ).toMap());

    await db.insert(
        DbSchema.tableUsers,
        UserModel(
          id: null,
          username: 'receptionist',
          passwordHash: UserModel.hashPassword('recep123'),
          fullName: 'Receptionist User',
          role: StaffRole.receptionist,
          isActive: true,
          createdAt: now,
        ).toMap());

    await db.insert(
        DbSchema.tableUsers,
        UserModel(
          id: null,
          username: 'housekeeping',
          passwordHash: UserModel.hashPassword('house123'),
          fullName: 'Housekeeping User',
          role: StaffRole.housekeeping,
          isActive: true,
          createdAt: now,
        ).toMap());
  }
}
