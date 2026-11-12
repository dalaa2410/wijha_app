import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wijha_app/core/network/api_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import 'request_state.dart';

class ForgotPasswordCubit extends Cubit<RequestState> {
  final AuthRepository repository;
  ForgotPasswordCubit(this.repository) : super(const RequestState());

  Future<void> send(String email) async {
    emit(const RequestState(status: RequestStatus.loading));
    try {
      await repository.forgotPassword(email);
      if (isClosed) return;
      emit(const RequestState(status: RequestStatus.success));
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(RequestState(status: RequestStatus.failure, message: e.message));
    } catch (_) {
      if (isClosed) return;
      emit(const RequestState(
        status: RequestStatus.failure,
        message: 'حدث خطأ غير متوقع',
      ));
    }
  }

  // للعودة إلى النموذج من شاشة التأكيد ("أعد المحاولة")
  void reset() => emit(const RequestState());
}