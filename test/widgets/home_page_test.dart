// test/widgets/home_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:tp_ecommerce/pages/home_page.dart';
import 'package:tp_ecommerce/services/cart_service.dart';
import 'package:tp_ecommerce/routes.dart';

void main() {
  group('HomePage', () {
    testWidgets('affiche le titre et pas de badge quand le panier est vide',
        (WidgetTester tester) async {
      final cart = CartService();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: cart,
          child: MaterialApp(
            routes: {
              AppRoutes.cart: (_) => const Scaffold(body: Text('CartPageMock')),
            },
            home: const HomePage(),
          ),
        ),
      );

      expect(find.text('ShopFlutter'), findsOneWidget);

      // Pas de badge si itemCount == 0
      expect(find.text('0'), findsNothing);
    });

    testWidgets('affiche le badge avec le nombre d’articles quand non vide',
        (WidgetTester tester) async {
      final cart = CartService();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: cart,
          child: MaterialApp(
            routes: {
              AppRoutes.cart: (_) => const Scaffold(body: Text('CartPageMock')),
            },
            home: const HomePage(),
          ),
        ),
      );

      // Ajoute des items (productId est int)
      cart.addItem(productId: 1, title: 'Produit 1', price: 10);
      cart.addItem(productId: 1, title: 'Produit 1', price: 10);
      cart.addItem(productId: 2, title: 'Produit 2', price: 20);

      await tester.pumpAndSettle();

      // Badge = 3
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('tap sur l’icône panier navigue vers /cart',
        (WidgetTester tester) async {
      final cart = CartService();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: cart,
          child: MaterialApp(
            routes: {
              AppRoutes.cart: (_) => const Scaffold(body: Text('CartPageMock')),
            },
            home: const HomePage(),
          ),
        ),
      );

      // Cible précisément le bouton via son tooltip (unique)
      final cartBtn = find.byTooltip('Panier');
      expect(cartBtn, findsOneWidget);

      await tester.tap(cartBtn);
      await tester.pumpAndSettle();

      expect(find.text('CartPageMock'), findsOneWidget);
    });
  });
}
