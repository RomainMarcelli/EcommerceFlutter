import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';

class CartService extends ChangeNotifier {
  final Map<int, CartItem> _items = {}; // key = productId

  List<CartItem> get items => _items.values.toList(growable: false);
  int get itemCount => _items.values.fold(0, (sum, it) => sum + it.quantity);
  double get subtotal =>
      _items.values.fold(0.0, (sum, it) => sum + it.lineTotal);
  bool get isEmpty => _items.isEmpty;

  void addItem({
    required int productId,
    required String title,
    required double price,
    String? thumbnail,
    int qty = 1,
  }) {
    if (_items.containsKey(productId)) {
      _items[productId]!.quantity += qty;
    } else {
      _items[productId] = CartItem(
        productId: productId,
        title: title,
        price: price,
        thumbnail: thumbnail,
        quantity: qty,
      );
    }
    notifyListeners();
  }

  void setQuantity(int productId, int qty) {
    if (!_items.containsKey(productId)) return;
    if (qty <= 0) {
      _items.remove(productId);
    } else {
      _items[productId]!.quantity = qty;
    }
    notifyListeners();
  }

  void increment(int productId) =>
      setQuantity(productId, (_items[productId]?.quantity ?? 0) + 1);

  void decrement(int productId) =>
      setQuantity(productId, (_items[productId]?.quantity ?? 0) - 1);

  void remove(int productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
