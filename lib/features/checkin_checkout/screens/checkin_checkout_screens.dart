import 'package:flutter/material.dart';

/// Check-In Screen stub.
/// TODO (Member 4): Implement — verify booking.roomId != null, call StayService.checkIn().
class CheckInScreen extends StatelessWidget {
  const CheckInScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Check-In')),
        body: const Center(child: Text('Check-in — to be implemented')),
      );
}

/// Surcharge Form Screen stub.
/// TODO (Member 4): Implement — input description + amount, call SurchargeRepository.addSurcharge().
class SurchargeFormScreen extends StatelessWidget {
  const SurchargeFormScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Add Surcharge')),
        body: const Center(child: Text('Surcharge form — to be implemented')),
      );
}

/// Checkout Screen stub.
/// TODO (Member 4): Implement — show totals, confirm cash, call StayService.checkout().
class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Check-Out')),
        body: const Center(child: Text('Checkout — to be implemented')),
      );
}

/// Invoice Detail Screen stub.
/// TODO (Member 4): Implement — display InvoiceModel data.
class InvoiceDetailScreen extends StatelessWidget {
  const InvoiceDetailScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Invoice')),
        body: const Center(child: Text('Invoice detail — to be implemented')),
      );
}
