class GtdCursorPage<T> {
  const GtdCursorPage({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final List<T> items;
  final bool hasMore;
  final String? nextCursor;

  factory GtdCursorPage.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) =>
      GtdCursorPage(
        items: (json['items'] as List)
            .map((e) => fromJsonT(e as Map<String, dynamic>))
            .toList(),
        hasMore: json['has_more'] as bool,
        nextCursor: json['next_cursor'] as String?,
      );
}
