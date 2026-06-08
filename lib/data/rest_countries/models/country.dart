/// A country from the REST Countries API (https://restcountries.com/v3.1).
///
/// Only commonly useful fields are modelled. Because the API lets you request
/// a subset of fields, any field may be absent — parsing is defensive and most
/// fields are nullable / default to empty.
class Country {
  const Country({
    required this.commonName,
    this.officialName,
    this.cca2,
    this.cca3,
    this.capitals = const [],
    this.region,
    this.subregion,
    this.population,
    this.area,
    this.flagPng,
    this.flagSvg,
    this.flagAlt,
    this.latitude,
    this.longitude,
    this.currencies = const [],
    this.languages = const [],
    this.timezones = const [],
    this.borders = const [],
    this.googleMaps,
  });

  /// Common name, e.g. `Germany`.
  final String commonName;

  /// Official name, e.g. `Federal Republic of Germany`.
  final String? officialName;

  /// ISO 3166-1 alpha-2 code, e.g. `DE`.
  final String? cca2;

  /// ISO 3166-1 alpha-3 code, e.g. `DEU`.
  final String? cca3;

  final List<String> capitals;

  final String? region;
  final String? subregion;

  final int? population;
  final double? area;

  final String? flagPng;
  final String? flagSvg;
  final String? flagAlt;

  final double? latitude;
  final double? longitude;

  final List<CountryCurrency> currencies;

  /// Language names, e.g. `['German']`.
  final List<String> languages;

  final List<String> timezones;

  /// Neighbouring countries by cca3 code. Resolve via
  /// `RestCountriesRepository.byCodes`.
  final List<String> borders;

  final String? googleMaps;

  factory Country.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final flags = json['flags'];
    final latlng = json['latlng'];
    final maps = json['maps'];

    return Country(
      commonName: name is Map ? name['common'] as String? ?? '' : '',
      officialName: name is Map ? name['official'] as String? : null,
      cca2: json['cca2'] as String?,
      cca3: json['cca3'] as String?,
      capitals: _stringList(json['capital']),
      region: json['region'] as String?,
      subregion: json['subregion'] as String?,
      population: (json['population'] as num?)?.toInt(),
      area: (json['area'] as num?)?.toDouble(),
      flagPng: flags is Map ? flags['png'] as String? : null,
      flagSvg: flags is Map ? flags['svg'] as String? : null,
      flagAlt: flags is Map ? flags['alt'] as String? : null,
      latitude: latlng is List && latlng.isNotEmpty
          ? (latlng[0] as num?)?.toDouble()
          : null,
      longitude: latlng is List && latlng.length > 1
          ? (latlng[1] as num?)?.toDouble()
          : null,
      currencies: _currencies(json['currencies']),
      languages: json['languages'] is Map
          ? (json['languages'] as Map).values.map((e) => e.toString()).toList()
          : const [],
      timezones: _stringList(json['timezones']),
      borders: _stringList(json['borders']),
      googleMaps: maps is Map ? maps['googleMaps'] as String? : null,
    );
  }
}

/// A currency entry, e.g. `{ code: EUR, name: Euro, symbol: € }`.
class CountryCurrency {
  const CountryCurrency({required this.code, this.name, this.symbol});

  final String code;
  final String? name;
  final String? symbol;
}

List<CountryCurrency> _currencies(dynamic value) {
  if (value is! Map) return const [];
  return value.entries
      .map((e) {
        final v = e.value;
        return CountryCurrency(
          code: e.key.toString(),
          name: v is Map ? v['name'] as String? : null,
          symbol: v is Map ? v['symbol'] as String? : null,
        );
      })
      .toList(growable: false);
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList(growable: false);
  }
  return const [];
}
