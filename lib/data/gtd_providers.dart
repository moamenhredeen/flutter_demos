import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'gtd_api_client.dart';
import 'gtd_repository.dart';

final gtdDioProvider = Provider<Dio>((ref) {
  final dio = GtdApiClient.create();
  ref.onDispose(dio.close);
  return dio;
});

final gtdRepositoryProvider = Provider<GtdRepository>((ref) {
  return GtdRepository(ref.watch(gtdDioProvider));
});
