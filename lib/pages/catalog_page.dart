import 'dart:async';
import 'package:flutter/material.dart';

import '../widgets/app_scaffold.dart';
import '../routes.dart';
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
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(
                                  () => _selectedCategory = v ?? 'Toutes',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Chip(label: Text('${products.length} résultat(s)')),
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
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _ProductCardGrid(product: products[i]),
                        childCount: products.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.65,
                          ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProductCardGrid extends StatelessWidget {
  final Product product;
  const _ProductCardGrid({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = (product.price as num).toDouble();
    final thumb =
        (product.thumbnail is String &&
            (product.thumbnail as String).isNotEmpty)
        ? product.thumbnail as String
        : null;
    final category = (product.category?.toString().trim().isNotEmpty ?? false)
        ? product.category.toString()
        : 'Sans catégorie';

    return Material(
      color: theme.cardColor,
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          '${AppRoutes.product}/${product.id}',
          arguments: product,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: thumb != null
                      ? Image.network(
                          thumb,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: Color(0x11000000),
                            child: Center(
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        )
                      : const ColoredBox(
                          color: Color(0x11000000),
                          child: Center(child: Icon(Icons.image_outlined)),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${price.toStringAsFixed(2)} €',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add_shopping_cart, size: 16),
                    label: const Text('Ajouter'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
