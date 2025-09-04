import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class SecondPage extends StatelessWidget {
  const SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Second Page')),
      drawer: const AppDrawer(),
      body: const Center(
        child: Text('This is the second page'),
      ),
    );
  }
}
