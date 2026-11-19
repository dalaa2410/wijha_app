import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/booking_model.dart';

// سجل حجوزات الجهاز (مخزّن مشفّرًا). مؤقت حتى يوفر الباك endpoint لقائمة الحجوزات
class BookingLocalDataSource {
  static const _key = 'my_bookings_v1';
  final FlutterSecureStorage _storage;

  BookingLocalDataSource([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  Future<List<BookingModel>> readAll() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(BookingModel.fromJson)
          .toList();
    } catch (_) {
      return []; // بيانات تالفة: نبدأ من جديد بدل أن ينهار التطبيق
    }
  }

  Future<void> writeAll(List<BookingModel> bookings) async {
    await _storage.write(
      key: _key,
      value: jsonEncode(bookings.map((b) => b.toJson()).toList()),
    );
  }
}
