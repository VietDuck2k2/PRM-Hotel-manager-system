import 'package:intl/intl.dart';

/// Date formatting utilities.
/// Rule: All dates stored in SQLite as INTEGER (Unix ms since epoch).
/// Display formatting happens ONLY in this file or in the UI layer.
/// Owner: Member 1
class DateFormatter {
  DateFormatter._();

  static final DateFormat _displayDate = DateFormat('dd/MM/yyyy');
  static final DateFormat _displayDateTime = DateFormat('dd/MM/yyyy HH:mm');

  /// Convert a [DateTime] to a Unix timestamp in milliseconds for SQLite storage.
  static int toMs(DateTime dt) => dt.millisecondsSinceEpoch;

  /// Convert a Unix timestamp in milliseconds from SQLite to a [DateTime].
  static DateTime fromMs(int ms) => DateTime.fromMillisecondsSinceEpoch(ms);

  /// Format a Unix ms timestamp for display (date only).
  static String formatDate(int ms) => _displayDate.format(fromMs(ms));

  /// Format a Unix ms timestamp for display (date + time).
  static String formatDateTime(int ms) => _displayDateTime.format(fromMs(ms));

  /// Calculate the number of nights between two Unix ms timestamps.
  /// Returns at minimum 1 to avoid zero-night billing edge cases.
  static int calculateNights(int checkInMs, int checkOutMs) {
    final diff = fromMs(checkOutMs).difference(fromMs(checkInMs)).inDays;
    return diff < 1 ? 1 : diff;
  }

  /// Returns today's date at midnight as Unix ms (for default date pickers).
  static int todayMs() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
  }
}
