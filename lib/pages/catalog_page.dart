import 'dart:async';
import 'package:flutter/material.dart';

import '../widgets/app_scaffold.dart';
import '../routes.dart';
import '../models/product.dart';
import '../repositories/catalog_repository.dart'; // adapte si tu injectes différemment

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final _repo =
      CatalogRepository(); // si tu utilises Provider, remplace par context.read<...>()
  late Future<List<Product>> _future;

  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;

  String _selectedCategory = 'Toutes';

  List<Product> _all = [];
  List<String> _categories = const ['Toutes'];

  @override
  void initState() {
    super.initState();
    _future = _load();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<List<Product>> _load() async {
    final products = await _repo.fetchProducts(); // Future<List<Product>>
    _all = products;

    // Catégories distinctes (triées)
    final cats = <String>{};
    for (final p in products) {
      final c = (p.category ?? '').toString().trim();
      if (c.isNotEmpty) cats.add(c);
    }
    _categories = ['Toutes', ...cats.toList()..sort()];
    setState(() {}); // maj UI (dropdown)
    return products;
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() {});
    });
  }

  List<Product> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    final cat = _selectedCategory;

    return _all.where((p) {
      final title = p.title.toString().toLowerCase();
      final matchTitle = q.isEmpty ? true : title.contains(q);
      final matchCat = (cat == 'Toutes') ? true : p.category?.toString() == cat;
      return matchTitle && matchCat;
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
      actions: const [_CartShortcut()],
      body: FutureBuilder<List<Product>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ErrorView(onRetry: _refresh);
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
                          focusNode: _searchFocus,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: 'Rechercher un produit…',
                            border: const OutlineInputBorder(),
                            suffixIcon: (_searchCtrl.text.isEmpty)
                                ? null
                                : IconButton(
                                    tooltip: 'Effacer',
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      _searchFocus.requestFocus();
                                    },
                                    icon: const Icon(Icons.clear),
                                  ),
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
                            const SizedBox(width: 12),
                            // Compteur résultats
                            Chip(
                              label: Text('${products.length} résultat(s)'),
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
                    child: _Empty(),
                  )
                else
                  SliverList.separated(
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => _ProductTile(product: products[i]),
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
      onTap: () =>
          Navigator.pushNamed(context, AppRoutes.product, arguments: product),
    );
  }
}

class _CartShortcut extends StatelessWidget {
  const _CartShortcut();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Panier',
      icon: const Icon(Icons.shopping_cart_outlined),
      onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
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
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Aucun produit ne correspond à votre recherche.'),
      ),
    );
  }
}
