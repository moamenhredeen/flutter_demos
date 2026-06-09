import 'package:flutter/material.dart';

/// Placeholder row shown while the page a row belongs to is still loading.
class BookTileSkeleton extends StatelessWidget {
  const BookTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget bar(double width) => Container(
          height: 12,
          width: width,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(4),
          ),
        );

    return ListTile(
      leading: Container(width: 40, height: 48, color: base),
      title: Align(alignment: Alignment.centerLeft, child: bar(180)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Align(alignment: Alignment.centerLeft, child: bar(110)),
      ),
    );
  }
}
