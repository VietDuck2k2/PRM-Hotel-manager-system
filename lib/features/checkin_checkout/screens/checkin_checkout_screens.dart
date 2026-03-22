import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/surcharge_model.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/repositories/surcharge_repository.dart';
import '../../auth/session_provider.dart';
import '../services/stay_service.dart';

@immutable
class BookingIdArgs {
  final int bookingId;
  const BookingIdArgs({required this.bookingId});
}

@immutable
class InvoiceDetailArgs {
  final int bookingId;
  const InvoiceDetailArgs({required this.bookingId});
}

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final _bookingRepo = BookingRepository();
  final _stayService = StayService();

  late Future<List<BookingModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _bookingRepo.getBookingsByStatus(BookingStatus.booked);
  }

  void _refresh() {
    setState(() {
      _future = _bookingRepo.getBookingsByStatus(BookingStatus.booked);
    });
  }

  Future<void> _doCheckIn(BookingModel booking) async {
    if (booking.id == null) return;
    if (booking.roomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking has no assigned room.')),
      );
      return;
    }
    try {
      await _stayService.checkIn(booking.id!, booking.roomId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checked in successfully.')),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Check-in failed.\n$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    if (session.role != StaffRole.admin && session.role != StaffRole.receptionist) {
      return Scaffold(
        appBar: AppBar(title: const Text('Check-In')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'You do not have permission to perform check-in.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-In'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<BookingModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load bookings.\n${snapshot.error}'),
              ),
            );
          }
          final all = snapshot.data ?? const <BookingModel>[];
          final bookings = all.where((b) => b.roomId != null).toList();
          if (bookings.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No BOOKED bookings with assigned rooms.\nAssign a room first.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: bookings.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final b = bookings[i];
              final subtitle =
                  'Room: ${b.roomId} • ${DateFormatter.formatDate(b.checkInDate)} → ${DateFormatter.formatDate(b.checkOutDate)}';
              return ListTile(
                title: Text(b.guestName),
                subtitle: Text(subtitle),
                trailing: FilledButton(
                  onPressed: () => _doCheckIn(b),
                  child: const Text('Check-in'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class SurchargeFormScreen extends StatefulWidget {
  const SurchargeFormScreen({super.key});

  @override
  State<SurchargeFormScreen> createState() => _SurchargeFormScreenState();
}

class _SurchargeFormScreenState extends State<SurchargeFormScreen> {
  final _repo = SurchargeRepository();
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _saving = false;
  int? _bookingId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bookingId != null) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is BookingIdArgs) _bookingId = args.bookingId;
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final bookingId = _bookingId;
    if (bookingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing bookingId for surcharge.')),
      );
      return;
    }
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount must be a positive number.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final surcharge = SurchargeModel(
        bookingId: bookingId,
        description: _descCtrl.text.trim(),
        amount: amount,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _repo.addSurcharge(surcharge);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add surcharge.\n$e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Surcharge')),
      body: AbsorbPointer(
        absorbing: _saving,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Description is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Amount is required' : null,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _save,
                icon: _saving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.add),
                label: Text(_saving ? 'Saving...' : 'Add surcharge'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _bookingRepo = BookingRepository();
  final _surchargeRepo = SurchargeRepository();
  final _stayService = StayService();

  late Future<List<BookingModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _bookingRepo.getBookingsByStatus(BookingStatus.checkedIn);
  }

  void _refresh() {
    setState(() {
      _future = _bookingRepo.getBookingsByStatus(BookingStatus.checkedIn);
    });
  }

  Future<void> _openSurchargeForm(int bookingId) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.surchargeForm,
      arguments: BookingIdArgs(bookingId: bookingId),
    );
    if (result == true) _refresh();
  }

  Future<void> _confirmCheckout(BookingModel booking) async {
    if (booking.id == null || booking.roomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking must have an assigned room.')),
      );
      return;
    }

    final surchargeTotal = await _surchargeRepo.getTotalSurcharge(booking.id!);
    final nights = DateFormatter.calculateNights(booking.checkInDate, booking.checkOutDate);
    final roomCharge = nights * booking.bookedPricePerNight;
    final total = roomCharge + surchargeTotal;

    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm checkout'),
        content: Text(
          'Guest: ${booking.guestName}\n'
              'Room: ${booking.roomId}\n'
              'Nights: $nights\n'
              'Room charge: $roomCharge\n'
              'Surcharges: $surchargeTotal\n'
              'Total: $total',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Checkout'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    if (!mounted) return;
    final session = context.read<SessionProvider>();
    final currentUserId = session.currentUser?.id;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing session user. Please login again.')),
      );
      return;
    }

    try {
      final invoice = await _stayService.checkout(
        bookingId: booking.id!,
        roomId: booking.roomId!,
        checkInMs: booking.checkInDate,
        checkOutMs: booking.checkOutDate,
        bookedPricePerNight: booking.bookedPricePerNight,
        currentUserId: currentUserId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checkout successful. Invoice created.')),
      );
      _refresh();
      await Navigator.pushNamed(
        context,
        AppRoutes.invoiceDetail,
        arguments: InvoiceDetailArgs(bookingId: invoice.bookingId),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout failed.\n$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    if (session.role != StaffRole.admin && session.role != StaffRole.receptionist) {
      return Scaffold(
        appBar: AppBar(title: const Text('Check-Out')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'You do not have permission to perform checkout.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-Out'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<BookingModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load checked-in bookings.\n${snapshot.error}'),
              ),
            );
          }
          final bookings = snapshot.data ?? const <BookingModel>[];
          if (bookings.isEmpty) {
            return const Center(child: Text('No CHECKED_IN bookings.'));
          }
          return ListView.separated(
            itemCount: bookings.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final b = bookings[i];
              final subtitle =
                  'Room: ${b.roomId ?? '-'} • ${DateFormatter.formatDate(b.checkInDate)} → ${DateFormatter.formatDate(b.checkOutDate)}';
              return ListTile(
                title: Text(b.guestName),
                subtitle: Text(subtitle),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: b.id == null ? null : () => _openSurchargeForm(b.id!),
                      child: const Text('Surcharge'),
                    ),
                    FilledButton(
                      onPressed: () => _confirmCheckout(b),
                      child: const Text('Checkout'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class InvoiceDetailScreen extends StatefulWidget {
  const InvoiceDetailScreen({super.key});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final _repo = InvoiceRepository();
  int? _bookingId;
  Future<InvoiceModel?>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bookingId != null) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is InvoiceDetailArgs) {
      _bookingId = args.bookingId;
      _future = _repo.getInvoiceByBookingId(args.bookingId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice')),
      body: _future == null
          ? const Center(child: Text('Missing invoice context.'))
          : FutureBuilder<InvoiceModel?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load invoice.\n${snapshot.error}'),
              ),
            );
          }
          final invoice = snapshot.data;
          if (invoice == null) {
            return const Center(child: Text('Invoice not found.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  title: const Text('Booking'),
                  subtitle: Text('#${invoice.bookingId}'),
                ),
              ),
                    Card(
                      child: ListTile(
                        title: const Text('Issued by (User ID)'),
                        subtitle: Text('${invoice.issuedBy}'),
                      ),
                    ),
              Card(
                child: ListTile(
                  title: const Text('Issued at'),
                  subtitle: Text(DateFormatter.formatDateTime(invoice.issuedAt)),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Room charge'),
                  trailing: Text(invoice.roomCharge.toStringAsFixed(2)),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Surcharges'),
                  trailing: Text(invoice.surchargeTotal.toStringAsFixed(2)),
                ),
              ),
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: ListTile(
                  title: const Text('Total'),
                  trailing: Text(
                    invoice.totalAmount.toStringAsFixed(2),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
