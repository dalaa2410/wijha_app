import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wijha_app/core/constants/app_colors.dart';
import 'package:wijha_app/core/di/injection.dart';
import 'package:wijha_app/core/utils/price_formatter.dart';
import 'package:wijha_app/features/bookings/domain/entities/booking.dart';
import 'package:wijha_app/features/bookings/domain/repositories/booking_repository.dart';
import 'package:wijha_app/features/bookings/presentation/screens/booking_details_screen.dart';
import 'package:wijha_app/features/bookings/presentation/widgets/hold_banner.dart';
import '../../domain/repositories/seat_repository.dart';
import '../cubit/seat_selection_cubit.dart';
import '../widgets/bus_seat_grid.dart';

class SeatMapScreen extends StatelessWidget {
  final int tripId;
  const SeatMapScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SeatSelectionCubit(
        repository: sl<SeatRepository>(),
        bookingRepository: sl<BookingRepository>(),
        tripId: tripId,
      )..loadSeats(),
      child: const _SeatMapView(),
    );
  }
}

// يفتح تفاصيل الحجز، وعند العودة (دفع أو إلغاء أو انتهاء) نحدّث الخريطة
// فتتحول المقاعد الصفراء إلى خضراء بعد الدفع
Future<void> _openBooking(BuildContext context, Booking booking) async {
  final cubit = context.read<SeatSelectionCubit>();
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => BookingDetailsScreen(booking: booking)),
  );
  if (!cubit.isClosed) cubit.refresh();
}

class _SeatMapView extends StatelessWidget {
  const _SeatMapView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primaryNavy,
        centerTitle: true,
        title: const Text(
          'اختر مقاعدك',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'تحديث المقاعد',
            icon: const Icon(Icons.refresh),
            // يمسح الاختيار ويجلب الخريطة من جديد
            onPressed: () => context.read<SeatSelectionCubit>().refresh(),
          ),
        ],
      ),
      body: BlocListener<SeatSelectionCubit, SeatSelectionState>(
        listenWhen: (prev, curr) =>
            (curr.message != null && prev.message != curr.message) ||
            (curr.createdBooking != null &&
                prev.createdBooking != curr.createdBooking),
        listener: (context, state) {
          final booking = state.createdBooking;
          if (booking != null) {
            // الحجز المؤقت نجح: ننتقل إلى تفاصيل الحجز (دفع/إلغاء)
            _openBooking(context, booking);
          } else if (state.message != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message!)));
          }
        },
        child: BlocBuilder<SeatSelectionCubit, SeatSelectionState>(
          builder: (context, state) => switch (state.status) {
            SeatMapStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            SeatMapStatus.failure => _ErrorView(
              message: state.errorMessage ?? 'تعذّر تحميل المقاعد',
              onRetry: () => context.read<SeatSelectionCubit>().loadSeats(),
            ),
            SeatMapStatus.loaded => _LoadedView(state: state),
          },
        ),
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  final SeatSelectionState state;
  const _LoadedView({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SeatSelectionCubit>();
    final map = state.seatMap!;
    final seatNumbers = state.selectedSeats.map((s) => s.number).join('، ');
    final hold = state.activeHold;

    return Column(
      children: [
        // حجز معلّق لهذه الرحلة ما دامت مهلته لم تنتهِ: زر للعودة إلى تفاصيله
        if (hold != null && !hold.isHoldExpired)
          HoldBanner(
            key: ValueKey('hold-${hold.id}'),
            booking: hold,
            onTap: () => _openBooking(context, hold),
            onExpired: cubit.refreshHold,
          ),
        const _Legend(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'حافلة ${map.busNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Icon(Icons.person_outline, color: Colors.grey.shade600),
                    ],
                  ),
                  Divider(color: Colors.grey.shade300),
                  const SizedBox(height: 6),
                  BusSeatGrid(
                    seatMap: map,
                    selectedIds: state.selectedIds,
                    mySeats: state.mySeats,
                    onSeatTap: cubit.toggleSeat,
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      state.selectedIds.isEmpty
                          ? 'لم تختر أي مقعد'
                          : 'المقاعد: $seatNumbers',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      formatPrice(state.totalPrice, map.currency),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      disabledBackgroundColor: AppColors.primaryBlue.withValues(
                        alpha: 0.4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: state.selectedIds.isEmpty || state.isSubmitting
                        ? null
                        : cubit.reserveSelected,
                    child: state.isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'المتابعة إلى الدفع',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(
      Color color,
      IconData? icon,
      String label, {
      Color iconColor = Colors.white,
    }) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
          child: icon == null ? null : Icon(icon, size: 12, color: iconColor),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Wrap(
        spacing: 14,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          item(const Color(0xFFE2E8F0), null, 'متاح'),
          item(AppColors.primaryBlue, Icons.check, 'مختار'),
          item(
            const Color(0xFFFACC15),
            Icons.schedule,
            'محجوز لك (بانتظار الدفع)',
            iconColor: const Color(0xFF713F12),
          ),
          item(AppColors.successGreen, Icons.verified_user_outlined, 'مدفوع'),
          item(const Color(0xFF94A3B8), Icons.lock_outline, 'محجوز لغيرك'),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
