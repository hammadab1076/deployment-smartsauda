import '../../domain/entities/order_entity.dart';

class OrderModel extends OrderEntity {
  OrderModel({
    required super.id,
    required super.userId,
    required super.totalAmount,
    required super.timestamp,
    required super.status,
    required super.items,
  });

  // MySQL DATETIME has no timezone suffix — treat as UTC and convert to local.
  static DateTime _parseUtc(String raw) {
    final normalized = raw.contains('T') ? raw : raw.replaceFirst(' ', 'T');
    final withZ = normalized.endsWith('Z') ? normalized : '${normalized}Z';
    return DateTime.parse(withZ).toLocal();
  }

  // From MySQL API response (snake_case columns)
  factory OrderModel.fromApiMap(Map<String, dynamic> map) {
    return OrderModel(
      id:          map['id'] ?? '',
      userId:      map['user_id'] ?? '',
      totalAmount: double.tryParse(map['total_amount'].toString()) ?? 0.0,
      timestamp:   map['created_at'] != null
                     ? _parseUtc(map['created_at'].toString())
                     : DateTime.now(),
      status:      map['status'] ?? 'completed',
      items:       (map['items'] as List? ?? []).map((i) => OrderItemEntity(
                     productId:   i['product_id'] ?? i['productId'] ?? '',
                     productName: i['product_name'] ?? i['productName'] ?? '',
                     quantity:    i['quantity'] ?? 1,
                     price:       double.tryParse(i['unit_price']?.toString() ?? i['price']?.toString() ?? '0') ?? 0.0,
                   )).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId':      userId,
      'totalAmount': totalAmount,
      'date':        timestamp.toIso8601String(),
      'status':      status,
      'items':       items.map((i) => {
        'productId':   i.productId,
        'productName': i.productName,
        'quantity':    i.quantity,
        'price':       i.price,
      }).toList(),
    };
  }
}
