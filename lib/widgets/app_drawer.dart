import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _go(BuildContext context, String route) {
    Navigator.pop(context);
    final current = ModalRoute.of(context)?.settings.name;
    if (current == route) return;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'ShopFlutter',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => _go(context, '/home'),
          ),
          ListTile(
            leading: const Icon(Icons.list),
            title: const Text('Catalogue'),
            onTap: () => _go(context, '/catalog'),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Panier'),
            onTap: () => _go(context, '/cart'),
          ),
          ListTile(
            leading: const Icon(Icons.receipt),
            title: const Text('Commandes'),
            onTap: () => _go(context, '/orders'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Déconnexion'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
    );
  }
}
