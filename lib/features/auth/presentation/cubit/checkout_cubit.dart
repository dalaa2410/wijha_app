import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wijha_app/core/network/api_exception.dart';
import '../../domain/repositories/seat_repository.dart';

enum CheckoutStatus { active, submitting, success, expired, conflict, failure }

class CheckoutState extends Equatable {
  final CheckoutStatus status;
  final int secondsRemaining;
  final String? message;

  const CheckoutState({
    this.status = CheckoutStatus.active,
    this.secondsRemaining = 0,
    this.message,
  });

  // يمكن الضغط على الدفع فقط في هاتين الحالتين
  bool get canPay =>
      status == CheckoutStatus.active || status == CheckoutStatus.failure;

  CheckoutState copyWith({
    CheckoutStatus? status,
    int? secondsRemaining,
    String? message,
    bool clearMessage = false,
  }) {
    return CheckoutState(
      status: status ?? this.status,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [status, secondsRemaining, message];
}

class CheckoutCubit extends Cubit<CheckoutState> {
  final SeatRepository repository;
  final int bookingId;
  final DateTime _deadline;
  Timer? _timer;

  // مرجع الدفع يُولَّد مرة واحدة، فإعادة المحاولة لا تنشئ دفعة جديدة
  // مؤقتًا: اسألي الباك عن الصيغة المطلوبة ومعنى هذا الحقل
  late final String _paymentReference =
      'TXN_APP_${bookingId}_${DateTime.now().millisecondsSinceEpoch}';

  CheckoutCubit({
    required this.repository,
    required this.bookingId,
    DateTime? expiresAt,
  }) : _deadline = expiresAt ?? DateTime.now().add(const Duration(minutes: 10)),
       super(const CheckoutState());

  void start() {
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  // نحسب المتبقي من وقت الانتهاء نفسه في كل مرة (لا نعدّ تنازليًا)،
  // فلا يتأخر العدّاد إن توقف التطبيق في الخلفية
  void _tick() {
    if (isClosed || state.status == CheckoutStatus.success) return;

    final diff = _deadline.difference(DateTime.now()).inSeconds;
    final remaining = diff < 0 ? 0 : diff;

    if (remaining == 0 && state.status == CheckoutStatus.active) {
      _timer?.cancel();
      emit(state.copyWith(status: CheckoutStatus.expired, secondsRemaining: 0));
    } else {
      // نحدّث الوقت فقط، ولا نغيّر الحالة (دفع، تعارض، خطأ...)
      emit(state.copyWith(secondsRemaining: remaining));
    }
  }

  Future<void> confirm() async {
    if (!state.canPay) return;

    emit(state.copyWith(status: CheckoutStatus.submitting, clearMessage: true));
    try {
      await repository.confirmBooking(bookingId, _paymentReference);
      if (isClosed) return;
      _timer?.cancel();
      emit(state.copyWith(status: CheckoutStatus.success));
    } on ConflictException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(status: CheckoutStatus.conflict, message: e.message));
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(status: CheckoutStatus.failure, message: e.message));
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: CheckoutStatus.failure,
          message: 'حدث خطأ غير متوقع',
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