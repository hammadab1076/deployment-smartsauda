import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../domain/repositories/audit_repository.dart';

class AuditorProvider extends ChangeNotifier {
  final AuditRepository _auditRepository;

  AuditorProvider(this._auditRepository);

  Map<String, dynamic> _auditorStats = {};
  Map<String, dynamic> get auditorStats => _auditorStats;

  Map<String, dynamic> _activeCartData = {};
  Map<String, dynamic> get activeCartData => _activeCartData;

  List<dynamic> get cartItems => _activeCartData['items'] ?? [];
  String get cartStatus => _activeCartData['status'] as String? ?? 'unknown';

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // True once auditor has generated the bill — used to change UI state
  bool _billGenerated = false;
  bool get billGenerated => _billGenerated;

  StreamSubscription<Map<String, dynamic>>? _cartSubscription;

  Future<void> loadAuditorStats() async {
    _isLoading = true;
    notifyListeners();
    try {
      final stats = await _auditRepository.getDailyStats();
      _auditorStats = stats;
    } catch (e) {
      debugPrint("Error loading auditor stats: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void listenToCart(String cartId) {
    _cartSubscription?.cancel();
    _activeCartData = {};
    _billGenerated = false;
    _cartSubscription = _auditRepository.getCartStream(cartId).listen((data) {
      _activeCartData = data;
      notifyListeners();

      // Auto-cleanup once customer has paid — subscription no longer needed
      if (data['status'] == 'completed') {
        _cartSubscription?.cancel();
        _cartSubscription = null;
        // Keep _activeCartData so the UI can show the final "paid" state
        // and auto-pop the screen
      }
    });
  }

  Future<void> verifyItem(String cartId, String productId) async {
    try {
      await _auditRepository.verifyItem(cartId, productId);
    } catch (e) {
      debugPrint("Error verifying item: $e");
    }
  }

  // Called when auditor taps "Generate Bill & Send to Customer"
  // Sets cart status → 'bill_generated' and creates the audit record.
  // Subscription stays alive so we detect when the customer pays.
  Future<void> generateBill(String cartId, String auditorId, int discrepanciesCount) async {
    try {
      final auditStatus = discrepanciesCount > 0 ? 'flagged' : 'verified';

      // Compute cart total from current items
      double total = 0;
      for (final item in cartItems) {
        final price = ((item['price'] ?? 0) as num).toDouble();
        final qty   = ((item['quantity'] ?? 1) as num).toInt();
        total += price * qty;
      }

      await _auditRepository.updateCartStatus(cartId, 'auditing');
      await _auditRepository.createAudit(
        cartId: cartId,
        auditorId: auditorId,
        discrepanciesCount: discrepanciesCount,
        status: auditStatus,
        totalAmount: total > 0 ? total : null,
      );

      _billGenerated = true;
      notifyListeners();
      // Subscription stays active — listenToCart will auto-stop on 'paid'
    } catch (e) {
      debugPrint("Error generating bill: $e");
    }
  }

  // Full cleanup after the session is done (called on logout or explicit reset)
  void stopListening() {
    _cartSubscription?.cancel();
    _cartSubscription = null;
    _activeCartData = {};
    _billGenerated = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _cartSubscription?.cancel();
    super.dispose();
  }
}
