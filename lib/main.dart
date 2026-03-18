import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Core
import 'core/constants/app_routes.dart';
import 'shared/themes/app_theme.dart';

// Session
import 'features/auth/session_provider.dart';

// Auth
import 'features/auth/screens/login_screen.dart';

// Dashboards
import 'features/dashboard/screens/dashboard_screens.dart';

// Bookings (Member 2)
import 'features/bookings/screens/booking_screens.dart';

// Rooms & Housekeeping (Member 3)
import 'features/rooms/screens/room_screens.dart';
import 'features/housekeeping/screens/housekeeping_task_list_screen.dart';

// Stay Operations & Staff (Member 4)
import 'features/checkin_checkout/screens/checkin_checkout_screens.dart';
import 'features/staff/screens/staff_screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HmsApp());
}

class HmsApp extends StatelessWidget {
  const HmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionProvider()),
      ],
      child: MaterialApp(
        title: 'Hotel Management System',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.login,
        routes: {
          // Auth (Member 1)
          AppRoutes.login: (_) => const LoginScreen(),

          // Dashboards (Member 1)
          AppRoutes.adminDashboard: (_) => const AdminDashboard(),
          AppRoutes.receptionistDashboard: (_) => const ReceptionistDashboard(),
          AppRoutes.housekeepingDashboard: (_) => const HousekeepingDashboard(),

          // Bookings (Member 2)
          AppRoutes.bookingList: (_) => const BookingListScreen(),
          AppRoutes.bookingDetail: (_) => const BookingDetailScreen(),
          AppRoutes.createBooking: (_) => const CreateBookingScreen(),
          AppRoutes.assignRoom: (_) => const AssignRoomScreen(),
          AppRoutes.cancelBooking: (_) => const CancelBookingScreen(),

          // Rooms (Member 3)
          AppRoutes.roomTypeList: (_) => const RoomTypeListScreen(),
          AppRoutes.roomTypeForm: (_) => const RoomTypeFormScreen(),
          AppRoutes.roomList: (_) => const RoomListScreen(),
          AppRoutes.roomForm: (_) => const RoomFormScreen(),

          // Housekeeping (Member 3)
          AppRoutes.housekeepingTaskList: (_) => const HousekeepingTaskListScreen(),

          // Stay Operations (Member 4)
          AppRoutes.checkIn: (_) => const CheckInScreen(),
          AppRoutes.surchargeForm: (_) => const SurchargeFormScreen(),
          AppRoutes.checkout: (_) => const CheckoutScreen(),
          AppRoutes.invoiceDetail: (_) => const InvoiceDetailScreen(),

          // Staff Management (Member 4)
          AppRoutes.staffList: (_) => const StaffListScreen(),
          AppRoutes.staffForm: (_) => const StaffFormScreen(),
        },
      ),
    );
  }
}
