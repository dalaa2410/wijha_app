import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wijha_app/core/network/api_exception.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/payment_receipt.dart';
import '../../domain/entities/payment_session.dart';
import '../../domain/repositories/booking_repository.dart';

enum BookingFlow {
  active, // حجز معلّق والمهلة جارية
  startingPayment, // جارٍ طلب جلسة الدفع من الباك
  awaitingPayment, // نافذة الدفع مفتوحة
  confirmed, // حجز مدفوع ومؤكد
  expired, // انتهت المهلة
  conflict, // تعارض (409) عند بدء الدفع
  failure, // فشل مؤقت: يمكن المحاولة من جديد
  cancelling, // جارٍ الإلغاء
  cancelled, // تم الإلغاء
}

class BookingDetailsState extends Equatable {
  final Booking booking;
  final BookingFlow flow;
  final int secondsRemaining;
  final String? message;
  final PaymentSession? session; // جلسة تنتظر فتح نافذة الدفع (مرة واحدة)
  final PaymentReceipt? receipt; // إيصال يعرض شاشة النجاح (مرة واحدة)

  const BookingDetailsState({
    required this.booking,
    required this.flow,
    required this.secondsRemaining,
    this.message,
    this.session,
    this.receipt,
  });

  // الدفع: فقط والحجز المؤقت قائم (يتعطل عند الانتهاء والتعارض والإلغاء)
  bool get canPay =>
      flow == BookingFlow.active || flow == BookingFlow.failure;

  // الإلغاء: للحجز المعلّق والمدفوع
  bool get canCancel =>
      flow == BookingFlow.active ||
      flow == BookingFlow.failure ||
      flow == BookingFlow.confirmed;

  bool get isBusy =>
      flow == BookingFlow.startingPayment ||
      flow == BookingFlow.awaitingPayment ||
      flow == BookingFlow.cancelling;

  BookingDetailsState copyWith({
    Booking? booking,
    BookingFlow? flow,
    int? secondsRemaining,
    String? message,
    PaymentSession? session,
    PaymentReceipt? receipt,
    bool clearMessage = false,
    bool clearSession = false,
    bool clearReceipt = false,
  }) {
    return BookingDetailsState(
      booking: booking ?? this.booking,
      flow: flow ?? this.flow,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      message: clearMessage ? null : (message ?? this.message),
      session: clearSession ? null : (session ?? this.session),
      receipt: clearReceipt ? null : (receipt ?? this.receipt),
    );
  }

  @override
  List<Object?> get props => [booking, flow, secondsRemaining, message, session, receipt];
}

class BookingDetailsCubit extends Cubit<BookingDetailsState> {
  final BookingRepository repository;
  Timer? _timer;
  PaymentSession? _lastSession; // آخر جلسة دفع (للإيصال)

  BookingDetailsCubit({required this.repository, required Booking booking})
    : super(
        BookingDetailsState(
          booking: booking,
          flow: _initialFlow(booking),
          secondsRemaining: _remaining(booking),
        ),
      );

  static BookingFlow _initialFlow(Booking b) => switch (b.effectiveStatus) {
    BookingStatus.pending => BookingFlow.active,
    BookingStatus.confirmed => BookingFlow.confirmed,
    BookingStatus.cancelled => BookingFlow.cancelled,
    BookingStatus.expired => BookingFlow.expired,
  };

  static int _remaining(Booking b) {
    final d = b.expiresAt.difference(DateTime.now()).inSeconds;
    return d < 0 ? 0 : d;
  }

  bool get _deadlinePassed => state.booking.isHoldExpired;

  // العدّاد يعمل فقط للحجز المعلّق
  void start() {
    if (state.flow != BookingFlow.active) return;
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  // نحسب المتبقي من وقت الانتهاء نفسه في كل مرة (لا نعدّ تنازليًا)
  void _tick() {
    if (isClosed ||
        state.flow == BookingFlow.confirmed ||
        state.flow == BookingFlow.cancelled) {
      return;
    }
    final remaining = _remaining(state.booking);
    final canExpire =
        state.flow == BookingFlow.active || state.flow == BookingFlow.failure;

    if (remaining == 0 && canExpire) {
      _timer?.cancel();
      emit(state.copyWith(flow: BookingFlow.expired, secondsRemaining: 0));
    } else {
      emit(state.copyWith(secondsRemaining: remaining));
    }
  }

  // الخطوة 1 من الدفع: نطلب جلسة من الباك، ثم تفتح الواجهة نافذة الدفع
  Future<void> pay() async {
    if (!state.canPay) return;
    emit(state.copyWith(flow: BookingFlow.startingPayment, clearMessage: true));
    try {
      final session = await repository.startPayment(state.booking.id);
      if (isClosed) return;
      _lastSession = session;
      final updated =
          await repository.getBooking(state.booking.id) ?? state.booking;
      emit(
        state.copyWith(
          booking: updated,
          flow: BookingFlow.awaitingPayment,
          session: session,
        ),
      );
      emit(state.copyWith(clearSession: true)); // الجلسة تُستهلك مرة واحدة
    } on ConflictException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(flow: BookingFlow.conflict, message: e.message));
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          flow: _deadlinePassed ? BookingFlow.expired : BookingFlow.failure,
          message: e.message,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          flow: BookingFlow.failure,
          message: 'حدث خطأ غير متوقع',
        ),
      );
    }
  }

  // الخطوة 2: يؤكد المستخدم أنه أكمل الدفع في المتصفح (paid) أو لا
  Future<void> paymentClosed({required bool paid}) async {
    if (isClosed || state.flow != BookingFlow.awaitingPayment) return;

    if (paid) {
      try {
        await repository.markPaid(state.booking.id);
      } catch (_) {}
      final updated =
          await repository.getBooking(state.booking.id) ??
          state.booking.copyWith(status: BookingStatus.confirmed);
      if (isClosed) return;
      _timer?.cancel();
      final receipt = PaymentReceipt(
        booking: updated,
        session:
            _lastSession ??
            PaymentSession(
              gateway: 'sandbox',
              sessionId: '',
              amount: updated.totalPrice,
              currency: updated.currency,
              checkoutUrl: updated.paymentUrl ?? '',
            ),
        paidAt: DateTime.now(),
      );
      emit(
        state.copyWith(
          booking: updated,
          flow: BookingFlow.confirmed,
          receipt: receipt,
        ),
      );
      emit(state.copyWith(clearReceipt: true)); // الإيصال يُستهلك مرة واحدة
    } else {
      // لم يُكمل المستخدم الدفع: نعيد الحجز إلى حالته (دون رسالة خطأ)
      emit(
        state.copyWith(
          flow: _deadlinePassed ? BookingFlow.expired : BookingFlow.active,
          clearMessage: true,
        ),
      );
    }
  }

  // إلغاء الحجز (المعلّق أو المدفوع)
  Future<void> cancel() async {
    if (!state.canCancel) return;
    final wasConfirmed = state.flow == BookingFlow.confirmed;

    emit(state.copyWith(flow: BookingFlow.cancelling, clearMessage: true));
    try {
      await repository.cancelBooking(state.booking.id);
      if (isClosed) return;
      _timer?.cancel();
      emit(
        state.copyWith(
          booking: state.booking.copyWith(status: BookingStatus.cancelled),
          flow: BookingFlow.cancelled,
        ),
      );
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          flow: wasConfirmed
              ? BookingFlow.confirmed
              : (_deadlinePassed ? BookingFlow.expired : BookingFlow.failure),
          message: e.message,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          flow: wasConfirmed ? BookingFlow.confirmed : BookingFlow.failure,
          message: 'تعذّر إلغاء الحجز، حاول مرة أخرى',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
