import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/housekeeping_task_model.dart';
import '../../../data/repositories/housekeeping_task_repository.dart';
import '../../auth/session_provider.dart';

class HousekeepingTaskDetailScreen extends StatefulWidget {
  final int taskId;

  const HousekeepingTaskDetailScreen({super.key, required this.taskId});

  @override
  State<HousekeepingTaskDetailScreen> createState() =>
      _HousekeepingTaskDetailScreenState();
}

class _HousekeepingTaskDetailScreenState
    extends State<HousekeepingTaskDetailScreen> {
  final HousekeepingTaskRepository _taskRepository =
      HousekeepingTaskRepository();

  bool _loading = true;
  String? _error;
  HousekeepingTaskDetail? _detail;
  bool _actionInFlight = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await _taskRepository.getTaskDetail(widget.taskId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load task: $e';
        _loading = false;
      });
    }
  }

  Future<void> _claimTask(SessionProvider session) async {
    final userId = session.userId;
    if (userId == null) return;
    final displayName = session.fullName ?? session.username ?? 'Housekeeper';
    setState(() => _actionInFlight = true);
    try {
      final success = await _taskRepository.claimTask(
        taskId: widget.taskId,
        userId: userId,
        displayName: displayName,
      );
      if (!mounted) return;
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This task was already claimed.')),
        );
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Claim failed: $e')));
    } finally {
      if (mounted) setState(() => _actionInFlight = false);
    }
  }

  Future<void> _toggleProgress({
    bool? sheets,
    bool? bathroom,
    bool? mop,
  }) async {
    final detail = _detail;
    if (detail == null) return;
    try {
      await _taskRepository.updateTaskProgress(
        taskId: detail.task.id!,
        doneChangeSheets: sheets,
        doneCleanBathroom: bathroom,
        doneMopFloor: mop,
      );
      if (!mounted) return;
      final updatedTask = detail.task.copyWith(
        doneChangeSheets: sheets ?? detail.task.doneChangeSheets,
        doneCleanBathroom: bathroom ?? detail.task.doneCleanBathroom,
        doneMopFloor: mop ?? detail.task.doneMopFloor,
      );
      setState(() {
        _detail = HousekeepingTaskDetail(
          task: updatedTask,
          room: detail.room,
          roomTypeName: detail.roomTypeName,
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  Future<void> _completeTask() async {
    setState(() => _actionInFlight = true);
    try {
      await _taskRepository.completeTask(widget.taskId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room marked as AVAILABLE.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final message = e is StateError ? e.message : e.toString();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _actionInFlight = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cleaning Task')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cleaning Task')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final detail = _detail;
    if (detail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cleaning Task')),
        body: const Center(child: Text('Task not found.')),
      );
    }

    final task = detail.task;
    final isDone = task.status == HousekeepingTaskStatus.done;
    final assignedUserId = task.assignedHousekeeperId;
    final assignedName = task.assignedHousekeeperName;
    final currentUserId = session.userId;
    final isAssignedToCurrent =
        assignedUserId != null && assignedUserId == currentUserId;
    final canClaim = !isDone && assignedUserId == null;
    final canEditChecklist = !isDone && isAssignedToCurrent;
    final hasAllRequired = task.doneChangeSheets &&
        task.doneCleanBathroom &&
        (!task.needMopFloor || task.doneMopFloor);
    final canComplete = canEditChecklist && hasAllRequired && !_actionInFlight;

    return Scaffold(
      appBar: AppBar(
        title: Text('Room ${detail.room.roomNumber}'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                title: Text(detail.roomTypeName ??
                    'Room type ID: '
                        '${detail.room.roomTypeId}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Source: ${_sourceLabel(task.sourceType)}'),
                    Text('Status: ${_statusLabel(task.status)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (detail.requiresMop)
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: const ListTile(
                  leading: Icon(Icons.cleaning_services),
                  title: Text('Floor mopping required this turn'),
                ),
              )
            else
              const Card(
                child: ListTile(
                  leading: Icon(Icons.cleaning_services_outlined),
                  title: Text('No floor mopping required this turn'),
                ),
              ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assignment',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      assignedName == null
                          ? 'Not claimed yet'
                          : 'Currently being cleaned by $assignedName',
                    ),
                    if (canClaim) ...[
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed:
                            _actionInFlight ? null : () => _claimTask(session),
                        child: const Text('Claim this room'),
                      ),
                    ],
                    if (!canClaim &&
                        !isAssignedToCurrent &&
                        assignedName != null)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'You cannot edit this task while another cleaner is working.',
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Checklist',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  CheckboxListTile(
                    value: task.doneChangeSheets,
                    onChanged: canEditChecklist
                        ? (value) => _toggleProgress(sheets: value ?? false)
                        : null,
                    title: const Text('Change bed sheets'),
                  ),
                  CheckboxListTile(
                    value: task.doneCleanBathroom,
                    onChanged: canEditChecklist
                        ? (value) => _toggleProgress(bathroom: value ?? false)
                        : null,
                    title: const Text('Clean bathroom'),
                  ),
                  CheckboxListTile(
                    value: task.needMopFloor ? task.doneMopFloor : false,
                    onChanged: canEditChecklist && task.needMopFloor
                        ? (value) => _toggleProgress(mop: value ?? false)
                        : null,
                    title: const Text('Mop floor'),
                    subtitle: task.needMopFloor
                        ? null
                        : const Text('Not required this turn'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: canComplete ? _completeTask : null,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Complete cleaning'),
            ),
            if (canEditChecklist && !hasAllRequired)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Check all required items before completing.'),
              ),
          ],
        ),
      ),
    );
  }

  String _sourceLabel(HousekeepingTaskSource source) {
    switch (source) {
      case HousekeepingTaskSource.checkout:
        return 'Checkout';
      case HousekeepingTaskSource.manualDirty:
        return 'Manual dirty';
    }
  }

  String _statusLabel(HousekeepingTaskStatus status) {
    switch (status) {
      case HousekeepingTaskStatus.pending:
        return 'Pending';
      case HousekeepingTaskStatus.inProgress:
        return 'In progress';
      case HousekeepingTaskStatus.done:
        return 'Done';
    }
  }
}
