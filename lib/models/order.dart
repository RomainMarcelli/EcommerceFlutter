import '../models/cart_item.dart';

class Order {
  final String id; // ex: timestamp
  final DateTime createdAt;
  final List<CartItem> lines;
  final double total;

  Order({
    required this.id,
    required this.createdAt,
    required this.lines,
    required this.total,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'total': total,
        'lines': lines
            .map((e) => {
                  'productId': e.productId,
                  'title': e.title,
                  'price': e.price,
                  'quantity': e.quantity,
                  'thumbnail': e.thumbnail,
                })
            .toList(),
      };

  static Order fromMap(Map<String, dynamic> m) => Order(
        id: m['id'] as String,
        createdAt: DateTime.parse(m['createdAt'] as String),
        total: (m['total'] as num).toDouble(),
        lines: (m['lines'] as List)
            .map((x) => CartItem(
                  productId: x['productId'] as int,
                  title: x['title'] as String,
                  price: (x['price'] as num).toDouble(),
                  quantity: x['quantity'] as int,
                  thumbnail: x['thumbnail'] as String?,
                ))
            .toList(),
      );
}
