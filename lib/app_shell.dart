import 'package:flutter/material.dart';
import 'package:flutter_demos/app_routes.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        destinations: [
          NavigationDestination(icon: Icon(Icons.inbox), label: "Inbox"),
          NavigationDestination(icon: Icon(Icons.move_to_inbox), label: "Inbox v2"),
          NavigationDestination(icon: Icon(Icons.settings), label: "Settings"),
        ],
        onDestinationSelected: (idx) {
          setState(() {
            selectedIndex = idx;
          });
          String route = switch (idx) {
            0 => AppRoutes.inbox,
            1 => AppRoutes.inboxV2,
            2 => AppRoutes.settings,
            _ => AppRoutes.inbox
          };
          context.go(route);
        },
      ),
      body: widget.child,
    );
  }
}
