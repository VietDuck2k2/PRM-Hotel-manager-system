import '../../core/constants/db_schema.dart';

/// RoomType entity model. Maps to [DbSchema.tableRoomTypes].
/// Owner: Member 3
class RoomTypeModel {
  final int? id;
  final String name;
  final double pricePerNight;
  final String? description;

  const RoomTypeModel({
    this.id,
    required this.name,
    required this.pricePerNight,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'pricePerNight': pricePerNight,
      'description': description,
    };
  }

  factory RoomTypeModel.fromMap(Map<String, dynamic> map) {
    return RoomTypeModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      pricePerNight: (map['pricePerNight'] as num).toDouble(),
      description: map['description'] as String?,
    );
  }

  RoomTypeModel copyWith({
    int? id,
    String? name,
    double? pricePerNight,
    String? description,
  }) {
    return RoomTypeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      pricePerNight: pricePerNight ?? this.pricePerNight,
      description: description ?? this.description,
    );
  }

  @override
  String toString() =>
      'RoomTypeModel(id: $id, name: $name, pricePerNight: $pricePerNight)';
}
