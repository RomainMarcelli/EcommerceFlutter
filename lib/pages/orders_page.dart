import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes commandes')),
      drawer: const AppDrawer(),
      body: const Center(
        child: Text('Aucune commande pour le moment (mock)'),
      ),
    );
  }
}
