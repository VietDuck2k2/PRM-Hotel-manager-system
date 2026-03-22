import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/session_provider.dart';
import '../../../core/constants/app_routes.dart';

/// Dashboard for admin role.
/// Links to shell tiles only — downstream screens live in other modules.
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DashboardGrid(
      title: 'Admin Dashboard',
      tiles: [
        _DashboardTileData(
            icon: Icons.people, label: 'Staff', route: AppRoutes.staffList),
        _DashboardTileData(
            icon: Icons.category,
            label: 'Room Types',
            route: AppRoutes.roomTypeList),
        _DashboardTileData(
            icon: Icons.meeting_room,
            label: 'Rooms',
            route: AppRoutes.roomList),
        _DashboardTileData(
            icon: Icons.book_online,
            label: 'Bookings',
            route: AppRoutes.bookingList),
        _DashboardTileData(
            icon: Icons.login, label: 'Check-In', route: AppRoutes.checkIn),
        _DashboardTileData(
            icon: Icons.logout, label: 'Check-Out', route: AppRoutes.checkout),
      ],
    );
  }
}

/// Dashboard for receptionist role.
class ReceptionistDashboard extends StatelessWidget {
  const ReceptionistDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DashboardGrid(
      title: 'Receptionist Dashboard',
      tiles: [
        _DashboardTileData(
            icon: Icons.book_online,
            label: 'Bookings',
            route: AppRoutes.bookingList),
        _DashboardTileData(
            icon: Icons.meeting_room,
            label: 'Rooms',
            route: AppRoutes.roomList),
        _DashboardTileData(
            icon: Icons.login, label: 'Check-In', route: AppRoutes.checkIn),
        _DashboardTileData(
            icon: Icons.logout, label: 'Check-Out', route: AppRoutes.checkout),
      ],
    );
  }
}

/// Dashboard for housekeeping role.
class HousekeepingDashboard extends StatelessWidget {
  const HousekeepingDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DashboardGrid(
      title: 'Housekeeping',
      tiles: [
        _DashboardTileData(
          icon: Icons.cleaning_services,
          label: 'Cleaning Tasks',
          route: AppRoutes.housekeepingTaskList,
        ),
      ],
    );
  }
}

class _DashboardGrid extends StatelessWidget {
  final String title;
  final List<_DashboardTileData> tiles;

  const _DashboardGrid({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    Widget content;
    if (tiles.length == 1) {
      content = Center(
        child: SizedBox(
          width: 220,
          child: _DashboardTile(data: tiles.first),
        ),
      );
    } else {
      content = GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: tiles
            .map((tile) => _DashboardTile(data: tile))
            .toList(growable: false),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _handleLogout(context, session),
          ),
        ],
      ),
      body: content,
    );
  }

  void _handleLogout(BuildContext context, SessionProvider session) {
    session.logout();
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }
}

class _DashboardTileData {
  final IconData icon;
  final String label;
  final String route;

  const _DashboardTileData({
    required this.icon,
    required this.label,
    required this.route,
  });
}

class _DashboardTile extends StatelessWidget {
  final _DashboardTileData data;

  const _DashboardTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, data.route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(data.icon, size: 40, color: const Color(0xFF1A6B8A)),
              const SizedBox(height: 8),
              Text(
                data.label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
