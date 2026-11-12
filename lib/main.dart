import 'package:flutter/material.dart';
import 'package:wijha_app/core/constants/app_colors.dart';
import 'package:wijha_app/core/di/injection.dart';
import 'package:wijha_app/features/auth/presentation/screens/welcome_screen.dart';

void main() {
  // لازم قبل أي شيء يستخدم المكوّنات الأصلية (مثل التخزين الآمن للـ Token)
  WidgetsFlutterBinding.ensureInitialized();

  // تسجيل الكائنات المشتركة (Dio و ApiClient و Repositories) مرة واحدة
  setupDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wijha',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryBlue),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const WelcomeScreen(),
    );
  }
}
