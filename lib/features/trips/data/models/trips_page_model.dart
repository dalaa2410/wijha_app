import 'package:wijha_app/core/utils/json_parsing.dart';
import '../../domain/entities/trip.dart';
import '../../domain/entities/trips_page.dart';
import 'trip_model.dart';

class TripsPageModel extends TripsPage {
  const TripsPageModel({
    required super.trips,
    required super.currentPage,
    required super.lastPage,
    required super.total,
  });

  // الشكل المتوقع: { success, data: [ ...رحلات ], meta: { current_page, last_page, per_page, total } }
  factory TripsPageModel.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final List items = raw is List
        ? raw
        : (raw is Map && raw['data'] is List ? raw['data'] as List : const []);

    final trips = <Trip>[];
    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;
      try {
        trips.add(TripModel.fromJson(item));
      } catch (_) {
        // نتجاهل أي سجل تالف بدل أن تنهار القائمة كلها
      }
    }

    final metaRaw = json['meta'];
    final meta = metaRaw is Map<String, dynamic>
        ? metaRaw
        : const <String, dynamic>{};

    return TripsPageModel(
      trips: trips,
      currentPage: asInt(meta['current_page']) ?? 1,
      lastPage: asInt(meta['last_page']) ?? 1,
      total: asInt(meta['total']) ?? trips.length,
    );
  }
}
