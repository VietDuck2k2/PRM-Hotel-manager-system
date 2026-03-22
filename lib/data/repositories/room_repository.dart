import '../../core/database/database_helper.dart';
import '../../core/constants/db_schema.dart';
import '../../core/constants/app_enums.dart';
import '../models/room_model.dart';

/// Handles room CRUD and status transitions.
/// OWNERSHIP: Module C (Room & Housekeeping Logic)
///
/// IMPORTANT: [getAvailableRoomsForDateRange] is consumed by Member 2's
/// BookingRepository. Do not change its signature without coordinating.
class RoomRepository {
  final DatabaseHelper _dbHelper;
  RoomRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<RoomModel>> getAllRooms() async {
    final db = await _dbHelper.database;
    final result = await db.query(DbSchema.tableRooms, orderBy: 'roomNumber ASC');
    return result.map(RoomModel.fromMap).toList();
  }

  Future<List<RoomModel>> getRoomsByStatus(RoomStatus status) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      DbSchema.tableRooms,
      where: 'status = ?',
      whereArgs: [status.toDbString()],
      orderBy: 'roomNumber ASC',
    );
    return result.map(RoomModel.fromMap).toList();
  }

  Future<RoomModel?> getRoomById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      DbSchema.tableRooms,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return RoomModel.fromMap(result.first);
  }

  /// Returns rooms of the given [roomTypeId] that have no overlapping
  /// BOOKED or CHECKED_IN booking for the given date range.
  Future<List<RoomModel>> getAvailableRoomsForDateRange({
    required int roomTypeId,
    required int checkInMs,
    required int checkOutMs,
  }) async {
    final db = await _dbHelper.database;

    // Availability eligibility:
    // - room must be AVAILABLE now (housekeeping has to mark DIRTY -> AVAILABLE)
    // - and there must be NO overlapping active booking (BOOKED/CHECKED_IN)
    //   with overlap condition: checkInDate < requestedCheckOut AND checkOutDate > requestedCheckIn
    final sql = '''
      SELECT *
      FROM ${DbSchema.tableRooms} r
      WHERE r.roomTypeId = ?
        AND r.status = ?
        AND NOT EXISTS (
          SELECT 1
          FROM ${DbSchema.tableBookings} b
          WHERE b.roomId = r.id
            AND b.status IN (?, ?)
            AND b.checkInDate < ?
            AND b.checkOutDate > ?
        )
      ORDER BY r.roomNumber ASC
    ''';

    final result = await db.rawQuery(sql, [
      roomTypeId,
      RoomStatus.available.toDbString(),
      BookingStatus.booked.toDbString(),
      BookingStatus.checkedIn.toDbString(),
      checkOutMs,
      checkInMs,
    ]);

    return result.map(RoomModel.fromMap).toList();
  }

  Future<int> createRoom(RoomModel room) async {
    final db = await _dbHelper.database;
    return await db.insert(DbSchema.tableRooms, room.toMap());
  }

  Future<int> updateRoom(RoomModel room) async {
    final db = await _dbHelper.database;
    return await db.update(
      DbSchema.tableRooms,
      room.toMap(),
      where: 'id = ?',
      whereArgs: [room.id],
    );
  }

  /// Update only the status of a room. Use this for all status transitions.
  Future<int> updateStatus(int roomId, RoomStatus newStatus) async {
    final db = await _dbHelper.database;
    return await db.update(
      DbSchema.tableRooms,
      {'status': newStatus.toDbString()},
      where: 'id = ?',
      whereArgs: [roomId],
    );
  }

  /// Housekeeping: marks a DIRTY room as AVAILABLE.
  /// Returns 0 if the room was not DIRTY (noop guard).
  Future<int> markRoomAvailable(int roomId) async {
    final db = await _dbHelper.database;
    return await db.update(
      DbSchema.tableRooms,
      {'status': RoomStatus.available.toDbString()},
      where: 'id = ? AND status = ?',
      whereArgs: [roomId, RoomStatus.dirty.toDbString()],
    );
  }
}
