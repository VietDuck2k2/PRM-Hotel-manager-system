import '../../core/database/database_helper.dart';
import '../../core/constants/db_schema.dart';
import '../../core/constants/app_enums.dart';
import '../models/booking_model.dart';

/// Handles booking CRUD and status transitions.
/// OWNERSHIP: Module B (Booking Logic)
class BookingRepository {
  final DatabaseHelper _dbHelper;
  BookingRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<BookingModel>> getAllBookings() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      DbSchema.tableBookings,
      orderBy: 'createdAt DESC',
    );
    return result.map(BookingModel.fromMap).toList();
  }

  Future<BookingModel?> getBookingById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      DbSchema.tableBookings,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return BookingModel.fromMap(result.first);
  }

  Future<List<BookingModel>> getBookingsByStatus(BookingStatus status) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      DbSchema.tableBookings,
      where: 'status = ?',
      whereArgs: [status.toDbString()],
      orderBy: 'createdAt DESC',
    );
    return result.map(BookingModel.fromMap).toList();
  }

  Future<int> createBooking(BookingModel booking) async {
    final db = await _dbHelper.database;
    return await db.insert(DbSchema.tableBookings, booking.toMap());
  }

  /// Assign a room to a booking. Sets Booking.roomId.
  Future<int> assignRoom(int bookingId, int roomId) async {
    final db = await _dbHelper.database;
    return await db.update(
      DbSchema.tableBookings,
      {'roomId': roomId},
      where: 'id = ? AND status = ?',
      whereArgs: [bookingId, BookingStatus.booked.toDbString()],
    );
  }

  /// Cancel booking: sets status to CANCELLED, records reason, clears roomId.
  Future<int> cancelBooking(int bookingId, String cancelReason) async {
    final db = await _dbHelper.database;
    return await db.update(
      DbSchema.tableBookings,
      {
        'status': BookingStatus.cancelled.toDbString(),
        'cancelReason': cancelReason,
        'roomId': null, // release the room assignment
      },
      where: 'id = ? AND status = ?',
      whereArgs: [bookingId, BookingStatus.booked.toDbString()],
    );
  }

  /// Update booking status only. Used by StayService for check-in/out.
  Future<int> updateStatus(int bookingId, BookingStatus newStatus) async {
    final db = await _dbHelper.database;
    return await db.update(
      DbSchema.tableBookings,
      {'status': newStatus.toDbString()},
      where: 'id = ?',
      whereArgs: [bookingId],
    );
  }
}
