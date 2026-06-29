import 'package:intl/intl.dart';

/// 筆記列表的相對日期顯示（今天 / 昨天 / MM/dd (週) / MM/dd）。
class RelativeDate {
  RelativeDate._();

  static const List<String> _weekdayZh = ['一', '二', '三', '四', '五', '六', '日'];

  static String label(DateTime time, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);
    final that = DateTime(time.year, time.month, time.day);
    final diffDays = today.difference(that).inDays;

    if (diffDays == 0) {
      return '今天 ${DateFormat('HH:mm').format(time)}';
    }
    if (diffDays == 1) {
      return '昨天';
    }
    final wd = _weekdayZh[time.weekday - 1];
    if (time.year == ref.year) {
      return '${DateFormat('MM/dd').format(time)} ($wd)';
    }
    return DateFormat('yyyy/MM/dd').format(time);
  }
}