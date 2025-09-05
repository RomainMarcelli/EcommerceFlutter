import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:tp_ecommerce/pages/cart_page.dart';
import 'package:tp_ecommerce/services/cart_service.dart';
import 'package:tp_ecommerce/routes.dart';

void main() {
  group('CartPage widget', () {
    late CartService cart;

    Widget buildApp(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<CartService>.value(value: cart),
        ],
        child: MaterialApp(
          routes: {
            AppRoutes.checkout: (_) => const _DummyCheckout(),
          },
          home: child,
        ),
      );
    }

    setUp(() {
      cart = CartService();
      cart.addItem(
          productId: 1, title: 'Produit A', price: 10.0, thumbnail: '');
      cart.addItem(productId: 2, title: 'Produit B', price: 5.0, thumbnail: '');
      // Total attendu: 15.00 €
    });

    testWidgets('affiche les items et le total', (tester) async {
      await tester.pumpWidget(buildApp(const CartPage()));
      await tester.pumpAndSettle();

      // 2 ListTile (Produit A & Produit B)
      expect(find.text('Produit A'), findsOneWidget);
      expect(find.text('Produit B'), findsOneWidget);

      // Total
      expect(find.textContaining('Total : 15.00 €'), findsOneWidget);
    });

    testWidgets('bouton + et - mettent à jour la quantité et le total',
        (tester) async {
      await tester.pumpWidget(buildApp(const CartPage()));
      await tester.pumpAndSettle();

      // On cible la ligne de "Produit A"
      final produitATile = find.widgetWithText(ListTile, 'Produit A');
      expect(produitATile, findsOneWidget);

      // + une fois
      final addButtons = find.descendant(
        of: produitATile,
        matching: find.byIcon(Icons.add_circle_outline),
      );
      expect(addButtons, findsOneWidget);
      await tester.tap(addButtons);
      await tester.pump(); // notifier rebuild

      // Total: 10 + 5 + 10 = 25.00
      expect(find.textContaining('Total : 25.00 €'), findsOneWidget);

      // - une fois
      final removeButtons = find.descendant(
        of: produitATile,
        matching: find.byIcon(Icons.remove_circle_outline),
      );
      await tester.tap(removeButtons);
      await tester.pump();

      // Retour au total 15.00
      expect(find.textContaining('Total : 15.00 €'), findsOneWidget);
    });

    testWidgets('supprimer un item met à jour la liste et le total',
        (tester) async {
      await tester.pumpWidget(buildApp(const CartPage()));
      await tester.pumpAndSettle();

      // Supprime "Produit B" (5.00 €)
      final produitBTile = find.widgetWithText(ListTile, 'Produit B');
      final deleteBtn = find.descendant(
        of: produitBTile,
        matching: find.byIcon(Icons.delete_outline),
      );
      await tester.tap(deleteBtn);
      await tester.pump();

      // Disparaît
      expect(find.text('Produit B'), findsNothing);

      // Total mis à jour: 10.00 €
      expect(find.textContaining('Total : 10.00 €'), findsOneWidget);
    });

    testWidgets('Commander navigue vers /checkout quand panier non vide',
        (tester) async {
      await tester.pumpWidget(buildApp(const CartPage()));
      await tester.pumpAndSettle();

      // On cible la clé ajoutée sur le bouton (fiable à 100 %)
      final checkoutBtn = find.byKey(const Key('checkout_button'));
      expect(checkoutBtn, findsOneWidget);

      await tester.tap(checkoutBtn);
      await tester.pumpAndSettle();

      expect(find.text('FAKE CHECKOUT'), findsOneWidget);
    });
  });
}

class _DummyCheckout extends StatelessWidget {
  const _DummyCheckout({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('FAKE CHECKOUT')));
  }
}
