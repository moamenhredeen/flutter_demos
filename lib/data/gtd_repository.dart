import 'package:dio/dio.dart';

import 'gtd_exception.dart';
import 'models/gtd_area.dart';
import 'models/gtd_context.dart';
import 'models/gtd_cursor_page.dart';
import 'models/gtd_offset_page.dart';
import 'models/gtd_project.dart';
import 'models/gtd_task.dart';

class GtdRepository {
  const GtdRepository(this._dio);

  final Dio _dio;

  // ── Tasks — offset pagination ─────────────────────────────────────────────

  Future<GtdOffsetPage<GtdTask>> getTasks({
    int page = 1,
    int perPage = 20,
    GtdTaskStatus? status,
    GtdEnergy? energy,
    int? projectId,
    int? contextId,
    int? areaId,
    CancelToken? cancelToken,
  }) =>
      _get(
        '/tasks',
        queryParameters: {
          'page': page,
          'per_page': perPage,
          'status': ?status?.toJson(),
          'energy': ?energy?.toJson(),
          'project_id': ?projectId,
          'context_id': ?contextId,
          'area_id': ?areaId,
        },
        cancelToken: cancelToken,
        parse: (json) => GtdOffsetPage.fromJson(json, GtdTask.fromJson),
      );

  // ── Tasks — cursor pagination ─────────────────────────────────────────────

  Future<GtdCursorPage<GtdTask>> getTasksCursor({
    int limit = 20,
    String? cursor,
    GtdTaskStatus? status,
    GtdEnergy? energy,
    int? contextId,
    int? areaId,
    CancelToken? cancelToken,
  }) =>
      _get(
        '/tasks/cursor',
        queryParameters: {
          'limit': limit,
          'cursor': ?cursor,
          'status': ?status?.toJson(),
          'energy': ?energy?.toJson(),
          'context_id': ?contextId,
          'area_id': ?areaId,
        },
        cancelToken: cancelToken,
        parse: (json) => GtdCursorPage.fromJson(json, GtdTask.fromJson),
      );

  // ── Task by ID ────────────────────────────────────────────────────────────

  Future<GtdTask> getTaskById(int id, {CancelToken? cancelToken}) =>
      _get('/tasks/$id', cancelToken: cancelToken, parse: GtdTask.fromJson);

  // ── Projects ──────────────────────────────────────────────────────────────

  Future<List<GtdProject>> getProjects({CancelToken? cancelToken}) =>
      _getList('/projects', cancelToken: cancelToken, parse: GtdProject.fromJson);

  Future<GtdOffsetPage<GtdTask>> getProjectTasks(
    int projectId, {
    int page = 1,
    int perPage = 20,
    GtdTaskStatus? status,
    CancelToken? cancelToken,
  }) =>
      _get(
        '/projects/$projectId/tasks',
        queryParameters: {
          'page': page,
          'per_page': perPage,
          if (status != null) 'status': status.toJson(),
        },
        cancelToken: cancelToken,
        parse: (json) => GtdOffsetPage.fromJson(json, GtdTask.fromJson),
      );

  // ── Contexts ──────────────────────────────────────────────────────────────

  Future<List<GtdContext>> getContexts({CancelToken? cancelToken}) =>
      _getList('/contexts', cancelToken: cancelToken, parse: GtdContext.fromJson);

  // ── Areas ─────────────────────────────────────────────────────────────────

  Future<List<GtdArea>> getAreas({CancelToken? cancelToken}) =>
      _getList('/areas', cancelToken: cancelToken, parse: GtdArea.fromJson);

  // ── Internals ─────────────────────────────────────────────────────────────

  Future<T> _get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required CancelToken? cancelToken,
    required T Function(Map<String, dynamic>) parse,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data == null) throw const GtdException('Empty response');
      return parse(data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) rethrow;
      throw GtdException(
        e.message ?? 'Request failed',
        statusCode: e.response?.statusCode,
        cause: e,
      );
    }
  }

  Future<List<T>> _getList<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required CancelToken? cancelToken,
    required T Function(Map<String, dynamic>) parse,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data == null) throw const GtdException('Empty response');
      return data.map((e) => parse(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) rethrow;
      throw GtdException(
        e.message ?? 'Request failed',
        statusCode: e.response?.statusCode,
        cause: e,
      );
    }
  }
}
