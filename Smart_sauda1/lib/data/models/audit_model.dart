import '../../domain/entities/audit_entity.dart';

class AuditModel extends AuditEntity {
  AuditModel({
    required super.id,
    required super.auditorId,
    required super.cartId,
    required super.timestamp,
    required super.discrepanciesCount,
    required super.status,
    super.totalAmount,
    super.orderId,
  });

  // From MySQL API response (snake_case columns)
  factory AuditModel.fromApiMap(Map<String, dynamic> map) {
    // resolved_amount comes from JOIN (falls back to audit's own total_amount)
    final rawAmount = map['resolved_amount'] ?? map['total_amount'];
    return AuditModel(
      id:                 map['id'] ?? '',
      auditorId:          map['auditor_id'] ?? '',
      cartId:             map['cart_id'] ?? '',
      timestamp:          map['created_at'] != null
                            ? DateTime.parse(map['created_at'].toString())
                            : DateTime.now(),
      discrepanciesCount: map['discrepancies_count'] ?? 0,
      status:             map['status'] ?? 'pending',
      totalAmount:        rawAmount != null
                            ? double.tryParse(rawAmount.toString())
                            : null,
      orderId:            map['order_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'auditorId':          auditorId,
      'cartId':             cartId,
      'date':               timestamp.toIso8601String(),
      'discrepanciesCount': discrepanciesCount,
      'status':             status,
    };
  }
}
