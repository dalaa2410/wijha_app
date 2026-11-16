import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:wijha_app/core/network/api_client.dart';
import 'package:wijha_app/core/network/api_endpoints.dart';
import '../models/trips_page_model.dart';

abstract class TripDataSource {
  Future<TripsPageModel> fetchTrips({
    String? origin,
    String? destination,
    DateTime? date,
    int page = 1,
  });
}

// المصدر المحلي: رحلات تجريبية للعرض الاحتياطي
class TripMockDataSource implements TripDataSource {
  @override
  Future<TripsPageModel> fetchTrips({
    String? origin,
    String? destination,
    DateTime? date,
    int page = 1,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final raw = await rootBundle.loadString('assets/mock/trips.json');
    return TripsPageModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}

// المصدر الحقيقي: GET /trips
class TripRemoteDataSource implements TripDataSource {
  final ApiClient client;
  TripRemoteDataSource(this.client);

  @override
  Future<TripsPageModel> fetchTrips({
    String? origin,
    String? destination,
    DateTime? date,
    int page = 1,
  }) async {
    // TODO: تأكدي من أسماء المعاملات مع الباك (origin / destination / date / page)
    final json = await client.get(
      ApiEndpoints.trips,
      query: {
        'page': page,
        if (origin != null && origin.isNotEmpty) 'origin': origin,
        if (destination != null && destination.isNotEmpty)
          'destination': destination,
        if (date != null) 'date': _ymd(date),
      },
    );
    return TripsPageModel.fromJson(json);
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
