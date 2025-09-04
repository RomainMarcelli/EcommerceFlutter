import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panier')),
      drawer: const AppDrawer(),
      body: const Center(
        child: Text('Votre panier est vide (mock)\nOn ajoutera les produits ensuite.'),
      ),
    );
  }
}
