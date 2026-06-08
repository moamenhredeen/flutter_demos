/// REST Countries API data layer (https://restcountries.com/v3.1).
library;

// Re-exported so consumers can drive cancellation without a direct dio import.
export 'package:dio/dio.dart' show CancelToken, DioException, DioExceptionType;

export 'models/country.dart';
export 'rest_countries_api_client.dart';
export 'rest_countries_exception.dart';
export 'rest_countries_providers.dart';
export 'rest_countries_repository.dart';
