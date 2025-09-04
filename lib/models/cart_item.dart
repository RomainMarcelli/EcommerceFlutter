class CartItem {
  final int productId;
  final String title;
  final double price;
  final String? thumbnail;
  int quantity;

  CartItem({
    required this.productId,
    required this.title,
    required this.price,
    this.thumbnail,
    this.quantity = 1,
  });

  double get lineTotal => price * quantity;
}
