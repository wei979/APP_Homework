/// 時間長度格式化工具。
class DurationFormat {
  DurationFormat._();

  /// 毫秒 → `mm:ss` 或 `h:mm:ss`（>= 1 小時）。
  /// 例：134000 → `02:14`，3750000 → `1:02:30`。
  static String hms(int milliseconds) {
    final totalSeconds = (milliseconds / 1000).floor();
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    if (h > 0) {
      return '$h:$mm:$ss';
    }
    return '$mm:$ss';
  }

  /// 錄音計時用：回傳 `mm:ss` 與 `:cc`（百分秒）兩段，方便分開排版。
  static (String, String) timer(int milliseconds) {
    final totalSeconds = (milliseconds / 1000).floor();
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    final centi = (milliseconds % 1000) ~/ 10;
    final main = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    final ms = ':${centi.toString().padLeft(2, '0')}';
    return (main, ms);
  }
}