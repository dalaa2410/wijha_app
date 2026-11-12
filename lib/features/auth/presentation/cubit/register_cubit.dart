// lib/features/auth/presentation/cubit/register_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wijha_app/core/network/api_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import 'request_state.dart';

class RegisterCubit extends Cubit<RequestState> {
  final AuthRepository repository;
  RegisterCubit(this.repository) : super(const RequestState());

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    emit(const RequestState(status: RequestStatus.loading));
    try {
      await repository.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
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
}