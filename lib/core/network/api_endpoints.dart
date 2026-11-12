class ApiEndpoints {
  static const login = '/auth/login';
  static const String register = '/auth/register';
  static const forgotPassword = '/auth/forgot-password';
  static String tripSeats(int tripId) => '/trips/$tripId/seats';
  static const reserve = '/bookings/reserve';
  static String confirm(int bookingId) => '/bookings/$bookingId/confirm';
  
}
