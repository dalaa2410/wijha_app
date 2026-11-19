import 'package:flutter/material.dart';
import 'package:wijha_app/core/constants/app_colors.dart';

/// شريط التنقل السفلي المشترك (استكشاف / حجوزاتي / الحساب).
/// لا يعرف الشاشات: كل شاشة تمرر ما يحدث عند الاختيار (onSelect).
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primaryBlue,
      unselectedItemColor: AppColors.textLight,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      onTap: onSelect,
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
