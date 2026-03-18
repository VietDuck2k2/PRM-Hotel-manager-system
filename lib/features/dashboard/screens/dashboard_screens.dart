import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/session_provider.dart';
import '../../../core/constants/app_routes.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return _DashboardLayout(
      title: 'Admin Dashboard',
      tiles: const [
        _DashboardTile(
          title: 'Bookings',
          icon: Icons.book,
          route: AppRoutes.bookings,
        ),
        _DashboardTile(
          title: 'Rooms',
          icon: Icons.king_bed,
          route: AppRoutes.rooms,
        ),
        _DashboardTile(
          title: 'Check-In/Out',
          icon: Icons.login,
          route: AppRoutes.checkIn,
        ),
        _DashboardTile(
          title: 'Staff',
          icon: Icons.people,
          route: AppRoutes.staff,
        ),
        _DashboardTile(
          title: 'Reports',
          icon: Icons.bar_chart,
          route: AppRoutes.reports,
        ),
        _DashboardTile(
          title: 'Settings',
          icon: Icons.settings,
          route: AppRoutes.settings,
        ),
      ],
    );
  }
}

class ReceptionistDashboard extends StatelessWidget {
  const ReceptionistDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return _DashboardLayout(
      title: 'Receptionist Dashboard',
      tiles: const [
        _DashboardTile(
          title: 'Bookings',
          icon: Icons.book,
          route: AppRoutes.bookings,
        ),
        _DashboardTile(
          title: 'Rooms',
          icon: Icons.king_bed,
          route: AppRoutes.rooms,
        ),
        _DashboardTile(
          title: 'Check-In/Out',
          icon: Icons.login,
          route: AppRoutes.checkIn,
        ),
        _DashboardTile(
          title: 'Guests',
          icon: Icons.person,
          route: AppRoutes.guests,
        ),
      ],
    );
  }
}

class HousekeepingDashboard extends StatelessWidget {
  const HousekeepingDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return _DashboardLayout(
      title: 'Housekeeping Dashboard',
      tiles: const [
        _DashboardTile(
          title: 'Cleaning Tasks',
          icon: Icons.cleaning_services,
          route: AppRoutes.housekeepingTasks,
        ),
      ],
    );
  }
}

class _DashboardLayout extends StatelessWidget {
  final String title;
  final List<_DashboardTile> tiles;

  const _DashboardLayout({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<SessionProvider>().logout();
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: tiles,
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final String route;

  const _DashboardTile({
    required this.title,
    required this.icon,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Wrap in try-catch or test route presence so stubs don't crash the shell
          try {
            Navigator.pushNamed(context, route);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Screen not yet implemented for $route')),
            );
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
