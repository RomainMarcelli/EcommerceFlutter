import 'package:hive_flutter/hive_flutter.dart';
import '../models/order.dart';

class OrdersRepository {
  final Box _box;
  OrdersRepository(this._box);

  Future<void> add(Order order) async {
    await _box.add(order.toMap());
  }

  // 🔧 Tri par createdAt DESC (même si l’ordre d’insertion change un jour)
  List<Order> all() {
    final list = _box.values
        .map((e) => Order.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> clear() => _box.clear();
}
