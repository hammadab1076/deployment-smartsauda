import '../../domain/entities/audit_entity.dart';
import '../../domain/repositories/audit_repository.dart';
import '../datasources/api_datasource.dart';

class AuditRepositoryImpl implements AuditRepository {
  final ApiDataSource _dataSource;

  AuditRepositoryImpl(this._dataSource);

  @override
  Future<List<AuditEntity>> getAudits(String auditorId) async {
    return await _dataSource.getAudits(auditorId);
  }

  @override
  Future<Map<String, dynamic>> getDailyStats() async {
    final res = await _dataSource.getAllAudits();
    final today = DateTime.now();
    final todayAudits = res.where((a) =>
        a.timestamp.year == today.year &&
        a.timestamp.month == today.month &&
        a.timestamp.day == today.day).toList();

    return {
      'todaysAudits':  todayAudits.length,
      'discrepancies': todayAudits.fold(0, (t, a) => t + a.discrepanciesCount),
    };
  }

  @override
  Stream<Map<String, dynamic>> getCartStream(String cartId) {
    return _dataSource.getCartStream(cartId);
  }

  @override
  Future<void> verifyItem(String cartId, String productId) async {
    await _dataSource.verifyItemInCart(cartId, productId);
  }

  @override
  Future<void> updateCartStatus(String cartId, String status) async {
    await _dataSource.updateCartStatus(cartId, status);
  }

  @override
  Future<void> createAudit({
    required String cartId,
    required String auditorId,
    required int discrepanciesCount,
    required String status,
    double? totalAmount,
  }) async {
    await _dataSource.createAudit(
      cartId: cartId,
      auditorId: auditorId,
      discrepanciesCount: discrepanciesCount,
      status: status,
      totalAmount: totalAmount,
    );
  }
}
