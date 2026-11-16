import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wijha_app/core/constants/app_colors.dart';
import 'package:wijha_app/core/di/injection.dart';
import 'package:wijha_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:wijha_app/features/auth/presentation/cubit/login_cubit.dart';
import 'package:wijha_app/features/auth/presentation/cubit/request_state.dart';
import 'package:wijha_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:wijha_app/features/auth/presentation/screens/register_screen.dart'; // <-- تم الاستيراد هنا
import 'package:wijha_app/features/auth/presentation/screens/seat_map_screen.dart';
import 'package:wijha_app/features/trips/presentation/screens/trips_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  OutlineInputBorder _border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginCubit(sl<AuthRepository>()),
      child: BlocConsumer<LoginCubit, RequestState>(
        listener: (context, state) {
          if (state.status == RequestStatus.success) {
            // الانتقال إلى شاشة الرحلات كأول صفحة بعد تسجيل الدخول
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const TripsScreen()),
              (route) => false,
            );
          } else if (state.status == RequestStatus.failure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message ?? 'حدث خطأ غير متوقع'),
                  backgroundColor: AppColors.error,
                ),
              );
          }
        },
        builder: (context, state) {
          final isLoading = state.status == RequestStatus.loading;

          return Scaffold(
            backgroundColor: Colors.white,
            body: SingleChildScrollView(
              child: Column(
                children: [
                  // ───────────── الرأس المتدرج ─────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(
                      top: 50,
                      bottom: 28,
                      left: 20,
                      right: 20,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryNavy,
                          AppColors.primaryNavy,
                          AppColors.primaryBlue,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const Text(
                              'تسجيل الدخول',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 40),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 55,
                              height: 55,
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Wijha',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'أهلاً بعودتك',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'سجِّل دخولك لحجز رحلتك القادمة وتصفُّح جميع تذاكرك في مكان واحد.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ───────────── النموذج ─────────────
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 10),

                          // البريد الإلكتروني
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'البريد الإلكتروني',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            enabled: !isLoading,
                            textAlign: TextAlign.right,
                            keyboardType: TextInputType.emailAddress,
                            textCapitalization: TextCapitalization.none,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'الرجاء إدخال البريد الإلكتروني';
                              }
                              final emailRegex = RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              );
                              if (!emailRegex.hasMatch(value.trim())) {
                                return 'الرجاء إدخال بريد إلكتروني صحيح (مثل: name@example.com)';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: 'أدخل بريدك الإلكتروني',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                              suffixIcon: Icon(
                                Icons.email_outlined,
                                color: Colors.grey.shade500,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              border: _border(Colors.grey.shade200),
                              enabledBorder: _border(Colors.grey.shade200),
                              focusedBorder: _border(
                                AppColors.primaryBlue,
                                1.5,
                              ),
                              errorBorder: _border(AppColors.error),
                              focusedErrorBorder: _border(AppColors.error, 1.5),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // كلمة المرور
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'كلمة المرور',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            enabled: !isLoading,
                            textAlign: TextAlign.right,
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'الرجاء إدخال كلمة المرور';
                              }
                              if (value.length < 6) {
                                return 'كلمة المرور يجب ألا تقل عن 6 أحرف';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: 'أدخل كلمة المرور',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                              suffixIcon: Icon(
                                Icons.lock_outline,
                                color: Colors.grey.shade500,
                              ),
                              prefixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.grey.shade500,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              border: _border(Colors.grey.shade200),
                              enabledBorder: _border(Colors.grey.shade200),
                              focusedBorder: _border(
                                AppColors.primaryBlue,
                                1.5,
                              ),
                              errorBorder: _border(AppColors.error),
                              focusedErrorBorder: _border(AppColors.error, 1.5),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // نسيت كلمة المرور؟
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ForgotPasswordScreen(),
                                        ),
                                      );
                                    },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text(
                                'نسيت كلمة المرور؟',
                                style: TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // زر تسجيل الدخول
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                disabledBackgroundColor: AppColors.primaryBlue
                                    .withValues(alpha: 0.6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                              ),
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        context.read<LoginCubit>().login(
                                          _emailController.text.trim(),
                                          _passwordController.text,
                                        );
                                      }
                                    },
                              child: isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(
                                          Icons.arrow_back,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'تسجيل الدخول',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // حسابك محفوظ وآمن دائماً
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'حسابك محفوظ وآمن دائماً',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),

                          // الفاصل (أو)
                          Row(
                            children: [
                              Expanded(
                                child: Divider(color: Colors.grey.shade300),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                ),
                                child: Text(
                                  'أو',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(color: Colors.grey.shade300),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // إنشاء حساب جديد
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'لست مشتركاً بعد؟ ',
                                style: TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 13,
                                ),
                              ),
                              GestureDetector(
                                onTap: isLoading
                                    ? null
                                    : () {
                                        // الانتقال الفعلي لشاشة إنشاء الحساب
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const RegisterScreen(),
                                          ),
                                        );
                                      },
                                child: const Text(
                                  'إنشاء حساب جديد',
                                  style: TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // شروط الخدمة وسياسة الخصوصية
                          Center(
                            child: Text.rich(
                              TextSpan(
                                text: 'بالمتابعة، فإنك توافق على ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                                children: const [
                                  TextSpan(
                                    text: 'شروط الخدمة',
                                    style: TextStyle(
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                  TextSpan(text: ' و'),
                                  TextSpan(
                                    text: 'سياسة الخصوصية',
                                    style: TextStyle(
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                  TextSpan(text: '.'),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
