class AppConfig {
  // يُغيَّر عند التشغيل دون تعديل الكود:
  // flutter run --dart-define=API_BASE_URL=https://xxxx.ngrok-free.dev/api
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://strength-linked-always.ngrok-free.dev/api',
  );
}