import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'db_api_client.dart';
import 'db_repository.dart';

/// The [Dio] instance used by the Deutsche Bahn data layer.
final dbDioProvider = Provider<Dio>((ref) {
  final dio = DbApiClient.create();
  ref.onDispose(dio.close);
  return dio;
});

/// The Deutsche Bahn repository.
final dbRepositoryProvider = Provider<DbRepository>((ref) {
  return DbRepository(ref.watch(dbDioProvider));
});
