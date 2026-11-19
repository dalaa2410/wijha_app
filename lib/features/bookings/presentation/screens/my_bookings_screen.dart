import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wijha_app/core/constants/app_colors.dart';
import 'package:wijha_app/core/di/injection.dart';
import 'package:wijha_app/core/widgets/app_bottom_nav.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../cubit/my_bookings_cubit.dart';
import '../widgets/booking_card.dart';
import 'booking_details_screen.dart';

/// حجوزاتي: القادمة (معلّقة ومدفوعة) والسابقة (ملغاة ومنتهية)
class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MyBookingsCubit(sl<BookingRepository>())..load(),
      child: const _MyBookingsView(),
    );
  }
}

class _MyBookingsView extends StatelessWidget {
  const _MyBookingsView();

  Future<void> _open(BuildContext context, Booking b) async {
    final cubit = context.read<MyBookingsCubit>();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookingDetailsScreen(booking: b)),
    );
    cubit.load(silent: true); // قد تغيّرت حالة الحجز (دفع أو إلغاء)
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: AppColors.primaryNavy,
          centerTitle: true,
          title: const Text(
            'حجوزاتي',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<MyBookingsCubit>().load(),
            ),
          ],
          bottom: const TabBar(
            labelColor: AppColors.primaryBlue,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primaryBlue,
            tabs: [
              Tab(text: 'القادمة'),
              Tab(text: 'السابقة'),
            ],
          ),
        ),
        body: BlocBuilder<MyBookingsCubit, MyBookingsState>(
          builder: (context, state) {
            switch (state.status) {
              case MyBookingsStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case MyBookingsStatus.failure:
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('تعذّر تحميل الحجوزات'),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => context.read<MyBookingsCubit>().load(),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                );
              case MyBookingsStatus.loaded:
                return TabBarView(
                  children: [
                    _BookingsList(
                      bookings: state.upcoming,
                      emptyTitle: 'لا توجد حجوزات قادمة',
                      emptyMessage: 'ابدأ باختيار رحلة من "استكشاف".',
                      onOpen: (b) => _open(context, b),
                    ),
                    _BookingsList(
                      bookings: state.past,
                      emptyTitle: 'لا توجد حجوزات سابقة',
                      emptyMessage: 'الحجوزات الملغاة والمنتهية تظهر هنا.',
                      onOpen: (b) => _open(context, b),
                    ),
                  ],
                );
            }
          },
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: 1,
          onSelect: (i) {
            if (i == 0) {
              // العودة إلى الشاشة الأولى (الرحلات)
              Navigator.popUntil(context, (route) => route.isFirst);
            } else if (i == 2) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(content: Text('قريبًا')));
            }
          },
        ),
      ),
    );
  }
}

class _BookingsList extends StatelessWidget {
  final List<Booking> bookings;
  final String emptyTitle;
  final String emptyMessage;
  final ValueChanged<Booking> onOpen;

  const _BookingsList({
    required this.bookings,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MyBookingsCubit>();

    return RefreshIndicator(
      onRefresh: () => cubit.load(silent: true),
      child: bookings.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.confirmation_number_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        emptyTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        emptyMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                for (final b in bookings)
                  BookingCard(
                    key: ValueKey('${b.id}-${b.status.name}'),
                    booking: b,
                    onTap: () => onOpen(b),
                    onExpired: () => cubit.load(silent: true),
                  ),
              ],
            ),
    );
  }
}
