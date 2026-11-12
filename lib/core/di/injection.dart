import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:wijha_app/core/config/app_config.dart';
import 'package:wijha_app/core/network/api_client.dart';
import 'package:wijha_app/core/network/auth_interceptor.dart';
import 'package:wijha_app/core/network/token_storage.dart';
import 'package:wijha_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:wijha_app/features/auth/data/datasources/seat_data_source.dart';
import 'package:wijha_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:wijha_app/features/auth/data/repositories/seat_repository_impl.dart';
import 'package:wijha_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:wijha_app/features/auth/domain/repositories/seat_repository.dart';

final sl = GetIt.instance; // service locator: مخزن مركزي للكائنات المشتركة

void setupDependencies() {
  sl.registerLazySingleton(() => TokenStorage());

  sl.registerLazySingleton(() {
    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
    ));
    dio.interceptors.add(AuthInterceptor(sl<TokenStorage>()));
    if (kDebugMode) {
      // requestHeader: false حتى لا يُطبع الـ Token في السجل
      dio.interceptors.add(LogInterceptor(
        requestHeader: false,
        requestBody: true,
        responseBody: true,
      ));
    }
    return ApiClient(dio);
  });

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(AuthRemoteDataSource(sl<ApiClient>()), sl<TokenStorage>()),
  );
  sl.registerLazySingleton<SeatRepository>(
    () => SeatRepositoryImpl(SeatRemoteDataSource(sl<ApiClient>())),
  );
  
}