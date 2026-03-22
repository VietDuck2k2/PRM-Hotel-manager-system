import 'package:flutter/foundation.dart';

import '../../../data/repositories/booking_repository.dart';
import '../../../data/repositories/room_repository.dart';
import '../../../data/repositories/surcharge_repository.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/booking_model.dart';
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

  Future<CheckInEvaluation> evaluateBookingForCheckIn(int bookingId) async {
    final booking = await _bookingRepo.getBookingById(bookingId);
    if (booking == null) {
      return const CheckInEvaluation(false, 'Booking not found.');
    }

    if (booking.status != BookingStatus.booked) {
      return const CheckInEvaluation(false, 'Booking is not in BOOKED status.');
    }

    final roomId = booking.roomId;
    if (roomId == null) {
      return const CheckInEvaluation(false, 'Assign a room before check-in.');
    }

    final room = await _roomRepo.getRoomById(roomId);
    if (room == null) {
      return const CheckInEvaluation(false, 'Assigned room was not found.');
    }

    if (room.status != RoomStatus.available) {
      return const CheckInEvaluation(false, 'Assigned room is not AVAILABLE.');
    }

    return const CheckInEvaluation(true, null);
  }

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

  Future<CheckoutQuote> buildCheckoutQuote(BookingModel booking) async {
    final bookingId = booking.id;
    if (bookingId == null) {
      throw StateError('Booking must have an id to build a quote.');
    }
    final nights = DateFormatter.calculateNights(
        booking.checkInDate, booking.checkOutDate);
    final roomCharge = nights * booking.bookedPricePerNight;
    final surchargeTotal = await _surchargeRepo.getTotalSurcharge(bookingId);
    return CheckoutQuote(
      nights: nights,
      roomCharge: roomCharge,
      surchargeTotal: surchargeTotal,
    );
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
    CheckoutQuote? quote,
  }) async {
    final summary = quote ??
        await CheckoutQuote.fromRaw(
          bookingId: bookingId,
          checkInMs: checkInMs,
          checkOutMs: checkOutMs,
          bookedPricePerNight: bookedPricePerNight,
          surchargeRepository: _surchargeRepo,
        );
    final issuedAt = DateTime.now().millisecondsSinceEpoch;

    final invoice = InvoiceModel(
      bookingId: bookingId,
      roomCharge: summary.roomCharge,
      surchargeTotal: summary.surchargeTotal,
      totalAmount: summary.total,
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

@immutable
class CheckInEvaluation {
  final bool canProceed;
  final String? message;

  const CheckInEvaluation(this.canProceed, this.message);
}

class CheckoutQuote {
  final int nights;
  final double roomCharge;
  final double surchargeTotal;

  double get total => roomCharge + surchargeTotal;

  const CheckoutQuote({
    required this.nights,
    required this.roomCharge,
    required this.surchargeTotal,
  });

  static Future<CheckoutQuote> fromRaw({
    required int bookingId,
    required int checkInMs,
    required int checkOutMs,
    required double bookedPricePerNight,
    required SurchargeRepository surchargeRepository,
  }) async {
    final nights = DateFormatter.calculateNights(checkInMs, checkOutMs);
    final roomCharge = nights * bookedPricePerNight;
    final surchargeTotal =
        await surchargeRepository.getTotalSurcharge(bookingId);
    return CheckoutQuote(
      nights: nights,
      roomCharge: roomCharge,
      surchargeTotal: surchargeTotal,
    );
  }
}
