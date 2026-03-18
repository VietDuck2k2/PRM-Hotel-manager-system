import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/database/database_helper.dart';
import 'core/constants/app_routes.dart';
import 'core/constants/app_constants.dart';
import 'shared/themes/app_theme.dart';
import 'features/auth/session_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/dashboard_screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite database
  await DatabaseHelper.instance.database;

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => SessionProvider())],
      child: const HMSApp(),
    ),
  );
}

class HMSApp extends StatelessWidget {
  const HMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.adminDashboard: (context) => const AdminDashboard(),
        AppRoutes.receptionistDashboard: (context) =>
            const ReceptionistDashboard(),
        AppRoutes.housekeepingDashboard: (context) =>
            const HousekeepingDashboard(),

        // Stubs for future screens
        AppRoutes.bookings: (context) => const _StubScreen(title: 'Bookings'),
        AppRoutes.checkIn: (context) =>
            const _StubScreen(title: 'Check-In/Out'),
        AppRoutes.rooms: (context) => const _StubScreen(title: 'Rooms'),
        AppRoutes.housekeepingTasks: (context) =>
            const _StubScreen(title: 'Cleaning Tasks'),
        AppRoutes.staff: (context) =>
            const _StubScreen(title: 'Staff Management'),
        AppRoutes.reports: (context) => const _StubScreen(title: 'Reports'),
        AppRoutes.settings: (context) => const _StubScreen(title: 'Settings'),
        AppRoutes.guests: (context) => const _StubScreen(title: 'Guests'),
      },
    );
  }
}

class _StubScreen extends StatelessWidget {
  final String title;
  const _StubScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Stub Screen for $title')),
    );
  }
}
