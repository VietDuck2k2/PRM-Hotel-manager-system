import '../../core/constants/db_schema.dart';

/// Invoice entity model. Maps to [DbSchema.tableInvoices].
/// Owner: Member 4
///
/// RULE: Invoice is created ONLY during the checkout flow.
/// One Invoice per Booking (enforced by UNIQUE constraint on bookingId in DB).
class InvoiceModel {
  final int? id;
  final int bookingId;
  final double roomCharge;
  final double surchargeTotal;
  final double totalAmount;
  final int issuedBy; // User.id of receptionist/admin who processed checkout
  final int issuedAt; // Unix ms

  const InvoiceModel({
    this.id,
    required this.bookingId,
    required this.roomCharge,
    required this.surchargeTotal,
    required this.totalAmount,
    required this.issuedBy,
    required this.issuedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'bookingId': bookingId,
      'roomCharge': roomCharge,
      'surchargeTotal': surchargeTotal,
      'totalAmount': totalAmount,
      'issuedBy': issuedBy,
      'issuedAt': issuedAt,
    };
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      id: map['id'] as int?,
      bookingId: map['bookingId'] as int,
      roomCharge: (map['roomCharge'] as num).toDouble(),
      surchargeTotal: (map['surchargeTotal'] as num).toDouble(),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      issuedBy: map['issuedBy'] as int,
      issuedAt: map['issuedAt'] as int,
    );
  }

  @override
  String toString() =>
      'InvoiceModel(id: $id, bookingId: $bookingId, total: $totalAmount)';
}
