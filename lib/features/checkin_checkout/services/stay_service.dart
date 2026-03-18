import '../../../data/repositories/booking_repository.dart';
import '../../../data/repositories/room_repository.dart';
import '../../../data/repositories/surcharge_repository.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/models/invoice_model.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/database/database_helper.dart';

/// Orchestrates the checkout transaction as a single atomic DB operation.
/// OWNERSHIP: Module D (Stay Operations Logic)
///
/// This is the ONLY place that creates an Invoice.
/// Caller must pass [currentUserId] — do not read session inside here.
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
    // TODO: [Module D] implement full check-in logic
    // Placeholder to keep it compile-safe
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
    // TODO: [Module D] implement invoice calculation and creation
    // TODO: [Module D] implement full checkout transaction

    // Placeholder return to keep it compile-safe
    return InvoiceModel(
      id: 0,
      bookingId: bookingId,
      roomCharge: 0,
      surchargeTotal: 0,
      totalAmount: 0,
      issuedBy: currentUserId,
      issuedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
