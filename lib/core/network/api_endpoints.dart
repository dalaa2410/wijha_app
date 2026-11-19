class ApiEndpoints {
  static const register = '/auth/register';
  static const login = '/auth/login';
  static const forgotPassword = '/auth/forgot-password';

  // قائمة الرحلات
  static const trips = '/trips';

  static String tripSeats(int tripId) => '/trips/$tripId/seats';
  static const reserve = '/bookings/reserve';
  static String confirm(int bookingId) => '/bookings/$bookingId/confirm';

  // إلغاء الحجز (API 8): {{base_url}}/bookings/{{booking_id}}
  static String cancelBooking(int bookingId) => '/bookings/$bookingId';

  // بدء الدفع (API 10): {{base_url}}/bookings/{{booking_id}}/pay
  static String payBooking(int bookingId) => '/bookings/$bookingId/pay';
}
