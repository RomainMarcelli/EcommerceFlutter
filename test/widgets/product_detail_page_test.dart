// test/widgets/product_detail_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:tp_ecommerce/pages/product_detail_page.dart';
import 'package:tp_ecommerce/models/product.dart';
import 'package:tp_ecommerce/services/cart_service.dart';

void main() {
  group('ProductDetailPage', () {
    final product = Product(
      id: 1,
      title: 'Sneakers Pro',
      price: 99.99,
      description: 'Chaussures de sport haut de gamme',
      category: 'Chaussures',
      thumbnail: 'https://via.placeholder.com/150',
      images: ['https://via.placeholder.com/150'],
    );

    Widget createWidgetUnderTest() {
      return ChangeNotifierProvider(
        create: (_) => CartService(),
        child: MaterialApp(home: ProductDetailPage(product: product)),
      );
    }

    testWidgets('affiche titre, prix et bouton Ajouter au panier', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Sneakers Pro'), findsOneWidget);
      expect(find.text('99.99 €'), findsOneWidget);

      // 🔑 On vérifie via la Key (ne dépend pas du type de bouton)
      expect(find.byKey(const Key('addToCartButton')), findsOneWidget);
    });

    testWidgets('Tap sur Ajouter au panier incrémente le panier', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final button = find.byKey(const Key('addToCartButton'));

      // S’assure que le bouton est bien visible dans le ScrollView
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();

      await tester.tap(button);
      await tester.pump();

      final cart = Provider.of<CartService>(
        tester.element(find.byType(ProductDetailPage)),
        listen: false,
      );

      expect(cart.items.length, 1);
      expect(cart.items.first.title, 'Sneakers Pro');
    });
  });
}
