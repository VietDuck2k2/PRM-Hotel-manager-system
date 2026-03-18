// Application-wide string constants.
// Owner: Member 1

class AppConstants {
  AppConstants._();

  static const String appName = 'Hotel Management System';
  static const String databaseName = 'hms.db';

  // ─── Booking Statuses ─────────────────────────────────────────────────────
  static const String statusBooked = 'BOOKED';
  static const String statusCancelled = 'CANCELLED';
  static const String statusCheckedIn = 'CHECKED_IN';
  static const String statusCheckedOut = 'CHECKED_OUT';

  // ─── Room Statuses ────────────────────────────────────────────────────────
  static const String roomAvailable = 'AVAILABLE';
  static const String roomOccupied = 'OCCUPIED';
  static const String roomDirty = 'DIRTY';
  static const String roomOutOfService = 'OUT_OF_SERVICE';

  // ─── Role Values (matches StaffRole enum names) ───────────────────────────
  static const String roleAdmin = 'admin';
  static const String roleReceptionist = 'receptionist';
  static const String roleHousekeeping = 'housekeeping';
}
