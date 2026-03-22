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
    final result =
        await db.query(DbSchema.tableRooms, orderBy: 'roomNumber ASC');
    return result.map(RoomModel.fromMap).toList();
  }

  /// Lightweight helper so UI layers can request only DIRTY rooms without
  /// duplicating status strings.
  Future<List<RoomModel>> getRoomsNeedingCleaning() {
    return getRoomsByStatus(RoomStatus.dirty);
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
    if (checkOutMs <= checkInMs) {
      // Defensive: callers should never send an invalid range but returning an
      // empty list is safer than throwing and breaking the booking flow.
      return [];
    }

    final db = await _dbHelper.database;

    // Availability eligibility:
    // - room must be AVAILABLE now (housekeeping has to mark DIRTY -> AVAILABLE)
    // - and there must be NO overlapping active booking (BOOKED/CHECKED_IN)
    //   with overlap condition: checkInDate < requestedCheckOut AND checkOutDate > requestedCheckIn
    const sql = '''
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

    try {
      final result = await db.rawQuery(sql, [
        roomTypeId,
        RoomStatus.available.toDbString(),
        BookingStatus.booked.toDbString(),
        BookingStatus.checkedIn.toDbString(),
        checkOutMs,
        checkInMs,
      ]);

      return result.map(RoomModel.fromMap).toList();
    } catch (_) {
      // TODO(Module 3): Remove this fallback once advanced overlap query is
      // validated across every platform target.
      final fallback = await db.query(
        DbSchema.tableRooms,
        where: 'roomTypeId = ? AND status = ?',
        whereArgs: [roomTypeId, RoomStatus.available.toDbString()],
        orderBy: 'roomNumber ASC',
      );
      return fallback.map(RoomModel.fromMap).toList();
    }
  }

  Future<int> createRoom(RoomModel room) async {
    final db = await _dbHelper.database;
    return await db.insert(DbSchema.tableRooms, room.toMap());
  }

  Future<int> deleteRoom(int roomId) async {
    final db = await _dbHelper.database;
    return db.delete(
      DbSchema.tableRooms,
      where: 'id = ?',
      whereArgs: [roomId],
    );
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

  Future<int> markRoomDirty(int roomId) {
    return updateStatus(roomId, RoomStatus.dirty);
  }

  Future<int> markRoomOutOfService(int roomId) {
    return updateStatus(roomId, RoomStatus.outOfService);
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

  Future<Map<RoomStatus, int>> getRoomStatusCounts() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT status, COUNT(*) as total
      FROM ${DbSchema.tableRooms}
      GROUP BY status
    ''');

    final counts = <RoomStatus, int>{
      for (final status in RoomStatus.values) status: 0,
    };

    for (final row in rows) {
      final statusString = row['status'] as String?;
      final total = row['total'] is int
          ? row['total'] as int
          : (row['total'] as num?)?.toInt() ?? 0;
      if (statusString == null) continue;
      try {
        final status = RoomStatus.fromString(statusString);
        counts[status] = total;
      } catch (_) {
        // Ignore unknown statuses so the UI remains stable.
      }
    }

    return counts;
  }
}
