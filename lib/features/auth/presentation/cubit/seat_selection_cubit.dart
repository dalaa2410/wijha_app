import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wijha_app/core/network/api_exception.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/entities/seat.dart';
import '../../domain/entities/seat_map.dart';
import '../../domain/repositories/seat_repository.dart';

enum SeatMapStatus { loading, loaded, failure }

class SeatSelectionState extends Equatable {
  final SeatMapStatus status;
  final SeatMap? seatMap;
  final Set<int> selectedIds;
  final String? message; // رسالة عابرة (SnackBar)
  final String? errorMessage; // سبب فشل التحميل
  final bool isSubmitting; // أثناء إرسال طلب الحجز
  final Reservation? reservation;
  final bool hasPendingBooking;
  final Reservation? pendingReservation;
  final List<String> pendingSeatNumbers;
  final int pendingTotalPrice;

  const SeatSelectionState({
    this.status = SeatMapStatus.loading,
    this.seatMap,
    this.selectedIds = const {},
    this.message,
    this.errorMessage,
    this.isSubmitting = false,
    this.reservation,
    this.hasPendingBooking = false,
    this.pendingReservation,
    this.pendingSeatNumbers = const [],
    this.pendingTotalPrice = 0,
  });

  List<Seat> get selectedSeats {
    final map = seatMap;
    if (map == null) return const [];
    return map.seats.where((s) => selectedIds.contains(s.id)).toList();
  }

  int get totalPrice => selectedIds.length * (seatMap?.pricePerSeat ?? 0);

  SeatSelectionState copyWith({
    SeatMapStatus? status,
    SeatMap? seatMap,
    Set<int>? selectedIds,
    String? message,
    String? errorMessage,
    bool? isSubmitting,
    Reservation? reservation,
    bool clearMessage = false,
    bool clearReservation = false,
    bool? hasPendingBooking,
    Reservation? pendingReservation,
    List<String>? pendingSeatNumbers,
    int? pendingTotalPrice,
  }) {
    return SeatSelectionState(
      status: status ?? this.status,
      seatMap: seatMap ?? this.seatMap,
      selectedIds: selectedIds ?? this.selectedIds,
      message: clearMessage ? null : (message ?? this.message),
      errorMessage: errorMessage ?? this.errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      reservation: clearReservation ? null : (reservation ?? this.reservation),
      hasPendingBooking: hasPendingBooking ?? this.hasPendingBooking,
      pendingReservation: pendingReservation ?? this.pendingReservation,
      pendingSeatNumbers: pendingSeatNumbers ?? this.pendingSeatNumbers,
      pendingTotalPrice: pendingTotalPrice ?? this.pendingTotalPrice,
    );
  }

  @override
  List<Object?> get props => [
        status,
        seatMap,
        selectedIds,
        message,
        errorMessage,
        isSubmitting,
        reservation,
        hasPendingBooking,       
        pendingReservation,    
        pendingSeatNumbers,   
        pendingTotalPrice,     
      ];
}

class SeatSelectionCubit extends Cubit<SeatSelectionState> {
  final SeatRepository repository;
  final int tripId;
  static const int maxSeats = 5;

  SeatSelectionCubit({required this.repository, required this.tripId})
    : super(const SeatSelectionState());

  Future<void> loadSeats({bool keepSelection = true}) async {
    emit(state.copyWith(status: SeatMapStatus.loading));
    try {
      final map = await repository.getSeatMap(tripId);
      if (isClosed) return;

      // keepSelection = true: نُبقي اختياراتكِ ونحذف ما حجزه غيركِ (حالة 409)
      // keepSelection = false: نبدأ من جديد (زر التحديث وبعد الحجز)
      final selected = keepSelection
          ? state.selectedIds
                .where(
                  (id) => map.seats.any((s) => s.id == id && s.isSelectable),
                )
                .toSet()
          : <int>{};

      emit(
        state.copyWith(
          status: SeatMapStatus.loaded,
          seatMap: map,
          selectedIds: selected,
        ),
      );
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(status: SeatMapStatus.failure, errorMessage: e.message),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: SeatMapStatus.failure,
          errorMessage: 'حدث خطأ غير متوقع',
        ),
      );
    }
  }

  // زر التحديث: يمسح الاختيار ويجلب الخريطة من جديد
  Future<void> refresh() => loadSeats(keepSelection: false);

  void toggleSeat(Seat seat) {
    if (!seat.isSelectable) return;

    final selected = {...state.selectedIds};
    if (selected.contains(seat.id)) {
      selected.remove(seat.id);
    } else {
      if (selected.length >= maxSeats) {
        _showMessage('الحد الأقصى $maxSeats مقاعد في الحجز الواحد');
        return;
      }
      selected.add(seat.id);
    }
    emit(state.copyWith(selectedIds: selected));
  }

  Future<void> reserveSelected() async {
    if (state.selectedIds.isEmpty || state.isSubmitting) return;

    emit(state.copyWith(isSubmitting: true));
    try {
      final reservation = await repository.reserveSeats(
        tripId,
        state.selectedIds.toList(),
      );
      if (isClosed) return;
      emit(state.copyWith(isSubmitting: false, reservation: reservation));
      emit(state.copyWith(clearReservation: true));
      // المقاعد صارت محجوزة في الباك: نحدّث الخريطة ونصفّر الاختيار
      await loadSeats(keepSelection: false);
    } on ConflictException catch (e) {
      // 409: أحدهم حجز مقعدًا قبلكِ. نحدّث الخريطة ونُبقي ما تبقى من اختياراتكِ
      if (isClosed) return;
      emit(state.copyWith(isSubmitting: false));
      _showMessage(e.message);
      await loadSeats();
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isSubmitting: false));
      _showMessage(e.message);
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(isSubmitting: false));
      _showMessage('حدث خطأ غير متوقع');
    }
  }

  // نصدر الرسالة ثم نمسحها فورًا لتظهر مرة واحدة فقط
  void _showMessage(String text) {
    emit(state.copyWith(message: text));
    emit(state.copyWith(clearMessage: true));
  }
}