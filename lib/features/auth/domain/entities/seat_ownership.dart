// علاقة المستخدم بالمقعد غير المتاح
enum SeatOwnership {
  none, // محجوز لدى غيره
  mineHeld, // حجزه المستخدم ولم يدفع بعد
  mineConfirmed, // حجزه ودفع ثمنه
}
