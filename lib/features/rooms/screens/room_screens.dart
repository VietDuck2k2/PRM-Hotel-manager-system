import 'package:flutter/material.dart';

/// Room Type List Screen stub.
/// TODO (Member 3): Implement with RoomTypeRepository.
class RoomTypeListScreen extends StatelessWidget {
  const RoomTypeListScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Room Types')),
        body: const Center(child: Text('Room types — to be implemented')),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/room-types/form'),
          child: const Icon(Icons.add),
        ),
      );
}

/// Room Type Form Screen stub.
class RoomTypeFormScreen extends StatelessWidget {
  const RoomTypeFormScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Room Type')),
        body: const Center(child: Text('Room type form — to be implemented')),
      );
}

/// Room List Screen stub.
/// TODO (Member 3): Implement with RoomRepository.
class RoomListScreen extends StatelessWidget {
  const RoomListScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Rooms')),
        body: const Center(child: Text('Rooms — to be implemented')),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/rooms/form'),
          child: const Icon(Icons.add),
        ),
      );
}

/// Room Form Screen stub.
class RoomFormScreen extends StatelessWidget {
  const RoomFormScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Room')),
        body: const Center(child: Text('Room form — to be implemented')),
      );
}
