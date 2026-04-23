/// Generic wrapper for Laravel's paginator response:
///
///   {
///     "data": [ ... ],
///     "links": { "first": "...", "last": "...", "prev": null, "next": "..." },
///     "meta":  { "current_page": 1, "last_page": 10, "per_page": 15,
///                "total": 142, "from": 1, "to": 15, "path": "..." }
///   }
///
/// Usage:
///   final page = Paginated<MarkModel>.fromJson(
///     json,
///     itemFromJson: MarkModel.fromJson,
///   );
///
///   page.items     // List<MarkModel>
///   page.hasNext   // bool
///   page.nextPage  // int?
class Paginated<T> {
  final List<T> items;

  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int? from;
  final int? to;

  final String? nextUrl;
  final String? prevUrl;

  const Paginated({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.from,
    this.to,
    this.nextUrl,
    this.prevUrl,
  });

  bool get hasNext => currentPage < lastPage;
  bool get hasPrev => currentPage > 1;
  int? get nextPage => hasNext ? currentPage + 1 : null;
  int? get prevPage => hasPrev ? currentPage - 1 : null;
  bool get isEmpty => items.isEmpty;

  factory Paginated.fromJson(
    Map<String, dynamic> json, {
    required T Function(Map<String, dynamic>) itemFromJson,
  }) {
    final rawData = (json['data'] as List? ?? const []);
    final items = rawData
        .whereType<Map<String, dynamic>>()
        .map(itemFromJson)
        .toList();

    // Laravel sometimes nests meta/links, sometimes flattens them onto the
    // top level (e.g. simplePaginate). Handle both.
    final meta  = _asMap(json['meta'])  ?? json;
    final links = _asMap(json['links']);

    int intOf(dynamic v, [int fallback = 0]) =>
        v is int ? v : (v is String ? int.tryParse(v) ?? fallback : fallback);

    return Paginated<T>(
      items:       items,
      currentPage: intOf(meta['current_page'], 1),
      lastPage:    intOf(meta['last_page'], 1),
      perPage:     intOf(meta['per_page'], items.length),
      total:       intOf(meta['total'], items.length),
      from:        meta['from']  is int ? meta['from']  as int : null,
      to:          meta['to']    is int ? meta['to']    as int : null,
      nextUrl:     links?['next'] as String?,
      prevUrl:     links?['prev'] as String?,
    );
  }

  /// Empty page (e.g. before the first load).
  factory Paginated.empty() => Paginated<T>(
        items: const [],
        currentPage: 1,
        lastPage: 1,
        perPage: 0,
        total: 0,
      );

  /// Append the next page's items onto this page (for infinite scroll).
  Paginated<T> appendPage(Paginated<T> next) => Paginated<T>(
        items: [...items, ...next.items],
        currentPage: next.currentPage,
        lastPage:    next.lastPage,
        perPage:     next.perPage,
        total:       next.total,
        from:        from ?? next.from,
        to:          next.to,
        nextUrl:     next.nextUrl,
        prevUrl:     next.prevUrl,
      );

  static Map<String, dynamic>? _asMap(dynamic v) =>
      v is Map<String, dynamic> ? v : null;
}
