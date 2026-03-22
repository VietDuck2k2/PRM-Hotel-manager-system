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

  BookingStatus? _selectedStatus = BookingStatus.booked;
  Future<List<BookingModel>>? _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _bookingsFuture = _fetchBookings();
  }

  Future<List<BookingModel>> _fetchBookings() {
    if (_selectedStatus == null) {
      return _bookingRepo.getAllBookings();
    }
    return _bookingRepo.getBookingsByStatus(_selectedStatus!);
  }

  Future<void> _refresh() async {
    final future = _fetchBookings();
    setState(() {
      _bookingsFuture = future;
    });
    await future;
  }

  void _setStatus(BookingStatus? status) {
    if (_selectedStatus == status) return;
    setState(() {
      _selectedStatus = status;
      _bookingsFuture = _fetchBookings();
    });
  }

  Future<void> _openCreateBooking() async {
    final result = await Navigator.pushNamed(context, AppRoutes.createBooking);
    if (!mounted) return;
    if (result is int) {
      await _openBookingDetail(result);
    } else if (result == true) {
      await _refresh();
    }
  }

  Future<void> _openBookingDetail(int bookingId) async {
    final changed = await Navigator.pushNamed(
      context,
      AppRoutes.bookingDetail,
      arguments: bookingId,
    );
    if (changed == true && mounted) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusChips = <MapEntry<BookingStatus?, String>>[
      const MapEntry<BookingStatus?, String>(null, 'ALL'),
      const MapEntry<BookingStatus?, String>(BookingStatus.booked, 'BOOKED'),
      const MapEntry<BookingStatus?, String>(
          BookingStatus.cancelled, 'CANCELLED'),
      const MapEntry<BookingStatus?, String>(
          BookingStatus.checkedIn, 'CHECKED_IN'),
      const MapEntry<BookingStatus?, String>(
          BookingStatus.checkedOut, 'CHECKED_OUT'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Bookings')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: statusChips
                  .map(
                    (entry) => ChoiceChip(
                      label: Text(entry.value),
                      selected: _selectedStatus == entry.key,
                      onSelected: (_) => _setStatus(entry.key),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<BookingModel>>(
                future: _bookingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'Failed to load bookings:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  }
                  final bookings = snapshot.data ?? [];
                  if (bookings.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text('No bookings found for this filter.'),
                          ),
                        ),
                      ],
                    );
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
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                booking.roomId != null
                                    ? 'Room: ${booking.roomId}'
                                    : 'No room',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          onTap: () => _openBookingDetail(bookingId),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateBooking,
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
  bool _hasUpdates = false;

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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.pop(context, _hasUpdates);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Booking Detail'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _hasUpdates),
          ),
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
                            Text(
                                'Booked price/night: ${_booking!.bookedPricePerNight}'),
                            const SizedBox(height: 12),
                            Text(
                              'Status: ${_bookingStatusLabel(_booking!.status)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
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
                                    icon:
                                        const Icon(Icons.meeting_room_outlined),
                                    label: const Text('Assign Room'),
                                    onPressed: () async {
                                      if (bookingId == null) return;
                                      final res = await Navigator.pushNamed(
                                        context,
                                        AppRoutes.assignRoom,
                                        arguments: bookingId,
                                      );
                                      if (res == true && mounted) {
                                        _hasUpdates = true;
                                        _refresh();
                                      }
                                    },
                                  ),
                                ),
                              if (_booking!.roomId == null)
                                const SizedBox(height: 12),
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
                                      _hasUpdates = true;
                                      _refresh();
                                    }
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      )),
      ),
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
  bool _roomTypesLoading = true;
  String? _roomTypesError;

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
    setState(() {
      _roomTypesLoading = true;
      _roomTypesError = null;
    });
    try {
      final roomTypes = await _roomTypeRepo.getAllRoomTypes();
      if (!mounted) return;
      setState(() {
        _roomTypes = roomTypes;
        _selectedRoomTypeId = roomTypes.isNotEmpty ? roomTypes.first.id : null;
        _roomTypesLoading = false;
        _roomTypesError = roomTypes.isEmpty
            ? 'No room types available yet. Please create one first.'
            : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _roomTypes = const [];
        _selectedRoomTypeId = null;
        _roomTypesLoading = false;
        _roomTypesError =
            'Failed to load room types. Pull to refresh and try again.';
      });
    }
  }

  Future<void> _pickDate({required bool isCheckIn}) async {
    final initial =
        (isCheckIn ? _checkInDate : _checkOutDate) ?? DateTime.now();
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

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    return DateFormatter.formatDate(value.millisecondsSinceEpoch);
  }

  String? _phoneValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Guest phone is required.';
    }
    final digits = trimmed.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.length < 8) {
      return 'Enter a valid phone number.';
    }
    return null;
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
      setState(() =>
          _submitError = 'Please select both check-in and check-out dates.');
      return;
    }
    if (!checkOut.isAfter(checkIn)) {
      setState(
          () => _submitError = 'Check-out date must be after check-in date.');
      return;
    }
    if (_selectedRoomTypeId == null) {
      setState(() => _submitError = 'Please select a room type.');
      return;
    }

    final session = context.read<SessionProvider>();
    final currentUserId = session.userId;
    if (currentUserId == null) {
      setState(
          () => _submitError = 'You must be logged in to create a booking.');
      return;
    }

    final roomType =
        _roomTypes.firstWhere((rt) => rt.id == _selectedRoomTypeId);

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
      Navigator.pop(context, bookingId);
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
      appBar: AppBar(
        title: const Text('New Booking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload room types',
            onPressed: _roomTypesLoading ? null : _loadRoomTypes,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRoomTypes,
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _guestNameController,
                      textInputAction: TextInputAction.next,
                      decoration:
                          const InputDecoration(labelText: 'Guest name'),
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
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      decoration:
                          const InputDecoration(labelText: 'Guest phone'),
                      validator: _phoneValidator,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      // ignore: deprecated_member_use
                      value: _selectedRoomTypeId,
                      decoration: InputDecoration(
                        labelText: _roomTypesLoading
                            ? 'Loading room types...'
                            : 'Room type',
                      ),
                      items: _roomTypes
                          .map(
                            (rt) => DropdownMenuItem<int>(
                              value: rt.id!,
                              child: Text(
                                  '${rt.name} (${rt.pricePerNight}/night)'),
                            ),
                          )
                          .toList(),
                      onChanged: (_roomTypesLoading || _roomTypes.isEmpty)
                          ? null
                          : (value) =>
                              setState(() => _selectedRoomTypeId = value),
                      validator: (_) {
                        if (_roomTypesLoading) {
                          return 'Room type list is still loading.';
                        }
                        if (_roomTypes.isEmpty || _selectedRoomTypeId == null) {
                          return 'Room type is required.';
                        }
                        return null;
                      },
                    ),
                    if (_roomTypesError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _roomTypesError!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickDate(isCheckIn: true),
                            icon: const Icon(Icons.calendar_today),
                            label:
                                Text('Check-in: ${_formatDate(_checkInDate)}'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickDate(isCheckIn: false),
                            icon: const Icon(Icons.calendar_month),
                            label: Text(
                                'Check-out: ${_formatDate(_checkOutDate)}'),
                          ),
                        ),
                      ],
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
            ),
          ],
        ),
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

  Future<void> _load({bool showLoader = true}) async {
    final bookingId = _bookingId;
    if (bookingId == null) {
      setState(() {
        if (showLoader) {
          _isLoading = false;
        }
        _errorMessage = 'Missing bookingId in route arguments.';
      });
      return;
    }

    if (showLoader) {
      setState(() => _isLoading = true);
    }
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

      if (booking.status != BookingStatus.booked) {
        setState(() {
          _booking = booking;
          _availableRooms = const [];
          _errorMessage =
              'Only bookings in BOOKED status can receive room assignments.';
          _isLoading = false;
        });
        return;
      }

      final rawAvailable = await _roomRepo.getAvailableRoomsForDateRange(
        roomTypeId: booking.roomTypeId,
        checkInMs: booking.checkInDate,
        checkOutMs: booking.checkOutDate,
      );

      final rooms = rawAvailable.isEmpty
          ? (await _roomRepo.getAllRooms())
              .where((r) =>
                  r.roomTypeId == booking.roomTypeId &&
                  r.status == RoomStatus.available)
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
          const SnackBar(
              content:
                  Text('Room assignment failed. Booking may not be BOOKED.')),
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
                        if (_booking!.roomId != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'A room is already assigned (ID ${_booking!.roomId}). Assigning a new room will replace it.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                            ),
                          ),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () => _load(showLoader: false),
                            child: _availableRooms.isEmpty
                                ? ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: const [
                                      Padding(
                                        padding: EdgeInsets.all(32),
                                        child: Center(
                                          child: Text(
                                              'No rooms available to assign.'),
                                        ),
                                      ),
                                    ],
                                  )
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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

    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) return;

    final reason = _reasonController.text.trim();

    setState(() => _isCanceling = true);
    try {
      final updated = await _bookingRepo.cancelBooking(bookingId, reason);
      if (!mounted) return;
      if (updated > 0) {
        Navigator.pop(context, true);
      } else {
        setState(() =>
            _errorMessage = 'Cancellation failed. Booking may not be BOOKED.');
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
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _reasonController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Cancel reason',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) {
                  return 'Cancellation reason is required.';
                }
                if (trimmed.length < 5) {
                  return 'Please provide a bit more detail.';
                }
                return null;
              },
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }
}
