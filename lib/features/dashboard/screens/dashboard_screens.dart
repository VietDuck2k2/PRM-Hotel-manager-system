import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/session_provider.dart';
import '../../../core/constants/app_routes.dart';

/// Dashboard for admin role.
/// Links to: staff mgmt, room types, rooms, bookings, check-in/out.
/// Owner: Member 1 (shell layout only — individual tiles link to other modules)
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              session.logout();
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          )
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: const [
          _DashboardTile(icon: Icons.people, label: 'Staff', route: AppRoutes.staffList),
          _DashboardTile(icon: Icons.category, label: 'Room Types', route: AppRoutes.roomTypeList),
          _DashboardTile(icon: Icons.meeting_room, label: 'Rooms', route: AppRoutes.roomList),
          _DashboardTile(icon: Icons.book_online, label: 'Bookings', route: AppRoutes.bookingList),
          _DashboardTile(icon: Icons.login, label: 'Check-In', route: AppRoutes.checkIn),
          _DashboardTile(icon: Icons.receipt_long, label: 'Invoices', route: AppRoutes.invoiceDetail),
        ],
      ),
    );
  }
}

/// Dashboard for receptionist role.
/// Owner: Member 1 (shell layout only)
class ReceptionistDashboard extends StatelessWidget {
  const ReceptionistDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receptionist Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              session.logout();
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          )
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: const [
          _DashboardTile(icon: Icons.book_online, label: 'Bookings', route: AppRoutes.bookingList),
          _DashboardTile(icon: Icons.meeting_room, label: 'Rooms', route: AppRoutes.roomList),
          _DashboardTile(icon: Icons.login, label: 'Check-In', route: AppRoutes.checkIn),
          _DashboardTile(icon: Icons.receipt_long, label: 'Invoices', route: AppRoutes.invoiceDetail),
        ],
      ),
    );
  }
}

/// Dashboard for housekeeping role.
/// Owner: Member 1 (shell layout only)
class HousekeepingDashboard extends StatelessWidget {
  const HousekeepingDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Housekeeping'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              session.logout();
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          )
        ],
      ),
      body: const Center(
        child: _DashboardTile(
          icon: Icons.cleaning_services,
          label: 'Cleaning Tasks',
          route: AppRoutes.housekeepingTaskList,
        ),
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;

  const _DashboardTile({
    required this.icon,
    required this.label,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: const Color(0xFF1A6B8A)),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
