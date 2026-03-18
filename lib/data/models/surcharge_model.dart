import '../../core/constants/db_schema.dart';

/// Surcharge entity model. Maps to [DbSchema.tableSurcharges].
/// Owner: Member 4
class SurchargeModel {
  final int? id;
  final int bookingId;
  final String description;
  final double amount;
  final int createdAt; // Unix ms

  const SurchargeModel({
    this.id,
    required this.bookingId,
    required this.description,
    required this.amount,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'bookingId': bookingId,
      'description': description,
      'amount': amount,
      'createdAt': createdAt,
    };
  }

  factory SurchargeModel.fromMap(Map<String, dynamic> map) {
    return SurchargeModel(
      id: map['id'] as int?,
      bookingId: map['bookingId'] as int,
      description: map['description'] as String,
      amount: (map['amount'] as num).toDouble(),
      createdAt: map['createdAt'] as int,
    );
  }

  @override
  String toString() =>
      'SurchargeModel(id: $id, bookingId: $bookingId, amount: $amount)';
}
