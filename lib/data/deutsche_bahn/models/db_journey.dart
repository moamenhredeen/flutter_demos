import 'db_line.dart';
import 'db_location.dart';

/// A journey option from `/journeys`: one or more [legs] from origin to
/// destination, optionally with a [price].
class DbJourney {
  const DbJourney({
    required this.legs,
    this.priceAmount,
    this.priceCurrency,
    this.refreshToken,
  });

  final List<DbLeg> legs;

  /// Cheapest ticket price, if `tickets`/price data was returned.
  final double? priceAmount;
  final String? priceCurrency;

  /// Token to refresh this journey via `/journeys/:ref`.
  final String? refreshToken;

  DateTime? get departure => legs.isEmpty ? null : legs.first.departure;
  DateTime? get arrival => legs.isEmpty ? null : legs.last.arrival;

  /// Number of transfers = legs that actually carry a line, minus one.
  int get transfers {
    final riding = legs.where((l) => !l.walking).length;
    return riding > 0 ? riding - 1 : 0;
  }

  factory DbJourney.fromJson(Map<String, dynamic> json) {
    final legsJson = json['legs'] as List? ?? const [];
    final price = json['price'];
    return DbJourney(
      legs: legsJson
          .map((e) => DbLeg.fromJson((e as Map).cast<String, dynamic>()))
          .toList(growable: false),
      priceAmount: price is Map ? (price['amount'] as num?)?.toDouble() : null,
      priceCurrency: price is Map ? price['currency'] as String? : null,
      refreshToken: json['refreshToken'] as String?,
    );
  }
}

/// A single leg of a [DbJourney].
class DbLeg {
  const DbLeg({
    this.origin,
    this.destination,
    this.departure,
    this.plannedDeparture,
    this.arrival,
    this.plannedArrival,
    this.line,
    this.direction,
    this.walking = false,
    this.cancelled = false,
  });

  final DbLocation? origin;
  final DbLocation? destination;

  final DateTime? departure;
  final DateTime? plannedDeparture;
  final DateTime? arrival;
  final DateTime? plannedArrival;

  /// Null for walking legs.
  final DbLine? line;
  final String? direction;

  /// True if this leg is a foot transfer rather than a ridden service.
  final bool walking;

  final bool cancelled;

  factory DbLeg.fromJson(Map<String, dynamic> json) {
    final origin = json['origin'];
    final dest = json['destination'];
    final line = json['line'];
    return DbLeg(
      origin: origin is Map
          ? DbLocation.fromJson(origin.cast<String, dynamic>())
          : null,
      destination:
          dest is Map ? DbLocation.fromJson(dest.cast<String, dynamic>()) : null,
      departure: _parseDate(json['departure']),
      plannedDeparture: _parseDate(json['plannedDeparture']),
      arrival: _parseDate(json['arrival']),
      plannedArrival: _parseDate(json['plannedArrival']),
      line: line is Map ? DbLine.fromJson(line.cast<String, dynamic>()) : null,
      direction: json['direction'] as String?,
      walking: json['walking'] as bool? ?? false,
      cancelled: json['cancelled'] as bool? ?? false,
    );
  }
}

DateTime? _parseDate(dynamic value) =>
    value is String ? DateTime.tryParse(value) : null;
