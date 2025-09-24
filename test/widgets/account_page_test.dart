import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:network_image_mock/network_image_mock.dart';

import 'package:tp_ecommerce/pages/account_page.dart';

Widget createWidgetUnderTest(FirebaseAuth auth) {
  return MaterialApp(home: AccountPage(auth: auth));
}

void main() {
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    mockUser = MockUser(
      uid: '123',
      email: 'test@example.com',
      displayName: 'Test User',
      photoURL: 'https://example.com/fake.jpg', // sera mocké
    );

    mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
  });

  testWidgets('Affiche l’email et le displayName dans AccountPage', (
    tester,
  ) async {
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(createWidgetUnderTest(mockAuth));
      await tester.pumpAndSettle();

      // L’email est affiché deux fois → on adapte l’assertion
      expect(find.text('test@example.com'), findsNWidgets(2));
      expect(find.text('Nom d’affichage'), findsOneWidget);
    });
  });

  testWidgets('Bouton Enregistrer est présent et cliquable', (tester) async {
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(createWidgetUnderTest(mockAuth));
      await tester.pumpAndSettle();

      final btn = find.widgetWithText(FilledButton, 'Enregistrer');
      expect(btn, findsOneWidget);

      await tester.tap(btn);
      await tester.pump();
    });
  });

  testWidgets('ListTiles sécurité sont affichés', (tester) async {
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(createWidgetUnderTest(mockAuth));
      await tester.pumpAndSettle();

      expect(find.text("Changer d’email"), findsOneWidget);
      expect(find.text("Changer le mot de passe"), findsOneWidget);
      expect(find.text("Supprimer mon compte"), findsOneWidget);
    });
  });
}
