import 'package:wijha_app/core/network/api_exception.dart';
import '../../domain/entities/reservation.dart';

class ReservationModel extends Reservation {
  const ReservationModel({required super.bookingId, super.expiresAt});

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final id = data is Map ? (data['id'] ?? data['booking_id']) : null;
    if (id == null) {
      throw const UnknownException('لم يصل رقم الحجز من الخادم');
    }
    return ReservationModel(
      bookingId: (id as num).toInt(),
      expiresAt: DateTime.tryParse(
        (data as Map)['expires_at']?.toString() ?? '',
      ),
    );
  }
}