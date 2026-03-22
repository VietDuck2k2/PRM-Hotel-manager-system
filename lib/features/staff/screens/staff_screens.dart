import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../auth/session_provider.dart';

class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  final _repo = UserRepository();

  late Future<List<UserModel>> _future;
  bool _showDeactivated = false;

  @override
  void initState() {
    super.initState();
    _future = _loadUsers();
  }

  Future<List<UserModel>> _loadUsers() {
    return _repo.getUsers(includeInactive: _showDeactivated);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadUsers();
    });
    await _future;
  }

  Future<void> _confirmDeactivate(UserModel user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Deactivate staff'),
        content: Text(
          'Deactivate "${user.fullName}"?\nThey will no longer be able to log in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await _repo.deactivateUser(user.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deactivated "${user.fullName}"')),
    );
    await _refresh();
  }

  Future<void> _reactivate(UserModel user) async {
    if (user.id == null) return;
    await _repo.reactivateUser(user.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reactivated "${user.fullName}"')),
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    if (session.role != StaffRole.admin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Staff')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Admin only.\nPlease login as an admin to manage staff accounts.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _showDeactivated = !_showDeactivated;
                _future = _loadUsers();
              });
            },
            icon: Icon(
                _showDeactivated ? Icons.visibility : Icons.visibility_off),
            tooltip: _showDeactivated ? 'Hide deactivated' : 'Show deactivated',
          ),
          IconButton(
            onPressed: () => _refresh(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load staff.\n${snapshot.error}'),
              ),
            );
          }
          final users = snapshot.data ?? const <UserModel>[];
          if (users.isEmpty) {
            return const Center(child: Text('No staff found.'));
          }

          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final u = users[i];
              final subtitle = '${u.username} • ${u.role.name}';
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    (u.fullName.trim().isEmpty ? '?' : u.fullName.trim()[0])
                        .toUpperCase(),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(child: Text(u.fullName)),
                    const SizedBox(width: 8),
                    _RoleBadge(role: u.role),
                  ],
                ),
                subtitle: Text(subtitle),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: u.isActive ? 'Deactivate' : 'Reactivate',
                      onPressed: u.id == null
                          ? null
                          : () => u.isActive
                              ? _confirmDeactivate(u)
                              : _reactivate(u),
                      icon: Icon(
                        u.isActive ? Icons.person_off : Icons.restart_alt,
                        color: u.isActive ? null : Colors.green,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: u.id == null
                          ? null
                          : () async {
                              await Navigator.pushNamed(
                                context,
                                AppRoutes.staffForm,
                                arguments: StaffFormArgs(userId: u.id),
                              );
                              await _refresh();
                            },
                      icon: const Icon(Icons.edit),
                    ),
                  ],
                ),
                onTap: u.id == null
                    ? null
                    : () async {
                        await Navigator.pushNamed(
                          context,
                          AppRoutes.staffForm,
                          arguments: StaffFormArgs(userId: u.id),
                        );
                        await _refresh();
                      },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(
            context,
            AppRoutes.staffForm,
            arguments: const StaffFormArgs(),
          );
          await _refresh();
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final StaffRole role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (role) {
      StaffRole.admin => ('Admin', Colors.deepPurple),
      StaffRole.receptionist => ('Receptionist', Colors.teal),
      StaffRole.housekeeping => ('Housekeeping', Colors.orange),
    };
    return Chip(
      label: Text(label),
      labelStyle: const TextStyle(color: Colors.white),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

@immutable
class StaffFormArgs {
  final int? userId;
  const StaffFormArgs({this.userId});
}

class StaffFormScreen extends StatefulWidget {
  const StaffFormScreen({super.key});

  @override
  State<StaffFormScreen> createState() => _StaffFormScreenState();
}

class _StaffFormScreenState extends State<StaffFormScreen> {
  final _repo = UserRepository();

  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  StaffRole _role = StaffRole.receptionist;
  bool _isActive = true;
  bool _saving = false;

  int? _editingUserId;
  UserModel? _loadedUser;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    final userId = (args is StaffFormArgs) ? args.userId : null;
    if (_editingUserId == userId) return;

    _editingUserId = userId;
    if (userId == null) {
      _loadedUser = null;
      _fullNameCtrl.text = '';
      _usernameCtrl.text = '';
      _passwordCtrl.text = '';
      _role = StaffRole.receptionist;
      _isActive = true;
      return;
    }

    _repo.getUserById(userId).then((user) {
      if (!mounted) return;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff not found.')),
        );
        Navigator.pop(context);
        return;
      }
      setState(() {
        _loadedUser = user;
        _fullNameCtrl.text = user.fullName;
        _usernameCtrl.text = user.username;
        _passwordCtrl.text = '';
        _role = user.role;
        _isActive = user.isActive;
      });
    });
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String? _required(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _saving = true);
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final isEdit = _editingUserId != null;
      final username = _usernameCtrl.text.trim();

      if (!isEdit) {
        final exists = await _repo.usernameExists(username);
        if (exists) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Username already exists.')),
            );
            setState(() => _saving = false);
          }
          return;
        }
      }

      if (!isEdit) {
        final user = UserModel(
          username: username,
          passwordHash: UserModel.hashPassword(_passwordCtrl.text),
          fullName: _fullNameCtrl.text.trim(),
          role: _role,
          isActive: _isActive,
          createdAt: now,
        );
        await _repo.createUser(user);
      } else {
        final existing = _loadedUser;
        if (existing == null) throw StateError('Missing loaded user');

        final password = _passwordCtrl.text;
        final passwordHash = password.trim().isEmpty
            ? existing.passwordHash
            : UserModel.hashPassword(password);

        final updated = existing.copyWith(
          fullName: _fullNameCtrl.text.trim(),
          role: _role,
          isActive: _isActive,
          passwordHash: passwordHash,
          username: existing.username,
        );
        await _repo.updateUser(updated);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed.\n$e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    if (session.role != StaffRole.admin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Staff Member')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Admin only.\nPlease login as an admin to manage staff accounts.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final isEdit = _editingUserId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Staff' : 'Create Staff'),
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _fullNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => _required(v, 'Full name'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameCtrl,
                enabled: !isEdit,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: const OutlineInputBorder(),
                  helperText: isEdit
                      ? 'Username cannot be changed.'
                      : 'Must be unique.',
                ),
                validator: (v) => _required(v, 'Username'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: isEdit ? 'New password (optional)' : 'Password',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (!isEdit) return _required(v, 'Password');
                  return null;
                },
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<StaffRole>(
                key: ValueKey(_role),
                initialValue: _role,
                items: StaffRole.values
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(r.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _role = v ?? _role),
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                title: const Text('Active'),
                subtitle: const Text('Inactive staff cannot log in.'),
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
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Saving...' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
