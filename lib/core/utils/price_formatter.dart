String formatPrice(num amount, [String currency = 'SYP']) {
  final intVal = amount.round();
  final formatted = intVal.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );
  final unit = currency.toUpperCase() == 'SYP' ? 'ل.س' : currency;
  return '$formatted $unit';
}
