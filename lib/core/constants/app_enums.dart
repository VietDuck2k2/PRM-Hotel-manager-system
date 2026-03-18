// Centralized enums for the HMS project.
// Owner: Member 1
// Rule: values match the strings stored in SQLite exactly (see AppConstants).

/// Staff role enum. Store as role.name in SQLite (e.g., 'admin').
enum StaffRole {
  admin,
  receptionist,
  housekeeping;

  /// Parse from SQLite-stored string. Throws if invalid.
  static StaffRole fromString(String value) => StaffRole.values.byName(value);
}

/// Booking lifecycle statuses.
enum BookingStatus {
  booked,
  cancelled,
  checkedIn,
  checkedOut;

  /// Convert to the string stored in SQLite.
  String toDbString() {
    switch (this) {
      case BookingStatus.booked:
        return 'BOOKED';
      case BookingStatus.cancelled:
        return 'CANCELLED';
      case BookingStatus.checkedIn:
        return 'CHECKED_IN';
      case BookingStatus.checkedOut:
        return 'CHECKED_OUT';
    }
  }

  /// Parse from SQLite-stored string.
  static BookingStatus fromString(String value) {
    switch (value) {
      case 'BOOKED':
        return BookingStatus.booked;
      case 'CANCELLED':
        return BookingStatus.cancelled;
      case 'CHECKED_IN':
        return BookingStatus.checkedIn;
      case 'CHECKED_OUT':
        return BookingStatus.checkedOut;
      default:
        throw ArgumentError('Unknown BookingStatus: $value');
    }
  }
}

/// Room operational statuses.
enum RoomStatus {
  available,
  occupied,
  dirty,
  outOfService;

  /// Convert to the string stored in SQLite.
  String toDbString() {
    switch (this) {
      case RoomStatus.available:
        return 'AVAILABLE';
      case RoomStatus.occupied:
        return 'OCCUPIED';
      case RoomStatus.dirty:
        return 'DIRTY';
      case RoomStatus.outOfService:
        return 'OUT_OF_SERVICE';
    }
  }

  /// Parse from SQLite-stored string.
  static RoomStatus fromString(String value) {
    switch (value) {
      case 'AVAILABLE':
        return RoomStatus.available;
      case 'OCCUPIED':
        return RoomStatus.occupied;
      case 'DIRTY':
        return RoomStatus.dirty;
      case 'OUT_OF_SERVICE':
        return RoomStatus.outOfService;
      default:
        throw ArgumentError('Unknown RoomStatus: $value');
    }
  }
}
