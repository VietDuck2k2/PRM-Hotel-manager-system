import '../../core/database/database_helper.dart';
import '../../core/constants/db_schema.dart';
import '../models/surcharge_model.dart';

/// Handles surcharge CRUD.
/// Owner: Member 4
class SurchargeRepository {
  final DatabaseHelper _dbHelper;
  SurchargeRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<SurchargeModel>> getSurchargesForBooking(int bookingId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      DbSchema.tableSurcharges,
      where: 'bookingId = ?',
      whereArgs: [bookingId],
      orderBy: 'createdAt ASC',
    );
    return result.map(SurchargeModel.fromMap).toList();
  }

  Future<int> addSurcharge(SurchargeModel surcharge) async {
    final db = await _dbHelper.database;
    return await db.insert(DbSchema.tableSurcharges, surcharge.toMap());
  }

  Future<int> deleteSurcharge(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DbSchema.tableSurcharges,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Returns the sum of all surcharge amounts for a booking.
  /// Returns 0.0 if no surcharges exist.
  Future<double> getTotalSurcharge(int bookingId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM ${DbSchema.tableSurcharges} WHERE bookingId = ?',
      [bookingId],
    );
    final total = result.first['total'];
    return total == null ? 0.0 : (total as num).toDouble();
  }
}
