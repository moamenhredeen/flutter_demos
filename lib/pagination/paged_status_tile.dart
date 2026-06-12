import 'package:flutter/material.dart';

/// Footer tile of a paged list — also the load-more TRIGGER.
///
/// Mounting it IS the "end reached" signal: builder delegates only build
/// children near the viewport (+ cacheExtent), so this tile is created
/// exactly when the user approaches the end. That gives threshold prefetch
/// for free (tune via the scroll view's `cacheExtent`), and it works for
/// lists shorter than one screen: the tile builds immediately, so loadMore
/// chains until the viewport fills or `hasMore` turns false.
class PagedStatusTile extends StatefulWidget {
  const PagedStatusTile({
    super.key,
    required this.hasMore,
    required this.isLoadingMore,
    required this.error,
    required this.onLoadMore,
    required this.onRetry,
  });

  final bool hasMore;
  final bool isLoadingMore;
  final Object? error;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;

  @override
  State<PagedStatusTile> createState() => _PagedStatusTileState();
}

class _PagedStatusTileState extends State<PagedStatusTile> {
  @override
  void initState() {
    super.initState();
    _requestMore();
  }

  @override
  void didUpdateWidget(PagedStatusTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A successful append normally shifts this tile to a higher index, so a
    // NEW element re-triggers via initState. This covers the stall case
    // where the element survives because itemCount didn't change: an empty
    // page (or fully deduped page) that still reports hasMore == true.
    if (oldWidget.isLoadingMore && !widget.isLoadingMore) _requestMore();
  }

  void _requestMore() {
    if (!widget.hasMore || widget.error != null) return;
    // Defer past the current build — mutating a provider mid-build is
    // forbidden. The notifier dedupes, so over-firing is harmless.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onLoadMore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.error;
    if (error != null) {
      // LOAD-MORE error: one tile at the end of an otherwise healthy list,
      // with the single Retry button. Distinct from the first-load error,
      // which owns the whole screen (see the screen widget).
      return ListTile(
        leading: Icon(
          Icons.error_outline,
          color: Theme.of(context).colorScheme.error,
        ),
        title: const Text("Couldn't load more"),
        subtitle: Text('$error', maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: FilledButton(
          onPressed: widget.onRetry,
          child: const Text('Retry'),
        ),
      );
    }
    if (widget.hasMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          "You're all caught up",
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
