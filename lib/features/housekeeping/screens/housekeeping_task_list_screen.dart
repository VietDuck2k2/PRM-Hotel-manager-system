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
  bool _initialLoadDone = false;
  List<RoomModel> _dirtyRooms = [];
  String? _error;
  final Set<int> _processingRooms = <int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_initialLoadDone && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final rooms = await _roomRepository.getRoomsNeedingCleaning();
      if (!mounted) return;
      setState(() {
        _dirtyRooms = rooms;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load cleaning tasks: $e';
        _dirtyRooms = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _initialLoadDone = true;
        });
      }
    }
  }

  Future<void> _refresh() => _load();

  Future<void> _markClean(int roomId) async {
    setState(() {
      _processingRooms.add(roomId);
    });
    try {
      final updated = await _roomRepository.markRoomAvailable(roomId);
      if (!mounted) return;
      if (updated == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Room is already marked clean')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Room marked as AVAILABLE')),
        );
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark clean: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingRooms.remove(roomId);
        });
      }
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
      body: _loading && !_initialLoadDone
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: _buildBody(),
            ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _load,
            child: const Text('Retry'),
          ),
        ],
      );
    }

    if (_dirtyRooms.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
          SizedBox(height: 12),
          Text(
            'No dirty rooms right now',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _dirtyRooms.length,
      itemBuilder: (context, i) {
        final room = _dirtyRooms[i];
        final roomId = room.id;
        final isProcessing =
            roomId != null && _processingRooms.contains(roomId);
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            title: Text('Room ${room.roomNumber}'),
            subtitle: Text('Status: ${room.status.toDbString()}'),
            trailing: roomId == null
                ? const SizedBox()
                : FilledButton(
                    onPressed: isProcessing ? null : () => _markClean(roomId),
                    child: isProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Mark clean'),
                  ),
          ),
        );
      },
    );
  }
}
