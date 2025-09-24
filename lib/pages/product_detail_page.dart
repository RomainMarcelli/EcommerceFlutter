// lib/pages/product_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../widgets/app_scaffold.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../routes.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final images = _extractImages(product);
    final price = (product.price as num).toDouble();

    return AppScaffold(
      title: 'Détail produit',
      actions: [
        IconButton(
          tooltip: 'Partager',
          icon: const Icon(Icons.share),
          onPressed: () => _shareProduct(product, price),
        ),
        IconButton(
          tooltip: 'Panier',
          icon: const Icon(Icons.shopping_cart_outlined),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----- image -----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AspectRatio(
                aspectRatio: 1.2,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      width: 2,
                    ),
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: PageView.builder(
                        itemCount: images.length,
                        itemBuilder: (_, i) => Image.network(
                          images[i],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image, size: 56),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ----- titre + prix -----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      product.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${price.toStringAsFixed(2)} €',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            if (product.category != null && product.category!.toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Chip(label: Text(product.category.toString())),
              ),

            const SizedBox(height: 16),

            // ----- description -----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                product.description ?? 'Aucune description fournie.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),

            const SizedBox(height: 24),

            // ----- boutons -----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    key: const Key('addToCartButton'), // <<<<<<<<<<<<<  KEY
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
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      minimumSize: const Size(0, 44),
                    ),
                  ),
                  OutlinedButton(
                    key: const Key('seeCartButton'), // optionnel
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      minimumSize: const Size(0, 44),
                    ),
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

  static List<String> _extractImages(Product p) {
    final thumbs = <String>[];
    final thumb = _extractThumbnail(p);
    if (thumb != null) thumbs.add(thumb);

    final any = p.images;
    if (any is List) {
      for (final v in any) {
        if (v is String && v.isNotEmpty && !thumbs.contains(v)) {
          thumbs.add(v);
        }
      }
    }
    if (thumbs.isEmpty) thumbs.add('');
    return thumbs;
  }

  static String? _extractThumbnail(Product p) {
    final t = (p.thumbnail is String) ? p.thumbnail as String : null;
    return (t != null && t.isNotEmpty) ? t : null;
  }

  void _shareProduct(Product p, double price) {
    final url = _extractThumbnail(p);
    final text = [p.title, '${price.toStringAsFixed(2)} €', if (url != null) url].join(' · ');
    Share.share(text);
    }
}
