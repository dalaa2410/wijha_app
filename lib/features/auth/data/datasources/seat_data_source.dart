import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:wijha_app/core/network/api_client.dart';
import 'package:wijha_app/core/network/api_endpoints.dart';
import '../models/reservation_model.dart';
import '../models/seat_map_model.dart';
import 'package:wijha_app/core/network/api_exception.dart';

abstract class SeatDataSource {
  Future<SeatMapModel> fetchSeatMap(int tripId);
  Future<ReservationModel> reserveSeats(int tripId, List<int> seatIds);
  Future<void> confirmBooking(int bookingId, String paymentReference);
}

// المصدر المحلي: للتجربة دون إنترنت
class SeatMockDataSource implements SeatDataSource {
  @override
  Future<SeatMapModel> fetchSeatMap(int tripId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final raw = await rootBundle.loadString('assets/mock/seat_map.json');
    return SeatMapModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<ReservationModel> reserveSeats(int tripId, List<int> seatIds) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return const ReservationModel(bookingId: 0);
  }

  @override
Future<void> confirmBooking(int bookingId, String paymentReference) async {
  await Future.delayed(const Duration(milliseconds: 600));
}
}

// المصدر الحقيقي: الاتصال بالباك عبر ApiClient
class SeatRemoteDataSource implements SeatDataSource {
  final ApiClient client;
  SeatRemoteDataSource(this.client);

  @override
  Future<SeatMapModel> fetchSeatMap(int tripId) async {
    final json = await client.get(ApiEndpoints.tripSeats(tripId));
    return SeatMapModel.fromJson(json);
  }

  @override
  Future<ReservationModel> reserveSeats(int tripId, List<int> seatIds) async {
    final json = await client.post(
      ApiEndpoints.reserve,
      body: {'trip_id': tripId, 'seat_ids': seatIds},
    );
    return ReservationModel.fromJson(json);
  }

@override
Future<void> confirmBooking(int bookingId, String paymentReference) async {
  final json = await client.post(
    ApiEndpoints.confirm(bookingId),
    body: {'payment_reference': paymentReference},
  );
  if (json['success'] == false) {
    throw UnknownException(json['message']?.toString());
  }
}
}