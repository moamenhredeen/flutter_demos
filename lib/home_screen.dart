
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TextButton(
                onPressed: (){
                  context.go("/open_library_search");
                },
                child: Text("Pagination")
            )
          ],
        ),
      ),
    );
  }
}
