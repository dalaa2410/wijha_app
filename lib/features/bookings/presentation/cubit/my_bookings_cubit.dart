import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';

enum MyBookingsStatus { loading, loaded, failure }

class MyBookingsState extends Equatable {
  final MyBookingsStatus status;
  final List<Booking> bookings;
  final int version; // يزيد مع كل تحميل ليُعاد الرسم حتى لو تطابقت القائمة

  const MyBookingsState({
    this.status = MyBookingsStatus.loading,
    this.bookings = const [],
    this.version = 0,
  });

  // القادمة: معلّقة سارية أو مدفوعة
  List<Booking> get upcoming => bookings.where((b) {
    final s = b.effectiveStatus;
    return s == BookingStatus.pending || s == BookingStatus.confirmed;
  }).toList();

  // السابقة: ملغاة أو منتهية
  List<Booking> get past => bookings.where((b) {
    final s = b.effectiveStatus;
    return s == BookingStatus.cancelled || s == BookingStatus.expired;
  }).toList();

  @override
  List<Object?> get props => [status, bookings, version];
}

class MyBookingsCubit extends Cubit<MyBookingsState> {
  final BookingRepository repository;
  MyBookingsCubit(this.repository) : super(const MyBookingsState());

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      emit(MyBookingsState(status: MyBookingsStatus.loading, version: state.version));
    }
    try {
      final list = await repository.getMyBookings();
      if (isClosed) return;
      emit(
        MyBookingsState(
          status: MyBookingsStatus.loaded,
          bookings: list,
          version: state.version + 1,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(MyBookingsState(status: MyBookingsStatus.failure, version: state.version + 1));
    }
  }
}
