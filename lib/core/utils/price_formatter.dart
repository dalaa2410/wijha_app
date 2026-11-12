String formatPrice(int amount, String currency) {
  final grouped = amount.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => ',',
  );
  return '$grouped $currency';
}
