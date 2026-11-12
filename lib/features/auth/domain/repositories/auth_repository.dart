abstract class AuthRepository {
  Future<void> login(String email, String password);
  Future<void> forgotPassword(String email);
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  });
}