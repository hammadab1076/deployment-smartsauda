class OrderEntity {
  final String id;
  final String userId;
  final double totalAmount;
  final DateTime timestamp;
  final String status;
  final List<OrderItemEntity> items;

  OrderEntity({
    required this.id,
    required this.userId,
    required this.totalAmount,
    required this.timestamp,
    required this.status,
    required this.items,
  });
}

class OrderItemEntity {
  final String productId;
  final String productName;
  final int quantity;
  final double price;

  OrderItemEntity({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });
}
