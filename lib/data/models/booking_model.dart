import '../../core/constants/app_enums.dart';
import '../../core/constants/db_schema.dart';

/// Booking entity model. Maps to [DbSchema.tableBookings].
/// Owner: Member 2
///
/// IMPORTANT RULES (from Phase A):
/// - [roomId] is nullable. Booking creation without a room is valid.
/// - [bookedPricePerNight] is a price snapshot — must not be updated after creation.
/// - [cancelReason] is required when status is CANCELLED.
/// - [createdBy] is the userId of the staff who created this booking.
class BookingModel {
  final int? id;
  final String guestName;
  final String guestPhone;
  final int roomTypeId;
  final int? roomId; // nullable — room may not be assigned yet
  final int checkInDate; // Unix ms
  final int checkOutDate; // Unix ms
  final double bookedPricePerNight; // price snapshot at booking creation
  final BookingStatus status;
  final String? cancelReason; // required when status == cancelled
  final int createdBy; // User.id who created this booking
  final int createdAt; // Unix ms

  const BookingModel({
    this.id,
    required this.guestName,
    required this.guestPhone,
    required this.roomTypeId,
    this.roomId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.bookedPricePerNight,
    required this.status,
    this.cancelReason,
    required this.createdBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'guestName': guestName,
      'guestPhone': guestPhone,
      'roomTypeId': roomTypeId,
      'roomId': roomId, // nullable — will be NULL in SQLite when null
      'checkInDate': checkInDate,
      'checkOutDate': checkOutDate,
      'bookedPricePerNight': bookedPricePerNight,
      'status': status.toDbString(),
      'cancelReason': cancelReason,
      'createdBy': createdBy,
      'createdAt': createdAt,
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'] as int?,
      guestName: map['guestName'] as String,
      guestPhone: map['guestPhone'] as String,
      roomTypeId: map['roomTypeId'] as int,
      roomId: map['roomId'] as int?, // explicit int? cast — can be null
      checkInDate: map['checkInDate'] as int,
      checkOutDate: map['checkOutDate'] as int,
      bookedPricePerNight: (map['bookedPricePerNight'] as num).toDouble(),
      status: BookingStatus.fromString(map['status'] as String),
      cancelReason: map['cancelReason'] as String?,
      createdBy: map['createdBy'] as int,
      createdAt: map['createdAt'] as int,
    );
  }

  BookingModel copyWith({
    int? id,
    String? guestName,
    String? guestPhone,
    int? roomTypeId,
    Object? roomId = _sentinel, // use sentinel to distinguish null-set from not-set
    int? checkInDate,
    int? checkOutDate,
    double? bookedPricePerNight,
    BookingStatus? status,
    String? cancelReason,
    int? createdBy,
    int? createdAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      guestName: guestName ?? this.guestName,
      guestPhone: guestPhone ?? this.guestPhone,
      roomTypeId: roomTypeId ?? this.roomTypeId,
      roomId: roomId == _sentinel ? this.roomId : roomId as int?,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      bookedPricePerNight: bookedPricePerNight ?? this.bookedPricePerNight,
      status: status ?? this.status,
      cancelReason: cancelReason ?? this.cancelReason,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'BookingModel(id: $id, guest: $guestName, status: $status, roomId: $roomId)';
}

// Sentinel object for copyWith nullable field handling
const Object _sentinel = Object();
