import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/app_scaffold.dart';
import '../repositories/orders_repository.dart';
import '../models/order.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<OrdersRepository>();
    final List<Order> orders = repo.all();

    return AppScaffold(
      title: 'Mes commandes',
      actions: [
        if (orders.isNotEmpty)
          IconButton(
            tooltip: 'Vider l’historique',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Vider l’historique ?'),
                  content: const Text(
                      'Cette action supprimera toutes les commandes locales.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Confirmer'),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await context.read<OrdersRepository>().clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Historique vidé')),
                );
              }
            },
          ),
      ],
      body: orders.isEmpty
          ? const _EmptyOrders()
          : ListView.separated(
              itemCount: orders.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final o = orders[i];
                final itemsCount =
                    o.lines.fold<int>(0, (s, e) => s + e.quantity);
                return ListTile(
                  title: Text('Commande #${o.id}'),
                  subtitle:
                      Text('${o.createdAt.toLocal()} • $itemsCount article(s)'),
                  trailing: Text('${o.total.toStringAsFixed(2)} €',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => _showOrderDetails(context, o),
                );
              },
            ),
    );
  }

  void _showOrderDetails(BuildContext context, Order order) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Commande #${order.id}',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Date : ${order.createdAt.toLocal()}'),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: order.lines.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final line = order.lines[i];
                      return ListTile(
                        leading: (line.thumbnail != null &&
                                line.thumbnail!.isNotEmpty)
                            ? Image.network(line.thumbnail!,
                                width: 48, height: 48, fit: BoxFit.cover)
                            : const Icon(Icons.image_outlined),
                        title: Text(line.title,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          '${line.price.toStringAsFixed(2)} € • x${line.quantity}',
                        ),
                        trailing: Text(
                          (line.price * line.quantity).toStringAsFixed(2) +
                              ' €',
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text('Total : ${order.total.toStringAsFixed(2)} €',
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fermer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 64),
          const SizedBox(height: 12),
          const Text('Aucune commande'),
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
