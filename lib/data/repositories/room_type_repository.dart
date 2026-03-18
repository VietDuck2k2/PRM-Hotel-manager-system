import '../../core/database/database_helper.dart';
import '../../core/constants/db_schema.dart';
import '../models/room_type_model.dart';

/// Handles room type CRUD.
/// Owner: Member 3
class RoomTypeRepository {
  final DatabaseHelper _dbHelper;
  RoomTypeRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<RoomTypeModel>> getAllRoomTypes() async {
    final db = await _dbHelper.database;
    final result = await db.query(DbSchema.tableRoomTypes, orderBy: 'name ASC');
    return result.map(RoomTypeModel.fromMap).toList();
  }

  Future<RoomTypeModel?> getRoomTypeById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      DbSchema.tableRoomTypes,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return RoomTypeModel.fromMap(result.first);
  }

  Future<int> createRoomType(RoomTypeModel roomType) async {
    final db = await _dbHelper.database;
    return await db.insert(DbSchema.tableRoomTypes, roomType.toMap());
  }

  Future<int> updateRoomType(RoomTypeModel roomType) async {
    final db = await _dbHelper.database;
    return await db.update(
      DbSchema.tableRoomTypes,
      roomType.toMap(),
      where: 'id = ?',
      whereArgs: [roomType.id],
    );
  }

  /// Deletes a room type. Caller must verify no rooms link to it first.
  Future<int> deleteRoomType(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DbSchema.tableRoomTypes,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Returns true if any room references this room type (block deletion guard).
  Future<bool> hasLinkedRooms(int roomTypeId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      DbSchema.tableRooms,
      where: 'roomTypeId = ?',
      whereArgs: [roomTypeId],
      limit: 1,
    );
    return result.isNotEmpty;
  }
}
