import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'rest_countries_api_client.dart';
import 'rest_countries_repository.dart';

/// The [Dio] instance used by the REST Countries data layer.
final restCountriesDioProvider = Provider<Dio>((ref) {
  final dio = RestCountriesApiClient.create();
  ref.onDispose(dio.close);
  return dio;
});

/// The REST Countries repository.
final restCountriesRepositoryProvider = Provider<RestCountriesRepository>((ref) {
  return RestCountriesRepository(ref.watch(restCountriesDioProvider));
});
