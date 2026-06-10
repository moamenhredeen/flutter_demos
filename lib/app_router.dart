import 'package:flutter_demos/book_search/book_search.dart';
import 'package:flutter_demos/home_screen.dart';
import 'package:go_router/go_router.dart';

final appRouterConfig = GoRouter(
  initialLocation: "/home",
  routes: [
    GoRoute(path: '/home', builder: (context, state) => HomeScreen()),
    GoRoute(path: '/book_search', builder: (context, state) => BookSearchScreen()),
  ],
);
