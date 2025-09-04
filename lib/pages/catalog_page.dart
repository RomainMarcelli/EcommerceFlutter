import 'package:flutter/material.dart';
import '../repositories/catalog_repository.dart';
import '../models/product.dart';
import '../widgets/app_drawer.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final repo = CatalogRepository();
  late Future<List<Product>> _futureProducts;

  @override
  void initState() {
    super.initState();
    _futureProducts = repo.fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catalogue')),
      drawer: const AppDrawer(),
      body: FutureBuilder<List<Product>>(
        future: _futureProducts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          final products = snapshot.data!;
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];
              return ListTile(
                leading: Image.network(p.thumbnail, width: 50, height: 50, fit: BoxFit.cover),
                title: Text(p.title),
                subtitle: Text('${p.price} €'),
                onTap: () {
                  Navigator.pushNamed(context, '/product/${p.id}');
                },
              );
            },
          );
        },
      ),
    );
  }
}
