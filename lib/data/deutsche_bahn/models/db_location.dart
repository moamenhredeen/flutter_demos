/// A stop, station, POI or address returned by the `/locations` endpoint
/// (and embedded in departures/journeys as `stop` / `origin` / `destination`).
class DbLocation {
  const DbLocation({
    required this.type,
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
    this.products = const {},
  });

  /// `stop`, `station`, `location` (POI) or `address`.
  final String type;

  /// Stop/station id. Null for raw address/POI locations.
  final String? id;

  final String name;

  final double? latitude;
  final double? longitude;

  /// Map of product key (e.g. `nationalExpress`, `regional`, `bus`) to whether
  /// that product serves this stop. Empty for non-stop locations.
  final Map<String, bool> products;

  factory DbLocation.fromJson(Map<String, dynamic> json) {
    // POI/address put coordinates at top level; stops nest them under
    // `location`.
    final loc = json['location'];
    final lat = (json['latitude'] as num?) ??
        (loc is Map ? loc['latitude'] as num? : null);
    final lng = (json['longitude'] as num?) ??
        (loc is Map ? loc['longitude'] as num? : null);

    final products = <String, bool>{};
    final rawProducts = json['products'];
    if (rawProducts is Map) {
      rawProducts.forEach((key, value) {
        if (value is bool) products[key.toString()] = value;
      });
    }

    return DbLocation(
      type: json['type'] as String? ?? 'location',
      id: json['id']?.toString(),
      name: json['name'] as String? ?? json['address'] as String? ?? '',
      latitude: lat?.toDouble(),
      longitude: lng?.toDouble(),
      products: products,
    );
  }
}
