import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_interceptor.dart';

class DioClient {
  static const String baseUrl = 'https://jsonplaceholder.typicode.com';
  late final Dio dio;

  DioClient({Dio? customDio}) {
    dio = customDio ??
        Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );

    dio.interceptors.add(ApiInterceptor());

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: false,
          responseHeader: false,
        ),
      );
    }
  }
}