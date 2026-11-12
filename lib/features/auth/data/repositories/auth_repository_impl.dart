import 'package:wijha_app/core/network/token_storage.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;
  final TokenStorage storage;
  AuthRepositoryImpl(this.remote, this.storage);

  @override
  Future<void> login(String email, String password) async {
    final token = await remote.login(email, password);
    await storage.save(token); // بعدها يضيفه الـ Interceptor لكل طلب تلقائيًا
  }

  @override
  Future<void> forgotPassword(String email) => remote.forgotPassword(email);

  
  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) => remote.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
}