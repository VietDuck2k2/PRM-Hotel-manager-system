import 'package:flutter/material.dart';

/// Staff List Screen stub.
/// TODO (Member 4): Implement with UserRepository.getAllUsers().
class StaffListScreen extends StatelessWidget {
  const StaffListScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Staff')),
        body: const Center(child: Text('Staff list — to be implemented')),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/staff/form'),
          child: const Icon(Icons.person_add),
        ),
      );
}

/// Staff Form Screen stub.
/// TODO (Member 4): Implement — input fullName, username, password, role.
class StaffFormScreen extends StatelessWidget {
  const StaffFormScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Staff Member')),
        body: const Center(child: Text('Staff form — to be implemented')),
      );
}
