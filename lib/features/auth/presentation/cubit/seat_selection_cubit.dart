import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wijha_app/core/network/api_exception.dart';
import 'package:wijha_app/features/bookings/domain/entities/booking.dart';
import 'package:wijha_app/features/bookings/domain/repositories/booking_repository.dart';
import '../../domain/entities/seat.dart';
import '../../domain/entities/seat_map.dart';
import '../../domain/entities/seat_ownership.dart';
import '../../domain/repositories/seat_repository.dart';

enum SeatMapStatus { loading, loaded, failure }

// يحوّل حجوزاتك لهذه الرحلة إلى: رقم المقعد ← ملكيته
//   حجز معلّق لم تنتهِ مهلته  ← mineHeld (أصفر)
//   حجز مدفوع                 ← mineConfirmed (أخضر)
//   ملغى أو منتهٍ              ← لا يُلوَّن
Map<String, SeatOwnership> buildSeatOwnership(
  List<Booking> bookings,
  int tripId,
) {
  final result = <String, SeatOwnership>{};
  final now = DateTime.now();

  for (final b in bookings) {
    if (b.tripId != tripId) continue;

    final SeatOwnership? kind = switch (b.status) {
      BookingStatus.confirmed => SeatOwnership.mineConfirmed,
      BookingStatus.pending when b.expiresAt.isAfter(now) =>
        SeatOwnership.mineHeld,
      _ => null,
    };
    if (kind == null) continue;

    for (final n in b.seatNumbers) {
      // المدفوع يغلب المعلّق إن تكرر الرقم
      if (result[n] != SeatOwnership.mineConfirmed) result[n] = kind;
    }
  }
  return result;
}

class SeatSelectionState extends Equatable {
  final SeatMapStatus status;
  final SeatMap? seatMap;
  final Set<int> selectedIds;
  final String? message; // رسالة عابرة (SnackBar)
  final String? errorMessage; // سبب فشل التحميل
  final bool isSubmitting; // أثناء إرسال طلب الحجز
  final Booking? createdBooking; // حجز جديد (مرة واحدة) للانتقال لتفاصيله
  final Booking? activeHold; // حجز معلّق لهذه الرحلة لم تنتهِ مهلته
  final Map<String, SeatOwnership> mySeats; // مقاعدك في هذه الرحلة وألوانها

  const SeatSelectionState({
    this.status = SeatMapStatus.loading,
    this.seatMap,
    this.selectedIds = const {},
    this.message,
    this.errorMessage,
    this.isSubmitting = false,
    this.createdBooking,
    this.activeHold,
    this.mySeats = const {},
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
    Booking? createdBooking,
    Booking? activeHold,
    Map<String, SeatOwnership>? mySeats,
    bool clearMessage = false,
    bool clearCreatedBooking = false,
    bool clearHold = false,
  }) {
    return SeatSelectionState(
      status: status ?? this.status,
      seatMap: seatMap ?? this.seatMap,
      selectedIds: selectedIds ?? this.selectedIds,
      message: clearMessage ? null : (message ?? this.message),
      errorMessage: errorMessage ?? this.errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      createdBooking: clearCreatedBooking
          ? null
          : (createdBooking ?? this.createdBooking),
      activeHold: clearHold ? null : (activeHold ?? this.activeHold),
      mySeats: mySeats ?? this.mySeats,
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
    createdBooking,
    activeHold,
    mySeats,
  ];
}

class SeatSelectionCubit extends Cubit<SeatSelectionState> {
  final SeatRepository repository;
  final BookingRepository bookingRepository;
  final int tripId;
  static const int maxSeats = 5;

  SeatSelectionCubit({
    required this.repository,
    required this.bookingRepository,
    required this.tripId,
  }) : super(const SeatSelectionState());

  // حجوزات هذه الرحلة: (الحجز المعلّق القائم، وألوان مقاعدك)
  Future<({Booking? hold, Map<String, SeatOwnership> seats})>
  _loadMyBookingsInfo() async {
    try {
      final all = await bookingRepository.getMyBookings();
      Booking? hold;
      for (final b in all) {
        // القائمة مرتبة: الأحدث أولًا
        if (b.tripId == tripId &&
            b.status == BookingStatus.pending &&
            b.expiresAt.isAfter(DateTime.now())) {
          hold = b;
          break;
        }
      }
      return (hold: hold, seats: buildSeatOwnership(all, tripId));
    } catch (_) {
      return (hold: null, seats: const <String, SeatOwnership>{});
    }
  }

  Future<void> loadSeats({bool keepSelection = true}) async {
    emit(state.copyWith(status: SeatMapStatus.loading));
    try {
      final map = await repository.getSeatMap(tripId);
      final mine = await _loadMyBookingsInfo();
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
          activeHold: mine.hold,
          clearHold: mine.hold == null,
          mySeats: mine.seats,
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

  // يُستدعى عند انتهاء مهلة شريط المتابعة: تعود المقاعد الصفراء إلى حالتها
  Future<void> refreshHold() async {
    final mine = await _loadMyBookingsInfo();
    if (isClosed) return;
    emit(
      state.copyWith(
        activeHold: mine.hold,
        clearHold: mine.hold == null,
        mySeats: mine.seats,
      ),
    );
  }

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
    final map = state.seatMap;
    if (map == null) return;

    emit(state.copyWith(isSubmitting: true));
    try {
      final reservation = await repository.reserveSeats(
        tripId,
        state.selectedIds.toList(),
      );
      if (isClosed) return;

      // نحفظ الحجز محليًا ليظهر في "حجوزاتي" وفي شريط المتابعة وألوان المقاعد
      final booking = Booking(
        id: reservation.bookingId,
        tripId: tripId,
        seatNumbers: state.selectedSeats.map((s) => s.number ?? '').toList(),
        pricePerSeat: map.pricePerSeat,
        totalPrice: state.totalPrice,
        currency: map.currency,
        busNumber: map.busNumber,
        origin: map.origin,
        destination: map.destination,
        departureTime: map.departureTime,
        // إن لم يرسل الباك وقت الانتهاء نفترض 10 دقائق
        expiresAt:
            reservation.expiresAt ??
            DateTime.now().add(const Duration(minutes: 10)),
        createdAt: DateTime.now(),
        status: BookingStatus.pending,
        paymentUrl: null,
      );
      try {
        await bookingRepository.saveBooking(booking);
      } catch (_) {
        // فشل التخزين المحلي لا يمنع المتابعة، فالحجز موجود في الباك
      }

      emit(state.copyWith(isSubmitting: false, createdBooking: booking));
      emit(state.copyWith(clearCreatedBooking: true));
      // المقاعد صارت محجوزة في الباك: نحدّث الخريطة (فتظهر صفراء) ونصفّر الاختيار
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
