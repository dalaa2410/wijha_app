// دوال مساعدة لقراءة JSON بتسامح (أرقام قد تصل كنص، وتواريخ قد تغيب)

int? asInt(dynamic v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt();
  return null;
}

DateTime? asDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString())?.toLocal();
}
