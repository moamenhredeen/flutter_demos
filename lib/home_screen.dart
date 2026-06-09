import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A single demo entry shown on the home page.
class _DemoLink {
  const _DemoLink({
    required this.label,
    required this.route,
    required this.icon,
    this.subtitle,
  });

  final String label;
  final String route;
  final IconData icon;
  final String? subtitle;
}

/// A titled group of demo links.
class _DemoSection {
  const _DemoSection({required this.title, required this.links});

  final String title;
  final List<_DemoLink> links;
}

const _sections = <_DemoSection>[
  _DemoSection(
    title: 'Search',
    links: [
      _DemoLink(
        label: 'Open Library Book Search',
        route: '/book_search',
        icon: Icons.menu_book_outlined,
        subtitle: 'Debounced search · lazy (query, page) family pagination',
      ),
    ],
  ),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Demos')),
      body: ListView(
        children: [
          for (final section in _sections) _Section(section: section),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.section});

  final _DemoSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // M3 list subheader.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            section.title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          clipBehavior: Clip.antiAlias,
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHigh,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(28)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < section.links.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 20, endIndent: 20),
                _LinkTile(link: section.links[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.link});

  final _DemoLink link;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Icon(link.icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(link.label),
      subtitle: link.subtitle != null ? Text(link.subtitle!) : null,
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: () => context.go(link.route),
    );
  }
}
