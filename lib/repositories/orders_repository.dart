import 'package:hive_flutter/hive_flutter.dart';
import '../models/order.dart';

class OrdersRepository {
  final Box _box;
  OrdersRepository(this._box);

  Future<void> add(Order order) async {
    await _box.add(order.toMap());
  }

  List<Order> all() {
    return _box.values
        .map((e) => Order.fromMap(Map<String, dynamic>.from(e)))
        .toList()
        .reversed
        .toList();
  }

  Future<void> clear() => _box.clear();
}
