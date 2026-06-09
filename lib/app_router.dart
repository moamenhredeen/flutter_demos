import 'package:flutter_demos/home_screen.dart';
import 'package:flutter_demos/open_library_search/open_library_search.dart';
import 'package:go_router/go_router.dart';

final appRouterConfig = GoRouter(
  initialLocation: "/home",
  routes: [
    GoRoute(path: '/home', builder: (context, state) => HomeScreen()),
    GoRoute(path: '/open_library_search', builder: (context, state) => OpenLibrarySearchScreen()),
  ],
);
