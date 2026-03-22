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

bool _canManageStayOps(StaffRole? role) =>
    role == StaffRole.admin || role == StaffRole.receptionist;

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

  Future<void> _handleRefresh() async {
    _refresh();
    try {
      await _future;
    } catch (_) {
      // Ignore errors because RefreshIndicator already surfaces them via UI.
    }
  }

  Future<void> _doCheckIn(BookingModel booking) async {
    if (booking.id == null) return;

    try {
      final evaluation =
          await _stayService.evaluateBookingForCheckIn(booking.id!);
      if (!evaluation.canProceed) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(evaluation.message ??
                    'Booking not eligible for check-in.')),
          );
        }
        return;
      }

      final roomId = booking.roomId;
      if (roomId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking has no assigned room.')),
          );
        }
        return;
      }

      await _stayService.checkIn(booking.id!, roomId);
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
    if (!_canManageStayOps(session.role)) {
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
          final ready =
              all.where((b) => b.roomId != null).toList(growable: false);
          final needsRoom =
              all.where((b) => b.roomId == null).toList(growable: false);

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (needsRoom.isNotEmpty)
                  _InfoBanner(
                    title: 'Waiting for room assignment',
                    message:
                        '${needsRoom.length} booking(s) still need a room before check-in.',
                  ),
                if (ready.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No BOOKED bookings with assigned rooms yet.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ...ready.map(
                    (b) => Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(b.guestName),
                        subtitle: Text(
                          'Room: ${b.roomId}\n${DateFormatter.formatDate(b.checkInDate)} → ${DateFormatter.formatDate(b.checkOutDate)}',
                        ),
                        trailing: FilledButton(
                          onPressed: () => _doCheckIn(b),
                          child: const Text('Check-in'),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
  final BookingRepository _bookingRepo = BookingRepository();
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _saving = false;
  int? _bookingId;
  BookingModel? _booking;
  bool _loadingBooking = false;
  bool _didInitArgs = false;
  String? _bookingError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitArgs) return;
    _didInitArgs = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is BookingIdArgs) _bookingId = args.bookingId;
    if (_bookingId != null) {
      _loadBooking();
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBooking() async {
    final id = _bookingId;
    if (id == null) return;
    setState(() {
      _loadingBooking = true;
      _bookingError = null;
    });
    try {
      final booking = await _bookingRepo.getBookingById(id);
      if (!mounted) return;
      setState(() => _booking = booking);
    } catch (e) {
      if (!mounted) return;
      setState(() => _bookingError = 'Failed to load booking: $e');
    } finally {
      if (mounted) setState(() => _loadingBooking = false);
    }
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
    final role = context.watch<SessionProvider>().role;
    if (!_canManageStayOps(role)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Surcharge')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Only admin or reception can add surcharges.'),
          ),
        ),
      );
    }

    final bookingHeader = _buildBookingHeader();
    final canSubmit = !_saving && _bookingError == null && _bookingId != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Surcharge')),
      body: AbsorbPointer(
        absorbing: _saving,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_loadingBooking) const LinearProgressIndicator(minHeight: 2),
              if (bookingHeader != null) ...[
                bookingHeader,
                const SizedBox(height: 16),
              ],
              if (_bookingError != null)
                _InfoBanner(
                  title: 'Booking unavailable',
                  message: _bookingError!,
                  isError: true,
                ),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Description is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Amount is required'
                    : null,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: canSubmit ? _save : null,
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

  Widget? _buildBookingHeader() {
    if (_bookingId == null) {
      return const _InfoBanner(
        title: 'Missing booking',
        message: 'This screen requires a booking context.',
        isError: true,
      );
    }

    final booking = _booking;
    if (booking == null) {
      return _bookingError == null
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Loading booking details...'),
            )
          : null;
    }

    return Card(
      child: ListTile(
        title: Text(booking.guestName),
        subtitle: Text(
          'Booking #${booking.id ?? '-'} - Room: ${booking.roomId ?? '-'}\n'
          '${DateFormatter.formatDate(booking.checkInDate)} → '
          '${DateFormatter.formatDate(booking.checkOutDate)}',
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

  Future<void> _handleRefresh() async {
    _refresh();
    try {
      await _future;
    } catch (_) {}
  }

  Future<void> _openSurchargeForm(int bookingId) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.surchargeForm,
      arguments: BookingIdArgs(bookingId: bookingId),
    );
    if (result == true) await _handleRefresh();
  }

  Future<void> _confirmCheckout(BookingModel booking) async {
    if (booking.id == null || booking.roomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking must have an assigned room.')),
      );
      return;
    }

    final quote = await _stayService.buildCheckoutQuote(booking);

    if (!mounted) return;
    final ok = await _showCheckoutDialog(booking, quote);
    if (ok != true) return;

    if (!mounted) return;
    final session = context.read<SessionProvider>();
    final currentUserId = session.currentUser?.id;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Missing session user. Please login again.')),
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
        quote: quote,
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
    if (!_canManageStayOps(session.role)) {
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
                child: Text(
                    'Failed to load checked-in bookings.\n${snapshot.error}'),
              ),
            );
          }
          final bookings = snapshot.data ?? const <BookingModel>[];
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: bookings.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 48),
                      Center(child: Text('No CHECKED_IN bookings right now.')),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                              onPressed: b.id == null
                                  ? null
                                  : () => _openSurchargeForm(b.id!),
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
                  ),
          );
        },
      ),
    );
  }

  Future<bool?> _showCheckoutDialog(BookingModel booking, CheckoutQuote quote) {
    return showDialog<bool>(
      context: context,
      builder: (_) {
        bool cashReceived = false;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Confirm checkout'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Guest: ${booking.guestName}'),
                  Text('Room: ${booking.roomId ?? '-'}'),
                  Text('Nights: ${quote.nights}'),
                  const SizedBox(height: 8),
                  Text('Room charge: ${quote.roomCharge.toStringAsFixed(2)}'),
                  Text(
                      'Surcharges: ${quote.surchargeTotal.toStringAsFixed(2)}'),
                  const Divider(height: 20),
                  Text(
                    'Total: ${quote.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: cashReceived,
                    onChanged: (v) => setState(() => cashReceived = v ?? false),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Cash payment received'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed:
                    cashReceived ? () => Navigator.pop(context, true) : null,
                child: const Text('Checkout'),
              ),
            ],
          ),
        );
      },
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
    final role = context.watch<SessionProvider>().role;
    if (!_canManageStayOps(role)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Only admin or reception can view invoices.'),
          ),
        ),
      );
    }

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
                    const Card(
                      child: ListTile(
                        title: Text('Payment method'),
                        subtitle: Text('Cash'),
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
                        subtitle: Text(
                            DateFormatter.formatDateTime(invoice.issuedAt)),
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
                        trailing:
                            Text(invoice.surchargeTotal.toStringAsFixed(2)),
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

class _InfoBanner extends StatelessWidget {
  final String title;
  final String message;
  final bool isError;

  const _InfoBanner({
    required this.title,
    required this.message,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor =
        isError ? colorScheme.errorContainer : colorScheme.secondaryContainer;
    final textColor = isError
        ? colorScheme.onErrorContainer
        : colorScheme.onSecondaryContainer;

    return Card(
      color: bgColor,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(message, style: TextStyle(color: textColor)),
          ],
        ),
      ),
    );
  }
}
