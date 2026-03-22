import '../../core/constants/app_enums.dart';
import '../../core/constants/db_schema.dart';

/// Room entity model. Maps to [DbSchema.tableRooms].
/// Owner: Member 3
class RoomModel {
  final int? id;
  final String roomNumber;
  final int roomTypeId;
  final RoomStatus status;
  final String? notes;
  final int checkoutSinceLastFloorClean;

  const RoomModel({
    this.id,
    required this.roomNumber,
    required this.roomTypeId,
    required this.status,
    this.notes,
    this.checkoutSinceLastFloorClean = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'roomNumber': roomNumber,
      'roomTypeId': roomTypeId,
      'status': status.toDbString(),
      'notes': notes,
      'checkoutSinceLastFloorClean': checkoutSinceLastFloorClean,
    };
  }

  factory RoomModel.fromMap(Map<String, dynamic> map) {
    return RoomModel(
      id: map['id'] as int?,
      roomNumber: map['roomNumber'] as String,
      roomTypeId: map['roomTypeId'] as int,
      status: RoomStatus.fromString(map['status'] as String),
      notes: map['notes'] as String?,
      checkoutSinceLastFloorClean:
          (map['checkoutSinceLastFloorClean'] as int?) ?? 0,
    );
  }

  RoomModel copyWith({
    int? id,
    String? roomNumber,
    int? roomTypeId,
    RoomStatus? status,
    String? notes,
    int? checkoutSinceLastFloorClean,
  }) {
    return RoomModel(
      id: id ?? this.id,
      roomNumber: roomNumber ?? this.roomNumber,
      roomTypeId: roomTypeId ?? this.roomTypeId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      checkoutSinceLastFloorClean:
          checkoutSinceLastFloorClean ?? this.checkoutSinceLastFloorClean,
    );
  }

  @override
  String toString() =>
      'RoomModel(id: $id, roomNumber: $roomNumber, status: $status, floorCounter: $checkoutSinceLastFloorClean)';
}
