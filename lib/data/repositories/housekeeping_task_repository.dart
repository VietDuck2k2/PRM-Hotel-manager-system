import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_enums.dart';
import '../../core/constants/db_schema.dart';
import '../../core/database/database_helper.dart';
import '../models/housekeeping_task_model.dart';
import '../models/room_model.dart';

class HousekeepingTaskListItem {
  final HousekeepingTaskModel task;
  final String roomNumber;
  final String? roomTypeName;

  bool get requiresMop => task.needMopFloor;
  bool get isInProgress =>
      task.status == HousekeepingTaskStatus.inProgress &&
      task.assignedHousekeeperName != null;

  const HousekeepingTaskListItem({
    required this.task,
    required this.roomNumber,
    required this.roomTypeName,
  });
}

class HousekeepingTaskDetail {
  final HousekeepingTaskModel task;
  final RoomModel room;
  final String? roomTypeName;

  const HousekeepingTaskDetail({
    required this.task,
    required this.room,
    required this.roomTypeName,
  });

  bool get requiresMop => task.needMopFloor;
}

class HousekeepingTaskRepository {
  final DatabaseHelper _dbHelper;

  HousekeepingTaskRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<DatabaseExecutor> _resolveExecutor(DatabaseExecutor? executor) async {
    if (executor != null) return executor;
    return _dbHelper.database;
  }

  Future<List<HousekeepingTaskListItem>> getOpenTasks() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT t.*, r.roomNumber AS roomNumber, r.roomTypeId AS roomTypeId,
             rt.name AS roomTypeName
      FROM ${DbSchema.tableHousekeepingTasks} t
      JOIN ${DbSchema.tableRooms} r ON r.id = t.roomId
      LEFT JOIN ${DbSchema.tableRoomTypes} rt ON rt.id = r.roomTypeId
      WHERE t.status IN ('PENDING', 'IN_PROGRESS')
      ORDER BY t.dirtyAt ASC
    ''');

    return rows.map((row) {
      final task = HousekeepingTaskModel.fromMap(row);
      return HousekeepingTaskListItem(
        task: task,
        roomNumber: row['roomNumber'] as String,
        roomTypeName: row['roomTypeName'] as String?,
      );
    }).toList();
  }

  Future<HousekeepingTaskDetail?> getTaskDetail(int taskId) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT t.*, r.roomNumber AS roomNumber, r.roomTypeId AS roomTypeId,
             r.status AS roomStatus, r.notes AS roomNotes,
             r.checkoutSinceLastFloorClean AS roomCheckoutCounter,
             rt.name AS roomTypeName
      FROM ${DbSchema.tableHousekeepingTasks} t
      JOIN ${DbSchema.tableRooms} r ON r.id = t.roomId
      LEFT JOIN ${DbSchema.tableRoomTypes} rt ON rt.id = r.roomTypeId
      WHERE t.id = ?
      LIMIT 1
    ''', [taskId]);

    if (rows.isEmpty) return null;
    final row = rows.first;
    final task = HousekeepingTaskModel.fromMap(row);
    final room = RoomModel(
      id: task.roomId,
      roomNumber: row['roomNumber'] as String,
      roomTypeId: row['roomTypeId'] as int,
      status: RoomStatus.fromString(row['roomStatus'] as String),
      notes: row['roomNotes'] as String?,
      checkoutSinceLastFloorClean: (row['roomCheckoutCounter'] as int?) ?? 0,
    );

    return HousekeepingTaskDetail(
      task: task,
      room: room,
      roomTypeName: row['roomTypeName'] as String?,
    );
  }

  Future<void> ensureTaskForDirtyRoom({
    required int roomId,
    required HousekeepingTaskSource source,
    required int checkoutSinceLastFloorClean,
    bool needChangeSheets = true,
    bool needCleanBathroom = true,
    DatabaseExecutor? executor,
  }) async {
    final db = await _resolveExecutor(executor);
    final open = await db.query(
      DbSchema.tableHousekeepingTasks,
      where: 'roomId = ? AND status != ?',
      whereArgs: [roomId, HousekeepingTaskStatus.done.toDbString()],
      limit: 1,
    );
    if (open.isNotEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final needMop = checkoutSinceLastFloorClean >= 2;
    await db.insert(DbSchema.tableHousekeepingTasks, {
      'roomId': roomId,
      'sourceType': source.toDbString(),
      'status': HousekeepingTaskStatus.pending.toDbString(),
      'dirtyAt': now,
      'needChangeSheets': needChangeSheets ? 1 : 0,
      'needCleanBathroom': needCleanBathroom ? 1 : 0,
      'needMopFloor': needMop ? 1 : 0,
      'doneChangeSheets': 0,
      'doneCleanBathroom': 0,
      'doneMopFloor': 0,
    });
  }

  Future<bool> claimTask({
    required int taskId,
    required int userId,
    required String displayName,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final updated = await db.update(
      DbSchema.tableHousekeepingTasks,
      {
        'status': HousekeepingTaskStatus.inProgress.toDbString(),
        'assignedHousekeeperId': userId,
        'assignedHousekeeperName': displayName,
        'startedAt': now,
      },
      where: 'id = ? AND status = ? AND assignedHousekeeperId IS NULL',
      whereArgs: [taskId, HousekeepingTaskStatus.pending.toDbString()],
    );
    return updated > 0;
  }

  Future<void> updateTaskProgress({
    required int taskId,
    bool? doneChangeSheets,
    bool? doneCleanBathroom,
    bool? doneMopFloor,
  }) async {
    final db = await _dbHelper.database;
    final data = <String, Object?>{};
    if (doneChangeSheets != null) {
      data['doneChangeSheets'] = doneChangeSheets ? 1 : 0;
    }
    if (doneCleanBathroom != null) {
      data['doneCleanBathroom'] = doneCleanBathroom ? 1 : 0;
    }
    if (doneMopFloor != null) {
      data['doneMopFloor'] = doneMopFloor ? 1 : 0;
    }
    if (data.isEmpty) return;
    await db.update(
      DbSchema.tableHousekeepingTasks,
      data,
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> completeTask(int taskId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        DbSchema.tableHousekeepingTasks,
        where: 'id = ?',
        whereArgs: [taskId],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw StateError('Task not found');
      }
      final task = HousekeepingTaskModel.fromMap(rows.first);
      if (task.status == HousekeepingTaskStatus.done) {
        return;
      }
      if (!task.doneChangeSheets || !task.doneCleanBathroom) {
        throw StateError('Complete the required checklist first.');
      }
      if (task.needMopFloor && !task.doneMopFloor) {
        throw StateError('Mop floor is required this turn.');
      }

      final finishTime = DateTime.now().millisecondsSinceEpoch;
      await txn.update(
        DbSchema.tableHousekeepingTasks,
        {
          'status': HousekeepingTaskStatus.done.toDbString(),
          'finishedAt': finishTime,
        },
        where: 'id = ?',
        whereArgs: [taskId],
      );

      final roomUpdate = <String, Object?>{
        'status': RoomStatus.available.toDbString(),
      };
      if (task.needMopFloor) {
        roomUpdate['checkoutSinceLastFloorClean'] = 0;
      }
      await txn.update(
        DbSchema.tableRooms,
        roomUpdate,
        where: 'id = ?',
        whereArgs: [task.roomId],
      );
    });
  }
}
