import 'package:flutter/material.dart';

class PaginationDemo extends StatefulWidget {
  const PaginationDemo({super.key});

  @override
  State<PaginationDemo> createState() => _PaginationDemoState();
}

class _PaginationDemoState extends State<PaginationDemo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pagination Demo"),
      ),
      body: Center(
        child: Text("Welcome"),
      ),
    );
  }
}
