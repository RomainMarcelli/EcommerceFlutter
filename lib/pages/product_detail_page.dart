import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../services/cart_service.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final images = _extractImages(product);
    final price = (product.price as num).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: Text(product.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.pushNamed(context, '/cart'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Images
            AspectRatio(
              aspectRatio: 1.2,
              child: PageView.builder(
                itemCount: images.length,
                itemBuilder: (_, i) => Image.network(
                  images[i],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Center(child: Icon(Icons.broken_image, size: 56)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Titre + prix
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      product.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${price.toStringAsFixed(2)} €',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Catégorie
            if (product.category != null && product.category!.toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Chip(
                  label: Text(product.category.toString()),
                ),
              ),

            const SizedBox(height: 16),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                product.description ?? 'Aucune description fournie.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),

            const SizedBox(height: 24),

            // Boutons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Ajouter au panier'),
                      onPressed: () {
                        final cart = context.read<CartService>();
                        cart.addItem(
                          productId: product.id as int,
                          title: product.title,
                          price: price,
                          thumbnail: _extractThumbnail(product),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ajouté au panier')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, '/cart'),
                    child: const Text('Voir le panier'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Utilitaires pour gérer DummyJSON ou modèle custom
  static List<String> _extractImages(Product p) {
    final thumbs = <String>[];
    final thumb = _extractThumbnail(p);
    if (thumb != null) thumbs.add(thumb);

    // si p.images existe et est une List<String>
    final any = (p.images);
    if (any is List) {
      for (final v in any) {
        if (v is String && v.isNotEmpty && !thumbs.contains(v)) {
          thumbs.add(v);
        }
      }
    }
    // fallback
    if (thumbs.isEmpty) thumbs.add('');
    return thumbs;
  }

  static String? _extractThumbnail(Product p) {
    final t = (p.thumbnail is String) ? p.thumbnail as String : null;
    return (t != null && t.isNotEmpty) ? t : null;
  }
}
