import 'db_line.dart';
import 'db_location.dart';

/// One row of a departures or arrivals board
/// (`/stops/:id/departures`, `/stops/:id/arrivals`).
class DbStationBoardEntry {
  const DbStationBoardEntry({
    this.tripId,
    this.line,
    this.direction,
    this.provenance,
    this.when,
    this.plannedWhen,
    this.delaySeconds,
    this.platform,
    this.plannedPlatform,
    this.stop,
    this.cancelled = false,
  });

  final String? tripId;

  final DbLine? line;

  /// Where the service is heading (departures board).
  final String? direction;

  /// Where the service came from (arrivals board).
  final String? provenance;

  /// Real-time timestamp; null if cancelled or unknown.
  final DateTime? when;

  /// Scheduled timestamp.
  final DateTime? plannedWhen;

  /// Delay vs. plan in seconds (can be negative). Null if unknown.
  final int? delaySeconds;

  final String? platform;
  final String? plannedPlatform;

  /// The stop this board belongs to (echoed by the API).
  final DbLocation? stop;

  final bool cancelled;

  Duration? get delay =>
      delaySeconds == null ? null : Duration(seconds: delaySeconds!);

  factory DbStationBoardEntry.fromJson(Map<String, dynamic> json) {
    final line = json['line'];
    final stop = json['stop'];
    return DbStationBoardEntry(
      tripId: json['tripId'] as String?,
      line: line is Map ? DbLine.fromJson(line.cast<String, dynamic>()) : null,
      direction: json['direction'] as String?,
      provenance: json['provenance'] as String?,
      when: _parseDate(json['when']),
      plannedWhen: _parseDate(json['plannedWhen']),
      delaySeconds: (json['delay'] as num?)?.toInt(),
      platform: json['platform'] as String?,
      plannedPlatform: json['plannedPlatform'] as String?,
      stop: stop is Map ? DbLocation.fromJson(stop.cast<String, dynamic>()) : null,
      cancelled: json['cancelled'] as bool? ?? false,
    );
  }
}

/// A departures-board row. Use [DbStationBoardEntry.direction].
typedef DbDeparture = DbStationBoardEntry;

/// An arrivals-board row. Use [DbStationBoardEntry.provenance].
typedef DbArrival = DbStationBoardEntry;

DateTime? _parseDate(dynamic value) =>
    value is String ? DateTime.tryParse(value) : null;
