import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/constants/app_routes.dart';
import '../../auth/session_provider.dart';
import '../../../data/models/room_model.dart';
import '../../../data/models/room_type_model.dart';
import '../../../data/repositories/room_repository.dart';
import '../../../data/repositories/room_type_repository.dart';

class RoomStatusBadge extends StatelessWidget {
  final RoomStatus status;

  const RoomStatusBadge({super.key, required this.status});

  Color _badgeColor() {
    switch (status) {
      case RoomStatus.available:
        return Colors.green;
      case RoomStatus.occupied:
        return Colors.orange;
      case RoomStatus.dirty:
        return Colors.red;
      case RoomStatus.outOfService:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _badgeColor();
    final label = status.toDbString().replaceAll('_', ' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 31),
        border: Border.all(color: c),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: c,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

bool _isAdmin(StaffRole? role) => role == StaffRole.admin;
bool _isHousekeeping(StaffRole? role) => role == StaffRole.housekeeping;

class RoomTypeListScreen extends StatefulWidget {
  const RoomTypeListScreen({super.key});

  @override
  State<RoomTypeListScreen> createState() => _RoomTypeListScreenState();
}

class _RoomTypeListScreenState extends State<RoomTypeListScreen> {
  final RoomTypeRepository _roomTypeRepository = RoomTypeRepository();

  late Future<List<RoomTypeModel>> _roomTypesFuture;

  @override
  void initState() {
    super.initState();
    _roomTypesFuture = _roomTypeRepository.getAllRoomTypes();
  }

  void _refresh() {
    setState(() {
      _roomTypesFuture = _roomTypeRepository.getAllRoomTypes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<SessionProvider>().role;

    if (_isHousekeeping(role)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Room Types')),
        body: const Center(child: Text('Access denied')),
      );
    }

    final canEdit = _isAdmin(role);

    return Scaffold(
      appBar: AppBar(title: const Text('Room Types')),
      floatingActionButton: canEdit
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.pushNamed(context, AppRoutes.roomTypeForm);
                _refresh();
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: FutureBuilder<List<RoomTypeModel>>(
        future: _roomTypesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load room types: ${snapshot.error}'));
          }
          final roomTypes = snapshot.data ?? [];

          if (roomTypes.isEmpty) {
            return const Center(child: Text('No room types found'));
          }

          return ListView.builder(
            itemCount: roomTypes.length,
            itemBuilder: (context, i) {
              final type = roomTypes[i];
              final priceText = type.pricePerNight.toStringAsFixed(2);
              return ListTile(
                title: Text(type.name),
                subtitle: Text('Price/night: $priceText${type.description != null && type.description!.isNotEmpty ? '\n${type.description}' : ''}'),
                trailing: canEdit ? const Icon(Icons.chevron_right) : null,
                enabled: canEdit,
                onTap: canEdit
                    ? () async {
                        await Navigator.pushNamed(
                          context,
                          AppRoutes.roomTypeForm,
                          arguments: {'roomTypeId': type.id},
                        );
                        _refresh();
                      }
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}

class RoomTypeFormScreen extends StatefulWidget {
  const RoomTypeFormScreen({super.key});

  @override
  State<RoomTypeFormScreen> createState() => _RoomTypeFormScreenState();
}

class _RoomTypeFormScreenState extends State<RoomTypeFormScreen> {
  final RoomTypeRepository _roomTypeRepository = RoomTypeRepository();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  bool _loading = true;
  bool _didInitArgs = false;
  int? _roomTypeId;
  bool get _isEdit => _roomTypeId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitArgs) return;
    _didInitArgs = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int) {
      _roomTypeId = args;
    } else if (args is Map) {
      final v = args['roomTypeId'];
      if (v is int) _roomTypeId = v;
    }

    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    if (_isEdit) {
      final existing = await _roomTypeRepository.getRoomTypeById(_roomTypeId!);
      if (existing != null) {
        _nameController.text = existing.name;
        _priceController.text = existing.pricePerNight.toString();
        _descController.text = existing.description ?? '';
      }
    }

    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final role = context.read<SessionProvider>().role;
    if (!_isAdmin(role)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Access denied')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    final description = _descController.text.trim();

    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Price must be > 0')),
      );
      return;
    }

    try {
      if (_isEdit) {
        await _roomTypeRepository.updateRoomType(
          RoomTypeModel(
            id: _roomTypeId,
            name: name,
            pricePerNight: price,
            description: description.isEmpty ? null : description,
          ),
        );
      } else {
        await _roomTypeRepository.createRoomType(
          RoomTypeModel(
            name: name,
            pricePerNight: price,
            description: description.isEmpty ? null : description,
          ),
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  Future<void> _delete() async {
    final role = context.read<SessionProvider>().role;
    if (!_isAdmin(role)) return;
    if (!_isEdit) return;

    final hasLinkedRooms =
        await _roomTypeRepository.hasLinkedRooms(_roomTypeId!);
    if (!mounted) return;
    if (hasLinkedRooms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete: room type is linked to rooms')),
      );
      return;
    }

    try {
      await _roomTypeRepository.deleteRoomType(_roomTypeId!);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<SessionProvider>().role;
    final canEdit = _isAdmin(role);

    if (_isHousekeeping(role) || role == null || !canEdit) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? 'Edit Room Type' : 'Create Room Type'),
        ),
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
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Room Type' : 'Create Room Type'),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: 'Delete room type',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete room type?'),
                    content: const Text('This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await _delete();
                }
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Room type name',
                        hintText: 'e.g., Deluxe',
                      ),
                      validator: (v) {
                        final text = (v ?? '').trim();
                        if (text.isEmpty) return 'Name is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price per night',
                        hintText: 'e.g., 120000',
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final text = (v ?? '').trim();
                        final price = double.tryParse(text);
                        if (price == null) return 'Price must be a number';
                        if (price <= 0) return 'Price must be > 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _save,
                      child: Text(_isEdit ? 'Save changes' : 'Create room type'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class RoomListScreen extends StatefulWidget {
  const RoomListScreen({super.key});

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  final RoomRepository _roomRepository = RoomRepository();
  final RoomTypeRepository _roomTypeRepository = RoomTypeRepository();

  bool _loading = true;
  List<RoomModel> _rooms = [];
  List<RoomTypeModel> _roomTypes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rooms = await _roomRepository.getAllRooms();
    final types = await _roomTypeRepository.getAllRoomTypes();
    setState(() {
      _rooms = rooms;
      _roomTypes = types;
      _loading = false;
    });
  }

  Future<void> _refresh() => _load();

  @override
  Widget build(BuildContext context) {
    final role = context.watch<SessionProvider>().role;
    if (_isHousekeeping(role)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rooms')),
        body: const Center(child: Text('Access denied')),
      );
    }

    final canEdit = _isAdmin(role);

    final typeById = <int, RoomTypeModel>{};
    for (final t in _roomTypes) {
      if (t.id != null) typeById[t.id!] = t;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Rooms')),
      floatingActionButton: canEdit
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.pushNamed(context, AppRoutes.roomForm);
                await _refresh();
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rooms.isEmpty
              ? const Center(child: Text('No rooms found'))
              : ListView.builder(
                  itemCount: _rooms.length,
                  itemBuilder: (context, i) {
                    final room = _rooms[i];
                    final roomTypeName = typeById[room.roomTypeId]?.name;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        title: Text('Room ${room.roomNumber}'),
                        subtitle: Text(
                          roomTypeName != null
                              ? 'Type: $roomTypeName'
                              : 'Room type ID: ${room.roomTypeId}',
                        ),
                        trailing: RoomStatusBadge(status: room.status),
                        enabled: canEdit,
                        onTap: canEdit
                            ? () async {
                                await Navigator.pushNamed(
                                  context,
                                  AppRoutes.roomForm,
                                  arguments: {'roomId': room.id},
                                );
                                await _refresh();
                              }
                            : null,
                      ),
                    );
                  },
                ),
    );
  }
}

class RoomFormScreen extends StatefulWidget {
  const RoomFormScreen({super.key});

  @override
  State<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends State<RoomFormScreen> {
  final RoomRepository _roomRepository = RoomRepository();
  final RoomTypeRepository _roomTypeRepository = RoomTypeRepository();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _roomNumberController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _loading = true;
  bool _didInitArgs = false;

  int? _roomId;
  bool get _isEdit => _roomId != null;

  List<RoomTypeModel> _roomTypes = [];
  int? _selectedRoomTypeId;
  RoomModel? _existingRoom;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitArgs) return;
    _didInitArgs = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int) {
      _roomId = args;
    } else if (args is Map) {
      final v = args['roomId'];
      if (v is int) _roomId = v;
    }

    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final types = await _roomTypeRepository.getAllRoomTypes();
    final existing = _isEdit ? await _roomRepository.getRoomById(_roomId!) : null;

    final selectedTypeId = existing?.roomTypeId ?? (types.isNotEmpty ? types.first.id : null);

    setState(() {
      _roomTypes = types;
      _existingRoom = existing;
      _selectedRoomTypeId = selectedTypeId;
      _roomNumberController.text = existing?.roomNumber ?? '';
      _notesController.text = existing?.notes ?? '';
      _loading = false;
    });
  }

  @override
  void dispose() {
    _roomNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final role = context.read<SessionProvider>().role;
    if (!_isAdmin(role)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Access denied')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final roomNumber = _roomNumberController.text.trim();
    final notes = _notesController.text.trim();
    final roomTypeId = _selectedRoomTypeId;
    if (roomTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a room type')),
      );
      return;
    }

    try {
      final status = _existingRoom?.status ?? RoomStatus.available;
      final model = RoomModel(
        id: _roomId,
        roomNumber: roomNumber,
        roomTypeId: roomTypeId,
        status: status,
        notes: notes.isEmpty ? null : notes,
      );

      if (_isEdit) {
        await _roomRepository.updateRoom(model);
      } else {
        await _roomRepository.createRoom(model);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<SessionProvider>().role;
    final canEdit = _isAdmin(role);

    if (_isHousekeeping(role) || role == null || !canEdit) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? 'Edit Room' : 'Create Room'),
        ),
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
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Room' : 'Create Room'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _roomTypes.isEmpty
              ? const Center(
                  child: Text('Please create at least one room type first.'),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        TextFormField(
                          controller: _roomNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Room number',
                            hintText: 'e.g., 101',
                          ),
                          validator: (v) {
                            final text = (v ?? '').trim();
                            if (text.isEmpty) return 'Room number is required';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: _selectedRoomTypeId,
                          decoration: const InputDecoration(
                            labelText: 'Room type',
                          ),
                          items: _roomTypes
                              .where((t) => t.id != null)
                              .map(
                                (t) => DropdownMenuItem<int>(
                                  value: t.id!,
                                  child: Text(t.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            setState(() => _selectedRoomTypeId = v);
                          },
                          validator: (v) {
                            if (v == null) return 'Room type is required';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Notes (optional)',
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _save,
                          child: Text(_isEdit ? 'Save changes' : 'Create room'),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
