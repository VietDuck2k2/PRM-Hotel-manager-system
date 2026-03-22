enum HousekeepingTaskSource {
  checkout,
  manualDirty;

  String toDbString() {
    switch (this) {
      case HousekeepingTaskSource.checkout:
        return 'CHECKOUT';
      case HousekeepingTaskSource.manualDirty:
        return 'MANUAL_DIRTY';
    }
  }

  static HousekeepingTaskSource fromString(String value) {
    switch (value) {
      case 'CHECKOUT':
        return HousekeepingTaskSource.checkout;
      case 'MANUAL_DIRTY':
        return HousekeepingTaskSource.manualDirty;
      default:
        throw ArgumentError('Unknown HousekeepingTaskSource: $value');
    }
  }
}

enum HousekeepingTaskStatus {
  pending,
  inProgress,
  done;

  String toDbString() {
    switch (this) {
      case HousekeepingTaskStatus.pending:
        return 'PENDING';
      case HousekeepingTaskStatus.inProgress:
        return 'IN_PROGRESS';
      case HousekeepingTaskStatus.done:
        return 'DONE';
    }
  }

  static HousekeepingTaskStatus fromString(String value) {
    switch (value) {
      case 'PENDING':
        return HousekeepingTaskStatus.pending;
      case 'IN_PROGRESS':
        return HousekeepingTaskStatus.inProgress;
      case 'DONE':
        return HousekeepingTaskStatus.done;
      default:
        throw ArgumentError('Unknown HousekeepingTaskStatus: $value');
    }
  }
}

class HousekeepingTaskModel {
  final int? id;
  final int roomId;
  final HousekeepingTaskSource sourceType;
  final HousekeepingTaskStatus status;
  final int? assignedHousekeeperId;
  final String? assignedHousekeeperName;
  final int dirtyAt;
  final int? startedAt;
  final int? finishedAt;
  final bool needChangeSheets;
  final bool needCleanBathroom;
  final bool needMopFloor;
  final bool doneChangeSheets;
  final bool doneCleanBathroom;
  final bool doneMopFloor;

  const HousekeepingTaskModel({
    this.id,
    required this.roomId,
    required this.sourceType,
    required this.status,
    this.assignedHousekeeperId,
    this.assignedHousekeeperName,
    required this.dirtyAt,
    this.startedAt,
    this.finishedAt,
    required this.needChangeSheets,
    required this.needCleanBathroom,
    required this.needMopFloor,
    required this.doneChangeSheets,
    required this.doneCleanBathroom,
    required this.doneMopFloor,
  });

  factory HousekeepingTaskModel.fromMap(Map<String, dynamic> map) {
    return HousekeepingTaskModel(
      id: map['id'] as int?,
      roomId: map['roomId'] as int,
      sourceType:
          HousekeepingTaskSource.fromString(map['sourceType'] as String),
      status: HousekeepingTaskStatus.fromString(map['status'] as String),
      assignedHousekeeperId: map['assignedHousekeeperId'] as int?,
      assignedHousekeeperName: map['assignedHousekeeperName'] as String?,
      dirtyAt: map['dirtyAt'] as int,
      startedAt: map['startedAt'] as int?,
      finishedAt: map['finishedAt'] as int?,
      needChangeSheets: (map['needChangeSheets'] as int?) == 1,
      needCleanBathroom: (map['needCleanBathroom'] as int?) == 1,
      needMopFloor: (map['needMopFloor'] as int?) == 1,
      doneChangeSheets: (map['doneChangeSheets'] as int?) == 1,
      doneCleanBathroom: (map['doneCleanBathroom'] as int?) == 1,
      doneMopFloor: (map['doneMopFloor'] as int?) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'roomId': roomId,
      'sourceType': sourceType.toDbString(),
      'status': status.toDbString(),
      'assignedHousekeeperId': assignedHousekeeperId,
      'assignedHousekeeperName': assignedHousekeeperName,
      'dirtyAt': dirtyAt,
      'startedAt': startedAt,
      'finishedAt': finishedAt,
      'needChangeSheets': needChangeSheets ? 1 : 0,
      'needCleanBathroom': needCleanBathroom ? 1 : 0,
      'needMopFloor': needMopFloor ? 1 : 0,
      'doneChangeSheets': doneChangeSheets ? 1 : 0,
      'doneCleanBathroom': doneCleanBathroom ? 1 : 0,
      'doneMopFloor': doneMopFloor ? 1 : 0,
    };
  }

  HousekeepingTaskModel copyWith({
    int? id,
    HousekeepingTaskStatus? status,
    int? assignedHousekeeperId,
    String? assignedHousekeeperName,
    int? startedAt,
    int? finishedAt,
    bool? doneChangeSheets,
    bool? doneCleanBathroom,
    bool? doneMopFloor,
  }) {
    return HousekeepingTaskModel(
      id: id ?? this.id,
      roomId: roomId,
      sourceType: sourceType,
      status: status ?? this.status,
      assignedHousekeeperId:
          assignedHousekeeperId ?? this.assignedHousekeeperId,
      assignedHousekeeperName:
          assignedHousekeeperName ?? this.assignedHousekeeperName,
      dirtyAt: dirtyAt,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      needChangeSheets: needChangeSheets,
      needCleanBathroom: needCleanBathroom,
      needMopFloor: needMopFloor,
      doneChangeSheets: doneChangeSheets ?? this.doneChangeSheets,
      doneCleanBathroom: doneCleanBathroom ?? this.doneCleanBathroom,
      doneMopFloor: doneMopFloor ?? this.doneMopFloor,
    );
  }
}
