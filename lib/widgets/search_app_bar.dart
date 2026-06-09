import 'package:flutter/material.dart';

/// An app bar whose title is a search field, styled like Flutter's
/// [SearchDelegate]: a back-arrow leading, an inline borderless [TextField],
/// and a clear action that appears once there's text.
class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SearchAppBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.onSubmitted,
    this.onBack,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Called by the leading back button. Defaults to popping the route.
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      leading: BackButton(onPressed: onBack),
      titleSpacing: 0,
      title: TextField(
        controller: controller,
        autofocus: true,
        textInputAction: TextInputAction.search,
        style: theme.textTheme.titleMedium,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
        ),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      ),
      // Rebuild the clear action as the text changes.
      actions: [
        ValueListenableBuilder(
          valueListenable: controller,
          builder: (context, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              tooltip: 'Clear',
              icon: const Icon(Icons.close),
              onPressed: () {
                controller.clear();
                onChanged('');
              },
            );
          },
        ),
      ],
    );
  }
}
