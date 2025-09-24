import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/app_scaffold.dart';
import '../services/cart_service.dart';

// Utils spécifiques web (conditionnels)
import '../utils/web_utils.dart'
    if (dart.library.html) '../utils/web_utils_web.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'ShopFlutter',
      actions: const [CartBadgeAction()],
      body: const _HomeContent(),
    );
  }
}

/// Action d’AppBar : icône panier avec badge
class CartBadgeAction extends StatelessWidget {
  const CartBadgeAction({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            tooltip: 'Panier',
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.pushNamed(context, '/cart'),
          ),
          Positioned(
            right: 6,
            top: 6,
            child: Consumer<CartService>(
              builder: (_, cart, __) => cart.itemCount == 0
                  ? const SizedBox.shrink()
                  : Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${cart.itemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Contenu principal : hero + raccourcis + résumé panier
class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroBanner(),
                const SizedBox(height: 16),

                // 🔹 Bouton spécial Web/Chrome uniquement
                if (kIsWeb && WebUtils.isChrome())
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: WebUtils.openPlayStore,
                      icon: const Icon(Icons.download),
                      label: const Text("Installer sur Google Play"),
                    ),
                  ),

                const SizedBox(height: 16),
                _QuickActions(),
                const SizedBox(height: 8),
                _CartSummary(
                  itemsCount: cart.itemCount,
                  total: cart.subtotal,
                  onGoToCart: () => Navigator.pushNamed(context, '/cart'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primaryContainer, cs.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Icon(Icons.store_mall_directory_outlined, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bienvenue sur ShopFlutter 👋\nParcourez le catalogue et passez commande.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 520;
        final children = [
          _ActionButton(
            icon: Icons.list_alt_outlined,
            label: 'Catalogue',
            style: buttonStyle,
            onTap: () => Navigator.pushNamed(context, '/catalog'),
          ),
          _ActionButton(
            icon: Icons.receipt_long_outlined,
            label: 'Mes commandes',
            style: buttonStyle,
            onTap: () => Navigator.pushNamed(context, '/orders'),
          ),
          _ActionButton(
            icon: Icons.shopping_cart_checkout_outlined,
            label: 'Checkout',
            style: buttonStyle,
            onTap: () => Navigator.pushNamed(context, '/checkout'),
          ),
        ];

        return isWide
            ? Row(
                children: [
                  Expanded(child: children[0]),
                  const SizedBox(width: 12),
                  Expanded(child: children[1]),
                  const SizedBox(width: 12),
                  Expanded(child: children[2]),
                ],
              )
            : Column(
                children: [
                  children[0],
                  const SizedBox(height: 8),
                  children[1],
                  const SizedBox(height: 8),
                  children[2],
                ],
              );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ButtonStyle? style;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: style,
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final int itemsCount;
  final double total;
  final VoidCallback onGoToCart;

  const _CartSummary({
    required this.itemsCount,
    required this.total,
    required this.onGoToCart,
  });

  @override
  Widget build(BuildContext context) {
    final hasItems = itemsCount > 0;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const Icon(Icons.shopping_cart_outlined),
        title: Text(
          hasItems
              ? 'Vous avez $itemsCount article(s) dans le panier'
              : 'Votre panier est vide',
        ),
        subtitle: hasItems
            ? Text('Total : ${total.toStringAsFixed(2)} €')
            : null,
        trailing: FilledButton(
          onPressed: onGoToCart,
          child: Text(hasItems ? 'Voir le panier' : 'Voir le catalogue'),
        ),
        onTap: hasItems
            ? onGoToCart
            : () => Navigator.pushNamed(context, '/catalog'),
      ),
    );
  }
}
