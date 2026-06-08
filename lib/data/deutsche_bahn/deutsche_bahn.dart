/// Deutsche Bahn REST API data layer (db-rest, v5.db.api.bahn.guru).
///
/// See https://v5.db.api.bahn.guru/api.html.
library;

// Re-exported so consumers can drive cancellation without a direct dio import.
export 'package:dio/dio.dart' show CancelToken, DioException, DioExceptionType;

export 'db_api_client.dart';
export 'db_exception.dart';
export 'db_providers.dart';
export 'db_repository.dart';
export 'models/db_journey.dart';
export 'models/db_line.dart';
export 'models/db_location.dart';
export 'models/db_station_board_entry.dart';
