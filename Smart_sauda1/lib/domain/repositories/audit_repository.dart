import '../entities/audit_entity.dart';

abstract class AuditRepository {
  Future<List<AuditEntity>> getAudits(String auditorId);
  Future<Map<String, dynamic>> getDailyStats(); // For Auditor Dashboard
  Stream<Map<String, dynamic>> getCartStream(String cartId);
  Future<void> verifyItem(String cartId, String productId);
  Future<void> updateCartStatus(String cartId, String status);
  Future<void> createAudit({
    required String cartId,
    required String auditorId,
    required int discrepanciesCount,
    required String status,
    double? totalAmount,
  });
}
