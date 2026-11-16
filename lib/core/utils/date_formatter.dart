const _months = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
];

const _weekdays = [
  'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد',
];

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

// 28 أكتوبر
String formatDayShort(DateTime d) => '${d.day} ${_months[d.month - 1]}';

// الأربعاء، 28 أكتوبر 2026
String formatDayFull(DateTime d) =>
    '${_weekdays[d.weekday - 1]}، ${d.day} ${_months[d.month - 1]} ${d.year}';

// 08:00 ص
String formatTime12(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  final suffix = d.hour < 12 ? 'ص' : 'م';
  return '${h.toString().padLeft(2, '0')}:$m $suffix';
}

// 28 أكتوبر · 08:00 ص
String formatDeparture(DateTime d) =>
    '${formatDayShort(d)} · ${formatTime12(d)}';

// 6 ساعات 30 دقيقة
String formatDuration(Duration d) {
  final totalMinutes = d.inMinutes;
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  final parts = <String>[];
  if (h > 0) parts.add(_unit(h, 'ساعة', 'ساعتان', 'ساعات', 'ساعة'));
  if (m > 0) parts.add(_unit(m, 'دقيقة', 'دقيقتان', 'دقائق', 'دقيقة'));
  return parts.isEmpty ? 'أقل من دقيقة' : parts.join(' ');
}

String _unit(int n, String one, String two, String few, String many) {
  if (n == 1) return one;
  if (n == 2) return two;
  if (n >= 3 && n <= 10) return '$n $few';
  return '$n $many';
}
