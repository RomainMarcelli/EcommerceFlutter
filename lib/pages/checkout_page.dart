import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/app_scaffold.dart';
import '../services/cart_service.dart';
import '../repositories/orders_repository.dart';
import '../models/order.dart';
import '../models/cart_item.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final items = cart.items;
    final total = cart.subtotal;

    return AppScaffold(
      title: 'Checkout',
      actions: const [_CartBadgeAction()],
      body: items.isEmpty
          ? const _EmptyCheckout()
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final it = items[i];
                      return ListTile(
                        leading:
                            (it.thumbnail != null && it.thumbnail!.isNotEmpty)
                            ? Image.network(
                                it.thumbnail!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
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
                        trailing: Text(
                          '${(it.lineTotal).toStringAsFixed(2)} €',
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
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
                          icon: const Icon(Icons.lock),
                          label: const Text('Payer (mock)'),
                          onPressed: items.isEmpty
                              ? null
                              : () async {
                                  final cart = context.read<CartService>();
                                  final repo = context.read<OrdersRepository>();

                                  final order = Order(
                                    id: DateTime.now().millisecondsSinceEpoch
                                        .toString(),
                                    createdAt: DateTime.now(),
                                    lines: List<CartItem>.from(cart.items),
                                    total: cart.subtotal,
                                  );

                                  await repo.add(order);
                                  cart.clear();

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Commande créée ✅'),
                                      ),
                                    );
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/orders',
                                      (r) =>
                                          r.settings.name == '/home' ||
                                          r.isFirst,
                                    );
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _EmptyCheckout extends StatelessWidget {
  const _EmptyCheckout();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shopping_bag_outlined, size: 64),
          const SizedBox(height: 12),
          const Text('Aucun article à payer'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/catalog'),
            child: const Text('Retour au catalogue'),
          ),
        ],
      ),
    );
  }
}

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
