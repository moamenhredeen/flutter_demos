/// A transport line / service, e.g. `ICE 599`, `S 1`, `Bus 100`.
class DbLine {
  const DbLine({
    required this.name,
    this.product,
    this.mode,
    this.operatorName,
  });

  /// Display name, e.g. `ICE 599`.
  final String name;

  /// Product key, e.g. `nationalExpress`, `regional`, `suburban`, `bus`.
  final String? product;

  /// Coarse mode, e.g. `train`, `bus`, `watercraft`.
  final String? mode;

  final String? operatorName;

  factory DbLine.fromJson(Map<String, dynamic> json) {
    final op = json['operator'];
    return DbLine(
      name: json['name'] as String? ?? '',
      product: json['product'] as String?,
      mode: json['mode'] as String?,
      operatorName: op is Map ? op['name'] as String? : null,
    );
  }
}
