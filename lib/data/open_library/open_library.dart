/// Open Library REST API data layer.
///
/// See https://openlibrary.org/developers/api.
library;

// Re-exported so consumers can drive cancellation without a direct dio import.
export 'package:dio/dio.dart' show CancelToken, DioException, DioExceptionType;

export 'models/open_library_author.dart';
export 'models/open_library_doc.dart';
export 'models/open_library_search_response.dart';
export 'models/open_library_work.dart';
export 'open_library_api_client.dart';
export 'open_library_covers.dart';
export 'open_library_exception.dart';
export 'open_library_providers.dart';
export 'open_library_repository.dart';
