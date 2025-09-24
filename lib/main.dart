import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';
import 'routes.dart';

// Services
import 'services/cart_service.dart';

// Repositories
import 'repositories/orders_repository.dart';

// Pages
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/catalog_page.dart';
import 'pages/cart_page.dart';
import 'pages/orders_page.dart';
import 'pages/product_detail_page.dart';
import 'pages/checkout_page.dart';
import 'pages/account_page.dart';

// Models
import 'models/product.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Hive (persistance des commandes)
  await Hive.initFlutter();
  final ordersBox = await Hive.openBox('orders');

  runApp(ShopFlutterApp(ordersBox: ordersBox));
}

class ShopFlutterApp extends StatelessWidget {
  final Box ordersBox;
  const ShopFlutterApp({super.key, required this.ordersBox});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartService()),
        Provider<OrdersRepository>(create: (_) => OrdersRepository(ordersBox)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ShopFlutter',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          snackBarTheme: const SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          appBarTheme: const AppBarTheme(centerTitle: true),
        ),

        // Auth guard : met à jour l'URL (/login ou /home) via navigation
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            // Écran d'attente
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final bool isLoggedIn = snapshot.data != null;
            final String target = isLoggedIn ? AppRoutes.home : AppRoutes.login;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              final current = ModalRoute.of(context)?.settings.name;
              if (current != target) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  target,
                  (route) => false,
                );
              }
            });

            // Page tampon minimale pendant la redirection
            return const Scaffold(body: SizedBox.shrink());
          },
        ),

        routes: {
          AppRoutes.login: (_) => const LoginPage(),
          AppRoutes.home: (_) => const HomePage(),
          AppRoutes.catalog: (_) => const CatalogPage(),
          AppRoutes.cart: (_) => const CartPage(),
          AppRoutes.orders: (_) => const OrdersPage(),
          AppRoutes.checkout: (_) => const CheckoutPage(),
          AppRoutes.account: (_) => const AccountPage(),
        },

        onGenerateRoute: (settings) {
          final name = settings.name ?? '';

          final reg = RegExp('^${AppRoutes.product}/(\\w+)\$');
          final m = reg.firstMatch(name);

          if (m != null) {
            final idFromUrl = m.group(1)!;

            // Si un Product est passé en argument (navigation interne), on l'utilise
            final arg = settings.arguments;
            if (arg is Product) {
              return MaterialPageRoute(
                builder: (_) => ProductDetailPage(product: arg),
                settings: settings,
              );
            }

            // Fallback temporaire si non implémenté
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Produit')),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Produit $idFromUrl non chargé.\nOuvre depuis le catalogue pour passer l’objet Product en arguments, ou implémente un fetch par ID.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              settings: settings,
            );
          }

          if (name == AppRoutes.product && settings.arguments is Product) {
            final product = settings.arguments as Product;
            return MaterialPageRoute(
              builder: (_) => ProductDetailPage(product: product),
              settings: settings,
            );
          }

          return null;
        },
      ),
    );
  }
}
