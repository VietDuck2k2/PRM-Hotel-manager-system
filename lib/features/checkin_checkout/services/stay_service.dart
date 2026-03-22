import '../../../data/repositories/booking_repository.dart';
import '../../../data/repositories/room_repository.dart';
import '../../../data/repositories/surcharge_repository.dart';
import '../../../data/models/invoice_model.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/constants/db_schema.dart';

class StayService {
  final BookingRepository _bookingRepo;
  final RoomRepository _roomRepo;
  final SurchargeRepository _surchargeRepo;

  StayService({
    BookingRepository? bookingRepo,
    RoomRepository? roomRepo,
    SurchargeRepository? surchargeRepo,
  })  : _bookingRepo = bookingRepo ?? BookingRepository(),
        _roomRepo = roomRepo ?? RoomRepository(),
        _surchargeRepo = surchargeRepo ?? SurchargeRepository();

  /// Perform check-in for [bookingId].
  Future<void> checkIn(int bookingId, int roomId) async {
    final booking = await _bookingRepo.getBookingById(bookingId);
    if (booking == null) {
      throw StateError('Booking not found.');
    }

    // Rule: Check-in requires an assigned room.
    if (booking.roomId == null) {
      throw StateError('Cannot check-in: booking has no assigned room.');
    }
    if (booking.roomId != roomId) {
      throw StateError('Cannot check-in: room does not match assigned room.');
    }
    if (booking.status != BookingStatus.booked) {
      throw StateError('Cannot check-in: booking is not in BOOKED status.');
    }

    final room = await _roomRepo.getRoomById(roomId);
    if (room == null) {
      throw StateError('Assigned room not found.');
    }
    if (room.status != RoomStatus.available) {
      throw StateError('Cannot check-in: room is not AVAILABLE.');
    }

    // Follow Module D guide: use repositories for status transitions.
    await _bookingRepo.updateStatus(bookingId, BookingStatus.checkedIn);
    await _roomRepo.updateStatus(roomId, RoomStatus.occupied);
  }

  /// Perform checkout for [bookingId].
  ///
  /// Returns the created [InvoiceModel] on success.
  Future<InvoiceModel> checkout({
    required int bookingId,
    required int roomId,
    required int checkInMs,
    required int checkOutMs,
    required double bookedPricePerNight,
    required int currentUserId,
  }) async {
    final nights = DateFormatter.calculateNights(checkInMs, checkOutMs);
    final roomCharge = nights * bookedPricePerNight;
    final surchargeTotal = await _surchargeRepo.getTotalSurcharge(bookingId);
    final total = roomCharge + surchargeTotal;
    final issuedAt = DateTime
        .now()
        .millisecondsSinceEpoch;

    final invoice = InvoiceModel(
      bookingId: bookingId,
      roomCharge: roomCharge,
      surchargeTotal: surchargeTotal,
      totalAmount: total,
      issuedBy: currentUserId,
      issuedAt: issuedAt,
    );

    final db = await DatabaseHelper.instance.database;
    int createdId = 0;

    await db.transaction((txn) async {
      // Guard: Invoice is only created during checkout, and exactly once per booking.
      final existingInvoice = await txn.query(
        DbSchema.tableInvoices,
        columns: const ['id'],
        where: 'bookingId = ?',
        whereArgs: [bookingId],
        limit: 1,
      );
      if (existingInvoice.isNotEmpty) {
        throw StateError('Invoice already exists for this booking.');
      }

      // Guard booking must be CHECKED_IN and room must match.
      final bookingRows = await txn.query(
        DbSchema.tableBookings,
        columns: const ['id', 'roomId', 'status'],
        where: 'id = ?',
        whereArgs: [bookingId],
        limit: 1,
      );
      if (bookingRows.isEmpty) {
        throw StateError('Booking not found.');
      }
      final b = bookingRows.first;
      final assignedRoomId = b['roomId'] as int?;
      final status = b['status'] as String;
      if (assignedRoomId == null) {
        throw StateError('Cannot checkout: booking has no assigned room.');
      }
      if (assignedRoomId != roomId) {
        throw StateError('Cannot checkout: room does not match assigned room.');
      }
      if (status != BookingStatus.checkedIn.toDbString()) {
        throw StateError('Cannot checkout: booking is not CHECKED_IN.');
      }

      createdId = await txn.insert(DbSchema.tableInvoices, invoice.toMap());

      await txn.update(
        DbSchema.tableBookings,
        {'status': BookingStatus.checkedOut.toDbString()},
        where: 'id = ? AND status = ?',
        whereArgs: [bookingId, BookingStatus.checkedIn.toDbString()],
      );

      // After checkout, room becomes DIRTY for housekeeping.
      await txn.update(
        DbSchema.tableRooms,
        {'status': RoomStatus.dirty.toDbString()},
        where: 'id = ? AND status = ?',
        whereArgs: [roomId, RoomStatus.occupied.toDbString()],
      );
    });

    // Keep repository referenced (ownership doc) without giving it invoice creation authority in UI.
    // (Actual insert is done in the transaction above for atomicity.)
    if (createdId <= 0) {
      // Fallback shouldn't happen, but keep signal if SQLite returns 0.
      throw StateError('Failed to create invoice.');
    }
    return InvoiceModel(
      id: createdId,
      bookingId: invoice.bookingId,
      roomCharge: invoice.roomCharge,
      surchargeTotal: invoice.surchargeTotal,
      totalAmount: invoice.totalAmount,
      issuedBy: invoice.issuedBy,
      issuedAt: invoice.issuedAt,
    );
  }
}
