class GtdOffsetPage<T> {
  const GtdOffsetPage({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
    required this.pages,
  });

  final List<T> items;
  final int total;
  final int page;
  final int perPage;
  final int pages;

  factory GtdOffsetPage.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) =>
      GtdOffsetPage(
        items: (json['items'] as List)
            .map((e) => fromJsonT(e as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int,
        page: json['page'] as int,
        perPage: json['per_page'] as int,
        pages: json['pages'] as int,
      );
}
