import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'open_library_api_client.dart';
import 'open_library_repository.dart';

/// The [Dio] instance used by the Open Library data layer.
final openLibraryDioProvider = Provider<Dio>((ref) {
  final dio = OpenLibraryApiClient.create();
  ref.onDispose(dio.close);
  return dio;
});

/// The Open Library repository.
final openLibraryRepositoryProvider = Provider<OpenLibraryRepository>((ref) {
  return OpenLibraryRepository(ref.watch(openLibraryDioProvider));
});
