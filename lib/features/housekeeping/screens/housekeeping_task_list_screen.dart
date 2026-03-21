import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_enums.dart';
import '../../auth/session_provider.dart';
import '../../../data/models/room_model.dart';
import '../../../data/repositories/room_repository.dart';

class HousekeepingTaskListScreen extends StatefulWidget {
  const HousekeepingTaskListScreen({super.key});

  @override
  State<HousekeepingTaskListScreen> createState() =>
      _HousekeepingTaskListScreenState();
}

class _HousekeepingTaskListScreenState
    extends State<HousekeepingTaskListScreen> {
  final RoomRepository _roomRepository = RoomRepository();

  bool _loading = true;
  List<RoomModel> _dirtyRooms = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rooms = await _roomRepository.getRoomsByStatus(RoomStatus.dirty);
    setState(() {
      _dirtyRooms = rooms;
      _loading = false;
    });
  }

  Future<void> _markClean(int roomId) async {
    try {
      await _roomRepository.markRoomAvailable(roomId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room marked as AVAILABLE')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark clean: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<SessionProvider>().role;

    if (role != StaffRole.housekeeping) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cleaning Tasks')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Access denied'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Cleaning Tasks')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _dirtyRooms.isEmpty
              ? const Center(child: Text('No dirty rooms right now'))
              : ListView.builder(
                  itemCount: _dirtyRooms.length,
                  itemBuilder: (context, i) {
                    final room = _dirtyRooms[i];
                    final roomId = room.id;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        title: Text('Room ${room.roomNumber}'),
                        subtitle: Text('Status: ${room.status.toDbString()}'),
                        trailing: ElevatedButton(
                          onPressed: roomId == null ? null : () => _markClean(roomId),
                          child: const Text('Mark Clean'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
