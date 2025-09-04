import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tp_ecommerce/main.dart';
import 'package:tp_ecommerce/app/app.dart'; // importe ShopApp

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ShopApp());

    // Ici tu n’as plus de compteur par défaut → le test peut être supprimé
    // ou adapté quand tu auras un widget concret à tester.
  });
}
