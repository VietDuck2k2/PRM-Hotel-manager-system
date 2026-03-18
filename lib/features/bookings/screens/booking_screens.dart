import 'package:flutter/material.dart';

/// Booking List Screen stub.
/// TODO (Member 2): Implement full list with BookingRepository.
class BookingListScreen extends StatelessWidget {
  const BookingListScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Bookings')),
        body: const Center(child: Text('Booking list — to be implemented')),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/bookings/create'),
          child: const Icon(Icons.add),
        ),
      );
}

/// Booking Detail Screen stub.
class BookingDetailScreen extends StatelessWidget {
  const BookingDetailScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Booking Detail')),
        body: const Center(child: Text('Booking detail — to be implemented')),
      );
}

/// Create Booking Screen stub.
class CreateBookingScreen extends StatelessWidget {
  const CreateBookingScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('New Booking')),
        body: const Center(child: Text('Create booking form — to be implemented')),
      );
}

/// Assign Room Screen stub.
class AssignRoomScreen extends StatelessWidget {
  const AssignRoomScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Assign Room')),
        body: const Center(child: Text('Room assignment — to be implemented')),
      );
}

/// Cancel Booking Screen stub.
class CancelBookingScreen extends StatelessWidget {
  const CancelBookingScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Cancel Booking')),
        body: const Center(child: Text('Cancel booking — to be implemented')),
      );
}
