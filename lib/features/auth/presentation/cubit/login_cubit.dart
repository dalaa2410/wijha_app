import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wijha_app/core/network/api_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import 'request_state.dart';

class LoginCubit extends Cubit<RequestState> {
  final AuthRepository repository;
  LoginCubit(this.repository) : super(const RequestState());

  Future<void> login(String email, String password) async {
    emit(const RequestState(status: RequestStatus.loading));
    try {
      await repository.login(email, password);
      if (isClosed) return;
      emit(const RequestState(status: RequestStatus.success));
    } on UnauthorizedException {
      if (isClosed) return;
      emit(const RequestState(
        status: RequestStatus.failure,
        message: 'البريد الإلكتروني أو كلمة المرور غير صحيحة',
      ));
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
}