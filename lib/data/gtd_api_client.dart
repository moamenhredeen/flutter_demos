import 'package:dio/dio.dart';

class GtdApiClient {
  // 10.0.2.2 routes to host machine from Android emulator; use localhost for web/desktop
  static const baseUrl = 'http://10.0.2.2:5000';

  static Dio create() => Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          responseType: ResponseType.json,
        ),
      );
}
