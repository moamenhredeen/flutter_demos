import 'package:flutter_demos/home_screen.dart';
import 'package:flutter_demos/pagination/pagination.dart';
import 'package:go_router/go_router.dart';

final appRouterConfig = GoRouter(
  initialLocation: "/home",
  routes: [
    GoRoute(path: '/home', builder: (context, state) => HomeScreen()),
    GoRoute(path: '/pagination', builder: (context, state) => PaginationDemo()),
  ],
);
