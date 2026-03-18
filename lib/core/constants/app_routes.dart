/// Named route constants for the application.
/// Owner: Member 1
///
/// All navigation uses these constants — no hardcoded strings.
class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String adminDashboard = '/dashboard/admin';
  static const String receptionistDashboard = '/dashboard/receptionist';
  static const String housekeepingDashboard = '/dashboard/housekeeping';

  // Booking routes (Member 2)
  static const String bookingList = '/bookings';
  static const String bookingDetail = '/bookings/detail';
  static const String createBooking = '/bookings/create';
  static const String assignRoom = '/bookings/assign-room';
  static const String cancelBooking = '/bookings/cancel';

  // Room & housekeeping routes (Member 3)
  static const String roomList = '/rooms';
  static const String roomForm = '/rooms/form';
  static const String roomTypeList = '/room-types';
  static const String roomTypeForm = '/room-types/form';
  static const String housekeepingTaskList = '/housekeeping/tasks';

  // Stay operations routes (Member 4)
  static const String checkIn = '/checkin';
  static const String surchargeForm = '/surcharges/form';
  static const String checkout = '/checkout';
  static const String invoiceDetail = '/invoices/detail';

  // Staff management routes (Member 4)
  static const String staffList = '/staff';
  static const String staffForm = '/staff/form';
}
