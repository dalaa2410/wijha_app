import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wijha_app/core/network/api_exception.dart';
import 'package:wijha_app/core/utils/date_formatter.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';

enum TripsStatus { loading, loaded, failure }

enum TripSort { time, price }

int _byTime(Trip a, Trip b) {
  final x = a.departureTime;
  final y = b.departureTime;
  if (x == null && y == null) return 0;
  if (x == null) return 1;
  if (y == null) return -1;
  return x.compareTo(y);
}

int _byPrice(Trip a, Trip b) {
  final c = a.pricePerSeat.compareTo(b.pricePerSeat);
  return c != 0 ? c : _byTime(a, b);
}

class TripsState extends Equatable {
  final TripsStatus status;
  final List<Trip> trips; // الرحلات المحمّلة من الباك (كل الصفحات)
  final int currentPage;
  final int lastPage;
  final int total;
  final bool isLoadingMore;
  final DateTime? selectedDate;
  final TripSort sort;
  final String? errorMessage;

  const TripsState({
    this.status = TripsStatus.loading,
    this.trips = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.isLoadingMore = false,
    this.selectedDate,
    this.sort = TripSort.time,
    this.errorMessage,
  });

  bool get hasMore => currentPage < lastPage;

  // ما يُعرض فعلًا: تصفية باليوم المختار ثم الترتيب
  List<Trip> get visibleTrips {
    final day = selectedDate;
    final list = trips.where((t) {
      if (day == null) return true;
      final dep = t.departureTime;
      return dep != null && isSameDay(dep, day);
    }).toList();
    list.sort(sort == TripSort.price ? _byPrice : _byTime);
    return list;
  }

  TripsState copyWith({
    TripsStatus? status,
    List<Trip>? trips,
    int? currentPage,
    int? lastPage,
    int? total,
    bool? isLoadingMore,
    DateTime? selectedDate,
    TripSort? sort,
    String? errorMessage,
    bool clearDate = false,
    bool clearError = false,
  }) {
    return TripsState(
      status: status ?? this.status,
      trips: trips ?? this.trips,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      selectedDate: clearDate ? null : (selectedDate ?? this.selectedDate),
      sort: sort ?? this.sort,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    trips,
    currentPage,
    lastPage,
    total,
    isLoadingMore,
    selectedDate,
    sort,
    errorMessage,
  ];
}

class TripsCubit extends Cubit<TripsState> {
  final TripRepository repository;
  final String? origin;
  final String? destination;

  TripsCubit({required this.repository, this.origin, this.destination})
    : super(const TripsState());

  // silent = true: لا نستبدل القائمة بدوران التحميل (للسحب للتحديث)
  Future<void> load({bool silent = false}) async {
    if (!silent) {
      emit(state.copyWith(status: TripsStatus.loading, clearError: true));
    }
    try {
      final page = await repository.getTrips(
        origin: origin,
        destination: destination,
        date: state.selectedDate,
        page: 1,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          status: TripsStatus.loaded,
          trips: page.trips,
          currentPage: page.currentPage,
          lastPage: page.lastPage,
          total: page.total,
          isLoadingMore: false,
          clearError: true,
        ),
      );
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(status: TripsStatus.failure, errorMessage: e.message),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: TripsStatus.failure,
          errorMessage: 'حدث خطأ غير متوقع',
        ),
      );
    }
  }

  // الصفحة التالية (التمرير اللانهائي)
  Future<void> loadMore() async {
    if (state.status != TripsStatus.loaded ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }
    emit(state.copyWith(isLoadingMore: true));
    try {
      final page = await repository.getTrips(
        origin: origin,
        destination: destination,
        date: state.selectedDate,
        page: state.currentPage + 1,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoadingMore: false,
          trips: [...state.trips, ...page.trips],
          currentPage: page.currentPage,
          lastPage: page.lastPage,
          total: page.total,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> changeDate(DateTime? date) async {
    emit(state.copyWith(selectedDate: date, clearDate: date == null));
    await load();
  }

  void changeSort(TripSort sort) => emit(state.copyWith(sort: sort));
}
