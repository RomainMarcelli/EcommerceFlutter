import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:tp_ecommerce/models/product.dart';
import 'package:tp_ecommerce/pages/product_detail_page.dart';
import 'package:tp_ecommerce/services/cart_service.dart';

void main() {
  // Un produit factice pour les tests
  final sampleProduct = Product(
    id: 1,
    title: 'Sneakers Pro',
    price: 79.99,
    description: 'Super baskets légères.',
    category: 'shoes',
    thumbnail: '',
    images: const [],
  );

  Widget _wrapWithProviders(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartService()),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets('ProductDetailPage affiche titre, prix et bouton Ajouter au panier',
      (tester) async {
    await tester.pumpWidget(_wrapWithProviders(ProductDetailPage(product: sampleProduct)));

    // Titre
    expect(find.text('Sneakers Pro'), findsOneWidget);

    // Prix (formatté avec €)
    expect(find.textContaining('79.99'), findsWidgets); // tolérant (avec ou sans € / décimales locales)
    // Bouton “Ajouter au panier”
    expect(find.widgetWithText(FilledButton, 'Ajouter au panier'), findsOneWidget);
  });

  testWidgets('Tap sur Ajouter au panier incrémente le panier', (tester) async {
    await tester.pumpWidget(_wrapWithProviders(ProductDetailPage(product: sampleProduct)));

    // Avant : panier vide
    final element = tester.element(find.byType(ProductDetailPage));
    final cartBefore = Provider.of<CartService>(element, listen: false);
    expect(cartBefore.itemCount, 0);

    // Tap sur le bouton
    await tester.tap(find.widgetWithText(FilledButton, 'Ajouter au panier'));
    await tester.pump(); // applique le setState éventuel / SnackBar

    // Après : 1 item dans le panier
    final cartAfter = Provider.of<CartService>(element, listen: false);
    expect(cartAfter.itemCount, 1);

    // Optionnel : si ProductDetailPage montre une SnackBar
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SnackBar), findsAny); // ne fait pas échouer si pas de SnackBar
  });
}
