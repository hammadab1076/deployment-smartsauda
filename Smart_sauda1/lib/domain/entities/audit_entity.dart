class AuditEntity {
  final String id;
  final String auditorId;
  final String cartId;
  final DateTime timestamp;
  final int discrepanciesCount;
  final String status; // e.g., 'verified', 'flagged'
  final double? totalAmount;
  final String? orderId;

  AuditEntity({
    required this.id,
    required this.auditorId,
    required this.cartId,
    required this.timestamp,
    required this.discrepanciesCount,
    required this.status,
    this.totalAmount,
    this.orderId,
  });
}
