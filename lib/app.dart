import 'package:flutter/material.dart';
import 'package:flutter_demos/app_router.dart';

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.teal),
      ),
      routerConfig: appRouterConfig,
    );
  }
}
