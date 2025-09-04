import 'package:flutter/material.dart';

import '../widgets/app_scaffold.dart';
import '../models/product.dart';
import '../repositories/catalog_repository.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final _repo = CatalogRepository();
  late Future<List<Product>> _future;

  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'Toutes';

  List<Product> _all = [];
  List<String> _categories = const ['Toutes'];

  @override
  void initState() {
    super.initState();
    _future = _load();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<List<Product>> _load() async {
    final products = await _repo.fetchProducts();
    _all = products;

    final cats = <String>{};
    for (final p in products) {
      final c = (p.category ?? '').toString().trim();
      if (c.isNotEmpty) cats.add(c);
    }
    _categories = ['Toutes', ...cats.toList()..sort()];
    setState(() {});
    return products;
  }

  List<Product> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    final cat = _selectedCategory;
    return _all.where((p) {
      final okTitle = q.isEmpty ? true : p.title.toLowerCase().contains(q);
      final okCat = (cat == 'Toutes') ? true : p.category?.toString() == cat;
      return okTitle && okCat;
    }).toList();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Catalogue',
      actions: const [_CartBadgeAction()],
      body: FutureBuilder<List<Product>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 56),
                    const SizedBox(height: 12),
                    const Text('Impossible de charger le catalogue.'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          final products = _filtered;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchCtrl,
                          textInputAction: TextInputAction.search,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Rechercher un produit…',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.filter_list),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Catégorie',
                                ),
                                value: _selectedCategory,
                                items: _categories
                                    .map((c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(c),
                                        ))
                                    .toList(),
                                onChanged: (v) => setState(
                                    () => _selectedCategory = v ?? 'Toutes'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (products.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                            'Aucun produit ne correspond à votre recherche.'),
                      ),
                    ),
                  )
                else
                  SliverList.separated(
                    itemBuilder: (context, i) =>
                        _ProductTile(product: products[i]),
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemCount: products.length,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final price = (product.price as num).toDouble();
    final thumb = (product.thumbnail is String &&
            (product.thumbnail as String).isNotEmpty)
        ? product.thumbnail as String
        : null;

    return ListTile(
      leading: thumb != null
          ? Image.network(
              thumb,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image_outlined),
            )
          : const Icon(Icons.image_outlined),
      title: Text(product.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text('${price.toStringAsFixed(2)} €'
          '${product.category != null ? ' • ${product.category}' : ''}'),
      onTap: () => Navigator.pushNamed(context, '/product', arguments: product),
    );
  }
}

/// Petit bouton panier avec badge (réutilisé ici simplement)
class _CartBadgeAction extends StatelessWidget {
  const _CartBadgeAction();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Panier',
      icon: const Icon(Icons.shopping_cart_outlined),
      onPressed: () => Navigator.pushNamed(context, '/cart'),
    );
  }
}
