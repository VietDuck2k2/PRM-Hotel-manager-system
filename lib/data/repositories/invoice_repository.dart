import '../../core/database/database_helper.dart';
import '../../core/constants/db_schema.dart';
import '../models/invoice_model.dart';

/// Handles invoice creation and retrieval.
/// Owner: Member 4
///
/// Invoices are ONLY created via [StayService.checkout] — never directly by UI.
class InvoiceRepository {
  final DatabaseHelper _dbHelper;
  InvoiceRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<int> createInvoice(InvoiceModel invoice) async {
    final db = await _dbHelper.database;
    return await db.insert(DbSchema.tableInvoices, invoice.toMap());
  }

  Future<InvoiceModel?> getInvoiceByBookingId(int bookingId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      DbSchema.tableInvoices,
      where: 'bookingId = ?',
      whereArgs: [bookingId],
    );
    if (result.isEmpty) return null;
    return InvoiceModel.fromMap(result.first);
  }

  Future<List<InvoiceModel>> getAllInvoices() async {
    final db = await _dbHelper.database;
    final result = await db.query(DbSchema.tableInvoices, orderBy: 'issuedAt DESC');
    return result.map(InvoiceModel.fromMap).toList();
  }
}
