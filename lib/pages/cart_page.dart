import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/app_scaffold.dart';
import '../services/cart_service.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final items = cart.items;

    return AppScaffold(
      title: 'Panier',
      actions: [
        if (!cart.isEmpty)
          IconButton(
            tooltip: 'Vider le panier',
            onPressed: () {
              cart.clear();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Panier vidé')));
            },
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
      ],
      body: items.isEmpty
          ? const _EmptyCart()
          : CustomScrollView(
              slivers: [
                SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final it = items[i];
                    return ListTile(
                      leading:
                          (it.thumbnail != null && it.thumbnail!.isNotEmpty)
                          ? Image.network(
                              it.thumbnail!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image_outlined),
                            )
                          : const Icon(Icons.image_outlined),
                      title: Text(
                        it.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${it.price.toStringAsFixed(2)} € • x${it.quantity}',
                      ),
                      trailing: ConstrainedBox(
                        constraints: const BoxConstraints.tightFor(
                          width: 160,
                          height: 48,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Diminuer',
                                onPressed: () => context
                                    .read<CartService>()
                                    .decrement(it.productId),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Text(
                                  '${it.quantity}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Augmenter',
                                onPressed: () => context
                                    .read<CartService>()
                                    .increment(it.productId),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                              IconButton(
                                tooltip: 'Supprimer',
                                onPressed: () => context
                                    .read<CartService>()
                                    .remove(it.productId),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SliverToBoxAdapter(
                  child: _CartBottomBar(
                    total: cart.subtotal,
                    enabled: !cart.isEmpty,
                  ),
                ),
              ],
            ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shopping_cart_outlined, size: 64),
          const SizedBox(height: 12),
          const Text('Votre panier est vide'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/catalog'),
            child: const Text('Aller au catalogue'),
          ),
        ],
      ),
    );
  }
}

class _CartBottomBar extends StatelessWidget {
  final double total;
  final bool enabled;
  const _CartBottomBar({required this.total, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Total : ${total.toStringAsFixed(2)} €',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            FilledButton.icon(
              key: const Key('checkout_button'),
              onPressed: enabled
                  ? () => Navigator.pushNamed(context, '/checkout')
                  : null,
              icon: const Icon(Icons.payment),
              label: const Text('Commander'),
            ),
          ],
        ),
      ),
    );
  }
}
