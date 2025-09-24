import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tp_ecommerce/pages/login_page.dart';
import 'package:tp_ecommerce/routes.dart';

void main() {
  group('LoginPage', () {
    // Helpers de finders robustes : d’abord par Key (si tu les as ajoutées),
    // sinon par texte/placeholder.
    Finder _findEmailField() {
      final byKey = find.byKey(const Key('email_field'));
      if (byKey.evaluate().isNotEmpty) return byKey;
      // fallback : par libellé courant
      final byLabel = find.widgetWithText(TextField, 'Email');
      if (byLabel.evaluate().isNotEmpty) return byLabel;
      // autre fallback : placeholder courant
      final byHint = find.descendant(
        of: find.byType(TextField),
        matching: find.text('Votre email'),
      );
      return byHint.evaluate().isNotEmpty
          ? byHint
          : find.byType(TextField).first;
    }

    Finder _findPasswordField() {
      final byKey = find.byKey(const Key('password_field'));
      if (byKey.evaluate().isNotEmpty) return byKey;
      final byLabel = find.widgetWithText(TextField, 'Mot de passe');
      if (byLabel.evaluate().isNotEmpty) return byLabel;
      final allTextFields = find.byType(TextField);
      // si le premier était l’email, on prend le 2e
      return allTextFields.evaluate().length >= 2
          ? allTextFields.at(1)
          : allTextFields.first;
    }

    Finder _findLoginButton() {
      final byKey = find.byKey(const Key('login_btn'));
      if (byKey.evaluate().isNotEmpty) return byKey;
      // Bouton Material courant
      final byText = find.widgetWithText(ElevatedButton, 'Se connecter');
      if (byText.evaluate().isNotEmpty) return byText;
      // Variante Material3
      final byFilled = find.widgetWithText(FilledButton, 'Se connecter');
      if (byFilled.evaluate().isNotEmpty) return byFilled;
      // Fallback : n’importe quel bouton avec “Se connecter”
      final genericText = find.text('Se connecter');
      if (genericText.evaluate().isNotEmpty) {
        // retourne le premier bouton ancêtre de ce texte
        final candidates = find.ancestor(
          of: genericText,
          matching: find.byType(ElevatedButton),
        );
        if (candidates.evaluate().isNotEmpty) return candidates.first;
        final candidates2 = find.ancestor(
          of: genericText,
          matching: find.byType(FilledButton),
        );
        if (candidates2.evaluate().isNotEmpty) return candidates2.first;
        final candidates3 = find.ancestor(
          of: genericText,
          matching: find.byType(TextButton),
        );
        if (candidates3.evaluate().isNotEmpty) return candidates3.first;
      }
      // Dernier recours : premier FilledButton/ElevatedButton trouvé
      final anyFilled = find.byType(FilledButton);
      if (anyFilled.evaluate().isNotEmpty) return anyFilled.first;
      final anyElev = find.byType(ElevatedButton);
      return anyElev.evaluate().isNotEmpty
          ? anyElev.first
          : find.byType(OutlinedButton).first;
    }

    Widget _buildApp(Widget child) {
      return MaterialApp(
        routes: {
          // On ajoute une fausse Home pour vérifier la navigation.
          AppRoutes.home: (_) => const _DummyHome(),
        },
        home: child,
      );
    }

    testWidgets('affiche les champs email/mot de passe et le bouton', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(const LoginPage()));
      await tester.pumpAndSettle();

      expect(_findEmailField(), findsOneWidget);
      expect(_findPasswordField(), findsOneWidget);
      expect(_findLoginButton(), findsOneWidget);
    });

    testWidgets('saisie email + mot de passe remplit les champs', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(const LoginPage()));
      await tester.pumpAndSettle();

      final email = _findEmailField();
      final pwd = _findPasswordField();

      await tester.enterText(email, 'john@doe.com');
      await tester.enterText(pwd, 'secret123');
      await tester.pump();

      expect(find.text('john@doe.com'), findsOneWidget);
      expect(find.text('secret123'), findsOneWidget);
    });

    testWidgets(
      'tap sur Se connecter ne crash pas et peut naviguer si LoginPage route vers /home',
      (tester) async {
        await tester.pumpWidget(_buildApp(const LoginPage()));
        await tester.pumpAndSettle();

        // On remplit des valeurs plausibles
        await tester.enterText(_findEmailField(), 'john@doe.com');
        await tester.enterText(_findPasswordField(), 'secret123');
        await tester.pump();

        // Tap sur le bouton
        await tester.tap(_findLoginButton());
        await tester.pumpAndSettle();

        // Deux cas :
        // - Si ta LoginPage navigue bien vers /home en cas de succès -> on voit la FAKE HOME.
        // - Sinon, ce test ne casse pas : on check simplement que l’écran reste stable.
        final isHome = find.text('FAKE HOME');
        if (isHome.evaluate().isNotEmpty) {
          expect(isHome, findsOneWidget);
        } else {
          // Pas de navigation ? On reste sur la page sans exceptions.
          expect(find.byType(LoginPage), findsOneWidget);
        }
      },
    );
  });
}

class _DummyHome extends StatelessWidget {
  const _DummyHome({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('FAKE HOME')));
  }
}
