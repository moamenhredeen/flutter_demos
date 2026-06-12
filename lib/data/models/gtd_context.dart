class GtdContext {
  const GtdContext({
    required this.id,
    required this.name,
    required this.icon,
  });

  final int id;
  final String name;
  final String icon;

  factory GtdContext.fromJson(Map<String, dynamic> json) => GtdContext(
        id: json['id'] as int,
        name: json['name'] as String,
        icon: json['icon'] as String,
      );
}
