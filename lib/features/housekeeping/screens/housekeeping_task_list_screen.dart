import 'package:flutter/material.dart';

/// Housekeeping Task List Screen stub.
/// TODO (Member 3): Implement — Query rooms WHERE status = 'DIRTY',
///   show list, tap to call RoomRepository.markRoomAvailable().
class HousekeepingTaskListScreen extends StatelessWidget {
  const HousekeepingTaskListScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Cleaning Tasks')),
        body: const Center(child: Text('Dirty rooms list — to be implemented')),
      );
}
