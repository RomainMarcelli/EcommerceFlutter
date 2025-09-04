import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class ThirdPage extends StatelessWidget {
  const ThirdPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Third Page')),
      drawer: const AppDrawer(),
      body: const Center(
        child: Text('This is the third page'),
      ),
    );
  }
}
