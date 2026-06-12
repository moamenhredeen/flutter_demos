class GtdArea {
  const GtdArea({required this.id, required this.name});

  final int id;
  final String name;

  factory GtdArea.fromJson(Map<String, dynamic> json) => GtdArea(
        id: json['id'] as int,
        name: json['name'] as String,
      );
}
