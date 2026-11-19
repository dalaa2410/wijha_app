import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wijha_app/core/constants/app_colors.dart';
import 'package:wijha_app/core/di/injection.dart';
import 'package:wijha_app/core/utils/date_formatter.dart';
import 'package:wijha_app/features/auth/presentation/screens/seat_map_screen.dart';
import 'package:wijha_app/features/bookings/presentation/screens/my_bookings_screen.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';
import '../cubit/trips_cubit.dart';
import '../widgets/trip_card.dart';

/// شاشة الرحلات. المعاملان اختياريان: عند تمرير المدينتين يظهر المسار في العنوان
/// ويُرسلان للباك كمرشحات (يمكن ربطهما بشاشة بحث لاحقًا).
class TripsScreen extends StatelessWidget {
  final String? origin;
  final String? destination;
  const TripsScreen({super.key, this.origin, this.destination});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TripsCubit(
        repository: sl<TripRepository>(),
        origin: origin,
        destination: destination,
      )..load(),
      child: _TripsView(origin: origin, destination: destination),
    );
  }
}

class _TripsView extends StatefulWidget {
  final String? origin;
  final String? destination;
  const _TripsView({this.origin, this.destination});

  @override
  State<_TripsView> createState() => _TripsViewState();
}

class _TripsViewState extends State<_TripsView> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  // عند الاقتراب من نهاية القائمة نجلب الصفحة التالية
  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      context.read<TripsCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, DateTime? current) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 90)),
      helpText: 'اختر يوم السفر',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
    );
    if (picked != null && context.mounted) {
      context.read<TripsCubit>().changeDate(picked);
    }
  }

  void _openSeats(BuildContext context, Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SeatMapScreen(tripId: trip.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasRoute = widget.origin != null && widget.destination != null;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primaryNavy,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasRoute
                  ? '${widget.origin} ← ${widget.destination}'
                  : 'الرحلات المتاحة',
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            Text(
              hasRoute ? 'ذهاب · خدمة مباشرة' : 'اختر رحلتك',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<TripsCubit>().load(),
          ),
        ],
      ),
      body: BlocBuilder<TripsCubit, TripsState>(
        builder: (context, state) {
          switch (state.status) {
            case TripsStatus.loading:
              return const _TripsSkeleton();
            case TripsStatus.failure:
              return _ErrorView(
                message: state.errorMessage ?? 'تعذّر تحميل الرحلات',
                onRetry: () => context.read<TripsCubit>().load(),
              );
            case TripsStatus.loaded:
              return _buildLoaded(context, state);
          }
        },
      ),
      bottomNavigationBar: const _BottomNav(),
    );
  }

  Widget _buildLoaded(BuildContext context, TripsState state) {
    final cubit = context.read<TripsCubit>();
    final trips = state.visibleTrips;

    return RefreshIndicator(
      onRefresh: () => cubit.load(silent: true),
      child: ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _DateBar(
            selected: state.selectedDate,
            onPick: () => _pickDate(context, state.selectedDate),
            onChange: cubit.changeDate,
          ),
          const SizedBox(height: 12),
          _FiltersRow(sort: state.sort, onSort: cubit.changeSort),
          const SizedBox(height: 14),
          _InfoRow(count: trips.length),
          const SizedBox(height: 12),
          if (trips.isEmpty)
            _EmptyView(
              hasDate: state.selectedDate != null,
              onShowAll: () => cubit.changeDate(null),
              onRefresh: () => cubit.load(),
            )
          else
            ...[
              for (var i = 0; i < trips.length; i++)
                TripCard(
                  trip: trips[i],
                  // أقرب رحلة موعدًا تُبرَز بإطار أزرق كما في التصميم
                  highlighted: i == 0 && state.sort == TripSort.time,
                  onTap: () => _openSeats(context, trips[i]),
                ),
            ],
          if (state.isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

String _tripsCountLabel(int n) {
  if (n == 0) return 'لا توجد رحلات';
  if (n == 1) return 'رحلة واحدة متاحة';
  if (n == 2) return 'رحلتان متاحتان';
  if (n <= 10) return '$n رحلات متاحة';
  return '$n رحلة متاحة';
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: Colors.grey.shade200),
);

// ───────────── شريط التاريخ ─────────────
class _DateBar extends StatelessWidget {
  final DateTime? selected;
  final VoidCallback onPick;
  final ValueChanged<DateTime?> onChange;

  const _DateBar({
    required this.selected,
    required this.onPick,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sel = selected;

    final VoidCallback? onPrev = (sel != null && sel.isAfter(today))
        ? () => onChange(sel.subtract(const Duration(days: 1)))
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          IconButton(
            tooltip: 'اليوم التالي',
            icon: const Icon(Icons.chevron_left),
            onPressed: () =>
                onChange(sel == null ? today : sel.add(const Duration(days: 1))),
          ),
          IconButton(
            tooltip: 'اليوم السابق',
            icon: const Icon(Icons.chevron_right),
            onPressed: onPrev,
          ),
          if (sel != null)
            IconButton(
              tooltip: 'كل الأيام',
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => onChange(null),
            ),
          Expanded(
            child: InkWell(
              onTap: onPick,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        sel == null ? 'كل الرحلات القادمة' : formatDayFull(sel),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────── صف الترتيب ─────────────
class _FiltersRow extends StatelessWidget {
  final TripSort sort;
  final ValueChanged<TripSort> onSort;
  const _FiltersRow({required this.sort, required this.onSort});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _FilterChip(
          label: 'السعر',
          icon: Icons.payments_outlined,
          selected: sort == TripSort.price,
          onTap: () => onSort(TripSort.price),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'وقت المغادرة',
          icon: Icons.schedule,
          selected: sort == TripSort.time,
          onTap: () => onSort(TripSort.time),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryBlue : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryBlue.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primaryBlue : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final int count;
  const _InfoRow({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'جميع الأوقات حسب التوقيت المحلي',
          style: TextStyle(fontSize: 11, color: AppColors.textLight),
        ),
        Text(
          _tripsCountLabel(count),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryNavy,
          ),
        ),
      ],
    );
  }
}

// ───────────── حالات: فارغ / خطأ / تحميل ─────────────
class _EmptyView extends StatelessWidget {
  final bool hasDate;
  final VoidCallback onShowAll;
  final VoidCallback onRefresh;

  const _EmptyView({
    required this.hasDate,
    required this.onShowAll,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        children: [
          Icon(
            Icons.directions_bus_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            'لا توجد رحلات متاحة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasDate
                ? 'لا توجد رحلات في هذا اليوم. جرّب يومًا آخر أو اعرض كل الرحلات.'
                : 'لا توجد رحلات قادمة حاليًا. حاول لاحقًا.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: hasDate ? onShowAll : onRefresh,
            child: Text(hasDate ? 'عرض كل الرحلات' : 'تحديث'),
          ),
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

class _TripsSkeleton extends StatelessWidget {
  const _TripsSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget box(double h) => Container(
      height: h,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
    );

    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [box(56), box(40), box(170), box(170), box(170)],
    );
  }
}

// ───────────── شريط التنقل السفلي (كما في التصميم) ─────────────
class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primaryBlue,
      unselectedItemColor: AppColors.textLight,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      onTap: (i) {
        if (i == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
          );
        } else if (i == 2) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('قريبًا')));
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'استكشاف'),
        BottomNavigationBarItem(
          icon: Icon(Icons.confirmation_number_outlined),
          label: 'حجوزاتي',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'الحساب',
        ),
      ],
    );
  }
}