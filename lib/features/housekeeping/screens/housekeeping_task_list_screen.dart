import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/constants/app_routes.dart';
import '../../auth/session_provider.dart';
import '../../../data/models/housekeeping_task_model.dart';
import '../../../data/repositories/housekeeping_task_repository.dart';
import 'housekeeping_task_detail_screen.dart';

class HousekeepingTaskListScreen extends StatefulWidget {
  const HousekeepingTaskListScreen({super.key});

  @override
  State<HousekeepingTaskListScreen> createState() =>
      _HousekeepingTaskListScreenState();
}

class _HousekeepingTaskListScreenState
    extends State<HousekeepingTaskListScreen> {
  final HousekeepingTaskRepository _taskRepository =
      HousekeepingTaskRepository();

  bool _loading = true;
  bool _initialLoadDone = false;
  List<HousekeepingTaskListItem> _tasks = [];
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
      final tasks = await _taskRepository.getOpenTasks();
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load cleaning tasks: $e';
        _tasks = [];
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

  Future<void> _openTaskDetail(HousekeepingTaskListItem item) async {
    final taskId = item.task.id;
    if (taskId == null) return;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => HousekeepingTaskDetailScreen(taskId: taskId),
      ),
    );
    if (changed == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<SessionProvider>().role;

    if (role != StaffRole.housekeeping) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cleaning Tasks')),
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
        title: const Text('Cleaning Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: _loading && !_initialLoadDone
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: _buildBody(),
            ),
    );
  }

  void _handleLogout(BuildContext context) {
    final session = context.read<SessionProvider>();
    session.logout();
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _load,
            child: const Text('Retry'),
          ),
        ],
      );
    }

    if (_tasks.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
          SizedBox(height: 12),
          Text(
            'No dirty rooms right now',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _tasks.length,
      itemBuilder: (context, i) {
        final item = _tasks[i];
        final task = item.task;
        final assignment = task.assignedHousekeeperName == null
            ? 'Awaiting claim'
            : 'Cleaning by ${task.assignedHousekeeperName}';
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            onTap: () => _openTaskDetail(item),
            title: Text('Room ${item.roomNumber}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.roomTypeName ?? 'Room type ID: ${task.roomId}'),
                const SizedBox(height: 2),
                Text(assignment),
                if (item.requiresMop)
                  const Text(
                    'Floor mopping required',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
              ],
            ),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _statusChip(task.status),
                const SizedBox(height: 6),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusChip(HousekeepingTaskStatus status) {
    Color color;
    String label;
    switch (status) {
      case HousekeepingTaskStatus.pending:
        color = Colors.orange;
        label = 'Pending';
        break;
      case HousekeepingTaskStatus.inProgress:
        color = Colors.blue;
        label = 'In progress';
        break;
      case HousekeepingTaskStatus.done:
        color = Colors.green;
        label = 'Done';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
