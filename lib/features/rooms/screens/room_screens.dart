import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/constants/app_routes.dart';
import '../../auth/session_provider.dart';
import '../../../data/models/room_model.dart';
import '../../../data/models/room_type_model.dart';
import '../../../data/repositories/room_repository.dart';
import '../../../data/repositories/room_type_repository.dart';
import '../../../data/repositories/housekeeping_task_repository.dart';
import '../../../data/models/housekeeping_task_model.dart';

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

  String _label() {
    switch (status) {
      case RoomStatus.available:
        return 'Available';
      case RoomStatus.occupied:
        return 'Occupied';
      case RoomStatus.dirty:
        return 'Dirty';
      case RoomStatus.outOfService:
        return 'Out of service';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _badgeColor();
    final label = _label();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
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

enum RoomListFilter { all, available, occupied, dirty, outOfService }

RoomStatus? _statusForFilter(RoomListFilter filter) {
  switch (filter) {
    case RoomListFilter.all:
      return null;
    case RoomListFilter.available:
      return RoomStatus.available;
    case RoomListFilter.occupied:
      return RoomStatus.occupied;
    case RoomListFilter.dirty:
      return RoomStatus.dirty;
    case RoomListFilter.outOfService:
      return RoomStatus.outOfService;
  }
}

String _filterLabel(RoomListFilter filter) {
  switch (filter) {
    case RoomListFilter.all:
      return 'All';
    case RoomListFilter.available:
      return 'Available';
    case RoomListFilter.occupied:
      return 'Occupied';
    case RoomListFilter.dirty:
      return 'Dirty';
    case RoomListFilter.outOfService:
      return 'Out of service';
  }
}

Map<RoomStatus, int> _initialStatusCounts() {
  return {
    for (final status in RoomStatus.values) status: 0,
  };
}

class RoomTypeListScreen extends StatefulWidget {
  const RoomTypeListScreen({super.key});

  @override
  State<RoomTypeListScreen> createState() => _RoomTypeListScreenState();
}

class _RoomTypeListScreenState extends State<RoomTypeListScreen> {
  final RoomTypeRepository _roomTypeRepository = RoomTypeRepository();

  bool _loading = false;
  bool _initialLoadDone = false;
  List<RoomTypeModel> _roomTypes = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_initialLoadDone && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final list = await _roomTypeRepository.getAllRoomTypes();
      if (!mounted) return;
      setState(() {
        _roomTypes = list;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load room types: $e';
        _roomTypes = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _initialLoadDone = true;
        });
      }
    }
  }

  Future<void> _refresh() => _load();

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
                await _refresh();
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: _loading && !_initialLoadDone
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: _buildRoomTypeBody(canEdit),
            ),
    );
  }

  Widget _buildRoomTypeBody(bool canEdit) {
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(_error!, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          FilledButton(onPressed: _load, child: const Text('Retry')),
        ],
      );
    }

    if (_roomTypes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          Icon(Icons.meeting_room, size: 56, color: Colors.grey),
          SizedBox(height: 12),
          Text('No room types found'),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _roomTypes.length,
      itemBuilder: (context, i) {
        final type = _roomTypes[i];
        final priceText = type.pricePerNight.toStringAsFixed(2);
        final description = type.description;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            title: Text(type.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Price/night: $priceText'),
                if (description != null && description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
            trailing: canEdit ? const Icon(Icons.chevron_right) : null,
            enabled: canEdit,
            onTap: canEdit
                ? () async {
                    await Navigator.pushNamed(
                      context,
                      AppRoutes.roomTypeForm,
                      arguments: {'roomTypeId': type.id},
                    );
                    await _refresh();
                  }
                : null,
          ),
        );
      },
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
        const SnackBar(
            content: Text('Cannot delete: room type is linked to rooms')),
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
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
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
                      child:
                          Text(_isEdit ? 'Save changes' : 'Create room type'),
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
  final HousekeepingTaskRepository _housekeepingTaskRepository =
      HousekeepingTaskRepository();

  bool _loading = false;
  bool _initialLoadDone = false;
  String? _error;
  RoomListFilter _filter = RoomListFilter.all;
  List<RoomModel> _rooms = [];
  List<RoomTypeModel> _roomTypes = [];
  Map<RoomStatus, int> _statusCounts = _initialStatusCounts();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_initialLoadDone && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final rooms = await _roomRepository.getAllRooms();
      final types = await _roomTypeRepository.getAllRoomTypes();
      final counts = await _roomRepository.getRoomStatusCounts();
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _roomTypes = types;
        _statusCounts = counts;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load rooms: $e';
        _rooms = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _initialLoadDone = true;
        });
      }
    }
  }

  Future<void> _refresh() => _load();

  Map<int, RoomTypeModel> get _roomTypeById {
    final map = <int, RoomTypeModel>{};
    for (final type in _roomTypes) {
      final id = type.id;
      if (id != null) {
        map[id] = type;
      }
    }
    return map;
  }

  List<RoomModel> get _filteredRooms {
    final status = _statusForFilter(_filter);
    if (status == null) return _rooms;
    return _rooms.where((room) => room.status == status).toList();
  }

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

    return Scaffold(
      appBar: AppBar(title: const Text('Rooms')),
      floatingActionButton: canEdit
          ? FloatingActionButton(
              onPressed: () async {
                await _openForm();
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: _buildBody(canEdit),
    );
  }

  Widget _buildBody(bool canEdit) {
    if (_loading && !_initialLoadDone) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: _error != null ? _buildErrorState() : _buildRoomList(canEdit),
    );
  }

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        Text(_error!, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 12),
        FilledButton(onPressed: _load, child: const Text('Retry')),
      ],
    );
  }

  Widget _buildRoomList(bool canEdit) {
    final rooms = _filteredRooms;
    final children = <Widget>[
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _RoomStatusSummary(counts: _statusCounts),
      ),
      const SizedBox(height: 8),
      _RoomFilterChips(
        selected: _filter,
        onSelected: (filter) => setState(() => _filter = filter),
      ),
      const SizedBox(height: 8),
    ];

    if (rooms.isEmpty) {
      children.add(const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 48),
        child: Center(
          child: Text('No rooms match this filter yet.'),
        ),
      ));
    } else {
      final typeById = _roomTypeById;
      children.addAll(
        rooms.map(
          (room) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              title: Text('Room ${room.roomNumber}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    typeById[room.roomTypeId]?.name != null
                        ? 'Type: ${typeById[room.roomTypeId]!.name}'
                        : 'Room type ID: ${room.roomTypeId}',
                  ),
                  if (room.notes != null && room.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        room.notes!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RoomStatusBadge(status: room.status),
                  IconButton(
                    tooltip: 'View details',
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => _showRoomDetails(room),
                  ),
                ],
              ),
              onTap: canEdit ? () => _openForm(roomId: room.id) : null,
            ),
          ),
        ),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: children,
    );
  }

  Future<void> _openForm({int? roomId}) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.roomForm,
      arguments: roomId == null ? null : {'roomId': roomId},
    );
    await _refresh();
  }

  Future<void> _showRoomDetails(RoomModel room) async {
    final type = _roomTypeById[room.roomTypeId];
    final role = context.read<SessionProvider>().role;
    final canEdit = _isAdmin(role);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => _RoomDetailSheet(
        room: room,
        roomType: type,
        canEdit: canEdit,
        onEdit: room.id == null ? null : () => _openForm(roomId: room.id),
        onChangeStatus: room.id == null || !canEdit
            ? null
            : (status) => _changeStatus(room, status),
      ),
    );
  }

  Future<void> _changeStatus(RoomModel room, RoomStatus newStatus) async {
    if (room.id == null) return;
    if (room.status == newStatus) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room is already in this status')),
      );
      return;
    }

    try {
      await _roomRepository.updateStatus(room.id!, newStatus);
      if (newStatus == RoomStatus.dirty) {
        await _housekeepingTaskRepository.ensureTaskForDirtyRoom(
          roomId: room.id!,
          source: HousekeepingTaskSource.manualDirty,
          checkoutSinceLastFloorClean: room.checkoutSinceLastFloorClean,
        );
      }
      if (!mounted) return;
      final label = newStatus.toDbString().replaceAll('_', ' ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room ${room.roomNumber} marked $label')),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }
}

class RoomFormScreen extends StatefulWidget {
  const RoomFormScreen({super.key});

  @override
  State<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFilterChips extends StatelessWidget {
  final RoomListFilter selected;
  final ValueChanged<RoomListFilter> onSelected;

  const _RoomFilterChips({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: RoomListFilter.values
            .map(
              (filter) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(_filterLabel(filter)),
                  selected: selected == filter,
                  onSelected: (_) => onSelected(filter),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _RoomStatusSummary extends StatelessWidget {
  final Map<RoomStatus, int> counts;

  const _RoomStatusSummary({required this.counts});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _StatusChipData(
          'Available', counts[RoomStatus.available] ?? 0, Colors.green),
      _StatusChipData(
          'Occupied', counts[RoomStatus.occupied] ?? 0, Colors.orange),
      _StatusChipData('Dirty', counts[RoomStatus.dirty] ?? 0, Colors.red),
      _StatusChipData(
          'Out of service', counts[RoomStatus.outOfService] ?? 0, Colors.grey),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tiles
          .map(
            (tile) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: tile.color.withValues(alpha: 31),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${tile.label}: ${tile.count}'),
            ),
          )
          .toList(),
    );
  }
}

class _StatusChipData {
  final String label;
  final int count;
  final Color color;

  const _StatusChipData(this.label, this.count, this.color);
}

class _RoomDetailSheet extends StatelessWidget {
  final RoomModel room;
  final RoomTypeModel? roomType;
  final bool canEdit;
  final Future<void> Function()? onEdit;
  final Future<void> Function(RoomStatus status)? onChangeStatus;

  const _RoomDetailSheet({
    required this.room,
    required this.roomType,
    required this.canEdit,
    this.onEdit,
    this.onChangeStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Room ${room.roomNumber}',
                          style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        roomType?.name ?? 'Room type ID: ${room.roomTypeId}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                RoomStatusBadge(status: room.status),
              ],
            ),
            if (room.notes != null && room.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Notes', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(room.notes!),
            ],
            const SizedBox(height: 16),
            if (canEdit && onEdit != null)
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () => _handleEdit(context),
                  child: const Text('Edit room details'),
                ),
              ),
            if (onChangeStatus != null) ...[
              const SizedBox(height: 12),
              Text('Status actions', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatusButton(
                      context, RoomStatus.available, 'Mark available'),
                  _buildStatusButton(context, RoomStatus.dirty, 'Mark dirty'),
                  _buildStatusButton(
                      context, RoomStatus.outOfService, 'Mark out of service'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(
      BuildContext context, RoomStatus status, String label) {
    return OutlinedButton(
      onPressed: room.status == status
          ? null
          : () => _handleStatusChange(context, status),
      child: Text(label),
    );
  }

  Future<void> _handleEdit(BuildContext context) async {
    if (onEdit == null) return;
    Navigator.pop(context);
    await onEdit!.call();
  }

  Future<void> _handleStatusChange(
      BuildContext context, RoomStatus status) async {
    if (onChangeStatus == null) return;
    Navigator.pop(context);
    await onChangeStatus!.call(status);
  }
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
    final existing =
        _isEdit ? await _roomRepository.getRoomById(_roomId!) : null;

    final selectedTypeId =
        existing?.roomTypeId ?? (types.isNotEmpty ? types.first.id : null);

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
        checkoutSinceLastFloorClean:
            _existingRoom?.checkoutSinceLastFloorClean ?? 0,
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
