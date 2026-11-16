import 'package:equatable/equatable.dart';
import 'trip.dart';

// صفحة واحدة من الرحلات مع معلومات الترقيم (meta)
class TripsPage extends Equatable {
  final List<Trip> trips;
  final int currentPage;
  final int lastPage;
  final int total;

  const TripsPage({
    required this.trips,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;

  @override
  List<Object?> get props => [trips, currentPage, lastPage, total];
}
