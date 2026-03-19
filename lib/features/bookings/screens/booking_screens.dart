import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/date_formatter.dart';
import '../../auth/session_provider.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/models/room_model.dart';
import '../../../data/models/room_type_model.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../data/repositories/room_repository.dart';
import '../../../data/repositories/room_type_repository.dart';

int? _bookingIdFromArgs(BuildContext context) {
  final args = ModalRoute.of(context)?.settings.arguments;
  if (args is int) return args;
  if (args is Map) {
    final dynamic maybeId = args['bookingId'];
    if (maybeId is int) return maybeId;
  }
  return null;
}

String _bookingStatusLabel(BookingStatus status) {
  switch (status) {
    case BookingStatus.booked:
      return 'BOOKED';
    case BookingStatus.cancelled:
      return 'CANCELLED';
    case BookingStatus.checkedIn:
      return 'CHECKED_IN';
    case BookingStatus.checkedOut:
      return 'CHECKED_OUT';
  }
}

/// Booking List Screen
/// - Filter by status
/// - Navigate to booking detail
class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  final BookingRepository _bookingRepo = BookingRepository();

  BookingStatus _selectedStatus = BookingStatus.booked;
  Future<List<BookingModel>>? _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _bookingsFuture = _bookingRepo.getBookingsByStatus(_selectedStatus);
  }

  void _setStatus(BookingStatus status) {
    setState(() {
      _selectedStatus = status;
      _bookingsFuture = _bookingRepo.getBookingsByStatus(_selectedStatus);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bookings')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('BOOKED'),
                  selected: _selectedStatus == BookingStatus.booked,
                  onSelected: (_) => _setStatus(BookingStatus.booked),
                ),
                ChoiceChip(
                  label: const Text('CANCELLED'),
                  selected: _selectedStatus == BookingStatus.cancelled,
                  onSelected: (_) => _setStatus(BookingStatus.cancelled),
                ),
                ChoiceChip(
                  label: const Text('CHECKED_IN'),
                  selected: _selectedStatus == BookingStatus.checkedIn,
                  onSelected: (_) => _setStatus(BookingStatus.checkedIn),
                ),
                ChoiceChip(
                  label: const Text('CHECKED_OUT'),
                  selected: _selectedStatus == BookingStatus.checkedOut,
                  onSelected: (_) => _setStatus(BookingStatus.checkedOut),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<BookingModel>>(
              future: _bookingsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load bookings: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                final bookings = snapshot.data ?? [];
                if (bookings.isEmpty) {
                  return const Center(child: Text('No bookings found.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    final bookingId = booking.id;
                    if (bookingId == null) {
                      return const SizedBox.shrink();
                    }
                    return Card(
                      child: ListTile(
                        title: Text(
                          booking.guestName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${DateFormatter.formatDate(booking.checkInDate)} -> ${DateFormatter.formatDate(booking.checkOutDate)}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _bookingStatusLabel(booking.status),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              booking.roomId != null ? 'Room: ${booking.roomId}' : 'No room',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.bookingDetail,
                            arguments: bookingId,
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.createBooking),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Booking Detail Screen
/// - Show booking fields
/// - Show action buttons depending on status
class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({super.key});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final BookingRepository _bookingRepo = BookingRepository();
  final RoomRepository _roomRepo = RoomRepository();
  final RoomTypeRepository _roomTypeRepo = RoomTypeRepository();

  int? _bookingId;
  bool _didLoad = false;
  BookingModel? _booking;
  RoomModel? _room;
  RoomTypeModel? _roomType;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bookingId ??= _bookingIdFromArgs(context);
    if (!_didLoad) {
      _didLoad = true;
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final bookingId = _bookingId;
    if (bookingId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Missing bookingId in route arguments.';
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final booking = await _bookingRepo.getBookingById(bookingId);
      if (booking == null) {
        setState(() {
          _booking = null;
          _room = null;
          _roomType = null;
          _errorMessage = 'Booking not found.';
          _isLoading = false;
        });
        return;
      }

      RoomModel? room;
      if (booking.roomId != null) {
        room = await _roomRepo.getRoomById(booking.roomId!);
      }

      final roomType = await _roomTypeRepo.getRoomTypeById(booking.roomTypeId);

      if (!mounted) return;
      setState(() {
        _booking = booking;
        _room = room;
        _roomType = roomType;
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingId = _bookingId;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Detail'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : (_booking == null
                  ? const Center(child: Text('Booking not found.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _booking!.guestName,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text('Phone: ${_booking!.guestPhone}'),
                          const SizedBox(height: 12),
                          Text(
                            'Dates: ${DateFormatter.formatDate(_booking!.checkInDate)} -> ${DateFormatter.formatDate(_booking!.checkOutDate)}',
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Room Type: ${_roomType?.name ?? "ID ${_booking!.roomTypeId}"}',
                          ),
                          const SizedBox(height: 12),
                          Text('Booked price/night: ${_booking!.bookedPricePerNight}'),
                          const SizedBox(height: 12),
                          Text(
                            'Status: ${_bookingStatusLabel(_booking!.status)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Assigned room: ${_room?.roomNumber ?? (_booking!.roomId != null ? "Room ID ${_booking!.roomId}" : "Not assigned")}',
                          ),
                          if (_booking!.cancelReason != null) ...[
                            const SizedBox(height: 12),
                            Text('Cancel reason: ${_booking!.cancelReason}'),
                          ],
                          const SizedBox(height: 16),
                          if (_booking!.status == BookingStatus.booked) ...[
                            if (_booking!.roomId == null)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.meeting_room_outlined),
                                  label: const Text('Assign Room'),
                                  onPressed: () async {
                                    if (bookingId == null) return;
                                    final res = await Navigator.pushNamed(
                                      context,
                                      AppRoutes.assignRoom,
                                      arguments: bookingId,
                                    );
                                    if (res == true && mounted) {
                                      _refresh();
                                    }
                                  },
                                ),
                              ),
                            if (_booking!.roomId == null) const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.cancel_outlined),
                                label: const Text('Cancel Booking'),
                                onPressed: () async {
                                  if (bookingId == null) return;
                                  final res = await Navigator.pushNamed(
                                    context,
                                    AppRoutes.cancelBooking,
                                    arguments: bookingId,
                                  );
                                  if (res == true && mounted) {
                                    _refresh();
                                  }
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ))
    );
  }
}

/// Create Booking Screen
class CreateBookingScreen extends StatefulWidget {
  const CreateBookingScreen({super.key});

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final BookingRepository _bookingRepo = BookingRepository();
  final RoomTypeRepository _roomTypeRepo = RoomTypeRepository();

  bool _isSaving = false;
  String? _submitError;

  List<RoomTypeModel> _roomTypes = const [];
  int? _selectedRoomTypeId;

  DateTime? _checkInDate;
  DateTime? _checkOutDate;

  final TextEditingController _guestNameController = TextEditingController();
  final TextEditingController _guestPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRoomTypes();

    final today = DateTime.now();
    _checkInDate = DateTime(today.year, today.month, today.day);
    _checkOutDate = DateTime(today.year, today.month, today.day + 1);
  }

  @override
  void dispose() {
    _guestNameController.dispose();
    _guestPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadRoomTypes() async {
    final roomTypes = await _roomTypeRepo.getAllRoomTypes();
    if (!mounted) return;
    setState(() {
      _roomTypes = roomTypes;
      _selectedRoomTypeId = roomTypes.isNotEmpty ? roomTypes.first.id : null;
    });
  }

  Future<void> _pickDate({required bool isCheckIn}) async {
    final initial = (isCheckIn ? _checkInDate : _checkOutDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    final normalized = DateTime(picked.year, picked.month, picked.day);
    setState(() {
      if (isCheckIn) {
        _checkInDate = normalized;
        // If check-in moves past check-out, keep check-out >= check-in + 1 day.
        if (_checkOutDate != null && !_checkOutDate!.isAfter(_checkInDate!)) {
          _checkOutDate = _checkInDate!.add(const Duration(days: 1));
        }
      } else {
        _checkOutDate = normalized;
      }
    });
  }

  Future<void> _submit() async {
    setState(() {
      _submitError = null;
    });
    final formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk) return;

    final checkIn = _checkInDate;
    final checkOut = _checkOutDate;
    if (checkIn == null || checkOut == null) {
      setState(() => _submitError = 'Please select both check-in and check-out dates.');
      return;
    }
    if (!checkOut.isAfter(checkIn)) {
      setState(() => _submitError = 'Check-out date must be after check-in date.');
      return;
    }
    if (_selectedRoomTypeId == null) {
      setState(() => _submitError = 'Please select a room type.');
      return;
    }

    final session = context.read<SessionProvider>();
    final currentUserId = session.userId;
    if (currentUserId == null) {
      setState(() => _submitError = 'You must be logged in to create a booking.');
      return;
    }

    final roomType = _roomTypes.firstWhere((rt) => rt.id == _selectedRoomTypeId);

    setState(() => _isSaving = true);
    try {
      final booking = BookingModel(
        guestName: _guestNameController.text.trim(),
        guestPhone: _guestPhoneController.text.trim(),
        roomTypeId: roomType.id!,
        roomId: null,
        checkInDate: DateFormatter.toMs(checkIn),
        checkOutDate: DateFormatter.toMs(checkOut),
        bookedPricePerNight: roomType.pricePerNight, // price snapshot
        status: BookingStatus.booked,
        cancelReason: null,
        createdBy: currentUserId,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      final bookingId = await _bookingRepo.createBooking(booking);

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.bookingDetail,
        arguments: bookingId,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitError = e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Booking')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _guestNameController,
                  decoration: const InputDecoration(labelText: 'Guest name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Guest name is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _guestPhoneController,
                  decoration: const InputDecoration(labelText: 'Guest phone'),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Guest phone is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  key: ValueKey<int?>(_selectedRoomTypeId),
                  initialValue: _selectedRoomTypeId,
                  decoration: const InputDecoration(labelText: 'Room type'),
                  items: _roomTypes
                      .map(
                        (rt) => DropdownMenuItem<int>(
                          value: rt.id!,
                          child: Text('${rt.name} (${rt.pricePerNight}/night)'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedRoomTypeId = value),
                  validator: (value) =>
                      value == null ? 'Room type is required.' : null,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _pickDate(isCheckIn: true),
                  child: Text(
                    'Check-in: ${_checkInDate == null ? '-' : DateFormatter.formatDate(DateFormatter.toMs(_checkInDate!))}',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _pickDate(isCheckIn: false),
                  child: Text(
                    'Check-out: ${_checkOutDate == null ? '-' : DateFormatter.formatDate(DateFormatter.toMs(_checkOutDate!))}',
                  ),
                ),
                if (_submitError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _submitError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save booking'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_roomTypes.isEmpty)
            const Text('Loading room types...', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

/// Assign Room Screen
class AssignRoomScreen extends StatefulWidget {
  const AssignRoomScreen({super.key});

  @override
  State<AssignRoomScreen> createState() => _AssignRoomScreenState();
}

class _AssignRoomScreenState extends State<AssignRoomScreen> {
  final BookingRepository _bookingRepo = BookingRepository();
  final RoomRepository _roomRepo = RoomRepository();

  int? _bookingId;
  bool _didLoad = false;
  BookingModel? _booking;
  bool _isLoading = true;
  String? _errorMessage;

  List<RoomModel> _availableRooms = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bookingId ??= _bookingIdFromArgs(context);
    if (!_didLoad) {
      _didLoad = true;
      _load();
    }
  }

  Future<void> _load() async {
    final bookingId = _bookingId;
    if (bookingId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Missing bookingId in route arguments.';
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final booking = await _bookingRepo.getBookingById(bookingId);
      if (booking == null) {
        setState(() {
          _booking = null;
          _availableRooms = const [];
          _errorMessage = 'Booking not found.';
          _isLoading = false;
        });
        return;
      }

      final rawAvailable = await _roomRepo.getAvailableRoomsForDateRange(
        roomTypeId: booking.roomTypeId,
        checkInMs: booking.checkInDate,
        checkOutMs: booking.checkOutDate,
      );

      // Until Member 3 implements the overlap-aware SQL, fall back to showing
      // all AVAILABLE rooms of the same roomType.
      final rooms = rawAvailable.isEmpty
          ? (await _roomRepo.getAllRooms())
              .where((r) =>
                  r.roomTypeId == booking.roomTypeId && r.status == RoomStatus.available)
              .toList()
          : rawAvailable
              .where((r) => r.status == RoomStatus.available)
              .toList();

      if (!mounted) return;
      setState(() {
        _booking = booking;
        _availableRooms = rooms;
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _assignRoom(RoomModel room) async {
    final bookingId = _bookingId;
    final roomId = room.id;
    if (bookingId == null || roomId == null) return;

    try {
      final updated = await _bookingRepo.assignRoom(bookingId, roomId);
      if (updated > 0) {
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Room assignment failed. Booking may not be BOOKED.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assignment error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assign Room')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : (_booking == null
                  ? const Center(child: Text('Booking not found.'))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            '${_booking!.guestName} • ${DateFormatter.formatDate(_booking!.checkInDate)} -> ${DateFormatter.formatDate(_booking!.checkOutDate)}',
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: _availableRooms.isEmpty
                              ? const Center(child: Text('No rooms available to assign.'))
                              : ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _availableRooms.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final room = _availableRooms[index];
                                    return Card(
                                      child: ListTile(
                                        title: Text(room.roomNumber),
                                        subtitle: Text(
                                          'Status: ${room.status.toDbString()}',
                                        ),
                                        trailing: room.id != null
                                            ? const Icon(Icons.chevron_right)
                                            : null,
                                        onTap: () => _assignRoom(room),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    )),
    );
  }
}

/// Cancel Booking Screen
class CancelBookingScreen extends StatefulWidget {
  const CancelBookingScreen({super.key});

  @override
  State<CancelBookingScreen> createState() => _CancelBookingScreenState();
}

class _CancelBookingScreenState extends State<CancelBookingScreen> {
  final BookingRepository _bookingRepo = BookingRepository();

  int? _bookingId;
  bool _isCanceling = false;
  String? _errorMessage;

  final TextEditingController _reasonController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bookingId ??= _bookingIdFromArgs(context);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitCancel() async {
    setState(() {
      _errorMessage = null;
    });
    final bookingId = _bookingId;
    if (bookingId == null) {
      setState(() => _errorMessage = 'Missing bookingId in route arguments.');
      return;
    }

    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _errorMessage = 'Cancellation reason is required.');
      return;
    }

    setState(() => _isCanceling = true);
    try {
      final updated = await _bookingRepo.cancelBooking(bookingId, reason);
      if (!mounted) return;
      if (updated > 0) {
        Navigator.pop(context, true);
      } else {
        setState(() => _errorMessage = 'Cancellation failed. Booking may not be BOOKED.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isCanceling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cancel Booking')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'This action can only cancel bookings in status BOOKED.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Cancel reason',
              border: OutlineInputBorder(),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isCanceling ? null : _submitCancel,
            child: _isCanceling
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Confirm cancel'),
          ),
        ],
      ),
    );
  }
}
