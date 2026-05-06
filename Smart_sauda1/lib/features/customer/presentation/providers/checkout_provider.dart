import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'package:smart_sauda1/data/models/order_model.dart';
import 'package:smart_sauda1/domain/entities/order_entity.dart';
import 'package:smart_sauda1/domain/repositories/order_repository.dart';
import 'package:smart_sauda1/domain/repositories/product_repository.dart';
import 'package:smart_sauda1/domain/usecases/process_payment_usecase.dart';

class CheckoutProvider extends ChangeNotifier {
  final ProcessPaymentUseCase _processPaymentUseCase;
  final OrderRepository _orderRepository;
  final ProductRepository _productRepository;

  CheckoutProvider(this._processPaymentUseCase, this._orderRepository, this._productRepository);

  // --- Cart state ---
  String? _activeCartId;
  String? get activeCartId => _activeCartId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String? _scannedProductName;
  String? get scannedProductName => _scannedProductName;

  // --- NFC polling state ---
  Timer? _pollingTimer;
  String? _arduinoIp;
  bool get isPolling => _pollingTimer != null;

  // ---------------------------------------------------------------------------
  // Cart session
  // ---------------------------------------------------------------------------

  Future<void> startNewCartSession(String userId, {String scannerId = 'SCANNER_01'}) async {
    debugPrint("DEBUG: startNewCartSession for user: $userId, scanner: $scannerId");
    final cartId = 'CART_${DateTime.now().millisecondsSinceEpoch}';
    await _orderRepository.createCartSession(cartId, userId, scannerId: scannerId);
    _activeCartId = cartId;
    debugPrint("DEBUG: Active cart: $_activeCartId");
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // NFC polling (Arduino HTTP server)
  // ---------------------------------------------------------------------------

  void startNfcPolling(String arduinoIp) {
    _arduinoIp = arduinoIp;
    _error = null;
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(milliseconds: 1500),
      (_) => _pollArduino(),
    );
    notifyListeners();
  }

  void stopNfcPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _arduinoIp = null;
    notifyListeners();
  }

  Future<void> _pollArduino() async {
    if (_arduinoIp == null) return;
    try {
      final response = await http
          .get(Uri.parse('http://$_arduinoIp/'))
          .timeout(const Duration(seconds: 1));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final uid = data['uid'] as String?;
        final fresh = data['fresh'] as bool? ?? false;
        if (uid != null && uid != 'none' && fresh) {
          await scanAndAddNfcProduct(uid);
        }
      }
    } catch (_) {
      // Silently ignore transient network errors between polls
    }
  }

  // ---------------------------------------------------------------------------
  // NFC product lookup → cart
  // ---------------------------------------------------------------------------

  Future<void> scanAndAddNfcProduct(String nfcTagId) async {
    _error = null;
    _scannedProductName = null;
    _isLoading = true;
    notifyListeners();

    try {
      final product = await _productRepository.getProductByNfcTag(nfcTagId);
      if (product != null) {
        _scannedProductName = product.name;
        await addProductToCart({
          'id': product.id,
          'name': product.name,
          'price': product.price,
          'category': product.category,
        });
      } else {
        _error = "No product found for NFC tag: $nfcTagId";
        notifyListeners();
      }
    } catch (e) {
      _error = "NFC scan failed: $e";
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Barcode product lookup → cart
  // ---------------------------------------------------------------------------

  Future<void> scanAndAddProduct(String barcode) async {
    _error = null;
    _scannedProductName = null;
    _isLoading = true;
    notifyListeners();

    try {
      final product = await _productRepository.getProductByBarcode(barcode);
      if (product != null) {
        _scannedProductName = product.name;
        await addProductToCart({
          'id': product.id,
          'name': product.name,
          'price': product.price,
          'category': product.category,
        });
      } else {
        debugPrint("DEBUG: Barcode $barcode not in DB — using mock data.");
        _scannedProductName = "Mock Product ($barcode)";
        await addProductToCart({
          'id': 'MOCK_$barcode',
          'name': _scannedProductName!,
          'price': 250.0,
          'category': 'Testing',
        });
        _error = "Note: Mock data used (barcode $barcode not in DB)";
        notifyListeners();
      }
    } catch (e) {
      _error = "Scan failed: $e";
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Core: add item to active cart
  // ---------------------------------------------------------------------------

  Future<void> addProductToCart(Map<String, dynamic> productData) async {
    _error = null;
    if (_activeCartId == null) {
      _error = "Error: no active cart session.";
      debugPrint("DEBUG ERROR: $_error");
      notifyListeners();
      return;
    }

    try {
      final item = {
        ...productData,
        'isVerified': false,
        'addedAt': DateTime.now().toIso8601String(),
      };
      await _orderRepository.addItemToCart(_activeCartId!, item);
      debugPrint("DEBUG: Added '${productData['name']}' to cart $_activeCartId");
      notifyListeners();
    } catch (e) {
      _error = "Cart update failed: $e";
      debugPrint("DEBUG ERROR: $_error");
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Real-time cart stream (2-second polling)
  // ---------------------------------------------------------------------------

  Stream<Map<String, dynamic>> get cartStream {
    if (_activeCartId != null) {
      return _orderRepository.getCartStream(_activeCartId!);
    }
    return Stream.value({});
  }

  // ---------------------------------------------------------------------------
  // Step 1 of checkout: customer signals they're ready → status = 'checkout_requested'
  // Auditor sees this and can generate the bill
  // ---------------------------------------------------------------------------

  // Returns true if the request succeeded (or was already advanced enough)
  Future<bool> requestCheckout() async {
    if (_activeCartId == null) return false;
    try {
      // Fetch current status first so we don't overwrite bill_generated / paid
      final cartData = await _orderRepository.getCartStream(_activeCartId!).first;
      final currentStatus = cartData['status'] as String? ?? 'active';
      if (currentStatus == 'bill_generated' ||
          currentStatus == 'paid' ||
          currentStatus == 'completed') {
        // Auditor already acted — skip the extra update and proceed
        return true;
      }
      await _orderRepository.updateCartStatus(_activeCartId!, 'checkout_requested');
      debugPrint("DEBUG: Checkout requested for cart $_activeCartId");
      return true;
    } catch (e) {
      _error = "Failed to request checkout: $e";
      debugPrint("DEBUG ERROR: requestCheckout → $e");
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Step 2 of checkout: customer pays → creates order + marks cart 'paid'
  // Returns true on success. Caller passes payment method chosen by customer.
  // ---------------------------------------------------------------------------

  Future<bool> processPayment({
    required String userId,
    required double totalAmount,
    required List<OrderItemEntity> items,
    required String paymentMethod,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final orderId = const Uuid().v4();
      final newOrder = OrderModel(
        id: orderId,
        userId: userId,
        totalAmount: totalAmount,
        timestamp: DateTime.now(),
        status: 'completed',
        items: items,
      );
      final cartIdSnapshot = _activeCartId;
      await _processPaymentUseCase.execute(newOrder, cartId: cartIdSnapshot);

      if (_activeCartId != null) {
        await _orderRepository.updateCartStatus(
          _activeCartId!,
          'paid',
          paymentMethod: paymentMethod,
        );
      }

      _activeCartId = null;
      _scannedProductName = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Reset — call on logout so the next user starts clean
  // ---------------------------------------------------------------------------

  void reset() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _arduinoIp = null;
    _activeCartId = null;
    _error = null;
    _scannedProductName = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
