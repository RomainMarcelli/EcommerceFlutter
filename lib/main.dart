import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

// Services
import 'services/cart_service.dart';

// Pages
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/catalog_page.dart';
import 'pages/cart_page.dart';
import 'pages/orders_page.dart';
import 'pages/product_detail_page.dart';
import 'pages/checkout_page.dart';

// Models
import 'models/product.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ShopFlutterApp());
}

class ShopFlutterApp extends StatelessWidget {
  const ShopFlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ShopFlutter',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        // Auth guard simple : home = StreamBuilder sur authStateChanges
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            final user = snapshot.data;
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (user == null) {
              return const LoginPage();
            }
            return const HomePage();
          },
        ),
        // Routes “simples”
        routes: {
          '/login': (context) => const LoginPage(),
          '/home': (context) => const HomePage(),
          '/catalog': (context) => const CatalogPage(),
          '/cart': (context) => const CartPage(),
          '/orders': (context) => const OrdersPage(),
          '/checkout': (context) => const CheckoutPage(),
        },
        // Détail produit via arguments (Product)
        onGenerateRoute: (settings) {
          if (settings.name == '/product') {
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
