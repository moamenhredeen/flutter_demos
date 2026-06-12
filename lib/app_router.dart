import 'package:flutter/material.dart';
import 'package:flutter_demos/app_routes.dart';
import 'package:flutter_demos/app_shell.dart';
import 'package:flutter_demos/screens/inbox/inbox_screen.dart';
import 'package:flutter_demos/screens/inbox_v2/inbox_screen.dart' as inbox_v2;
import 'package:flutter_demos/screens/settings/settings_screen.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterConfig = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.inbox,
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: AppRoutes.inbox, builder: (context, state) => InboxScreen()),
        GoRoute(path: AppRoutes.inboxV2, builder: (context, state) => const inbox_v2.InboxScreen()),
        GoRoute(path: AppRoutes.settings, builder: (context, state) => SettingsScreen()),
      ],
    ),
  ],
);
