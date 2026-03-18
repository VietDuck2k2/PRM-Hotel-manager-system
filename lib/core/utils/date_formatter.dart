class DateFormatter {
  static int toMs(DateTime date) => date.millisecondsSinceEpoch;
  static DateTime fromMs(int ms) => DateTime.fromMillisecondsSinceEpoch(ms);

  static String format(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
