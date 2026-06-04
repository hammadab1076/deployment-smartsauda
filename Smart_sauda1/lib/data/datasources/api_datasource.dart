import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:smart_sauda1/core/api_config.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/audit_model.dart';
import '../../features/auth/data/models/user_model.dart';

class ApiDataSource {
  final String _base = ApiConfig.baseUrl;

  // -------------------------------------------------------------------------
  // Products
  // -------------------------------------------------------------------------

  Future<List<ProductModel>> getProducts() async {
    final res = await http.get(Uri.parse('$_base/products'));
    final List data = json.decode(res.body) as List;
    return data.map((m) => ProductModel.fromApiMap(m as Map<String, dynamic>)).toList();
  }

  Future<ProductModel?> getProductByBarcode(String barcode) async {
    final res = await http.get(Uri.parse('$_base/products/barcode/$barcode'));
    if (res.statusCode == 404) return null;
    return ProductModel.fromApiMap(json.decode(res.body) as Map<String, dynamic>);
  }

  Future<ProductModel?> getProductByNfcTag(String nfcTagId) async {
    final res = await http.get(Uri.parse('$_base/products/nfc/$nfcTagId'));
    if (res.statusCode == 404) return null;
    return ProductModel.fromApiMap(json.decode(res.body) as Map<String, dynamic>);
  }

  // -------------------------------------------------------------------------
  // Carts
  // -------------------------------------------------------------------------

  Future<void> createCartSession(String cartId, String userId,
      {String? scannerId, List<Map<String, dynamic>> initialItems = const []}) async {
    final res = await http.post(
      Uri.parse('$_base/carts'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'cartId': cartId, 'userId': userId, 'scannerId': scannerId}),
    );
    if (res.statusCode != 200) {
      final body = json.decode(res.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to create cart session');
    }
  }

  // Real-time sync via 2-second polling (replaces Firestore stream)
  Stream<Map<String, dynamic>> getCartStream(String cartId) {
    return Stream.periodic(const Duration(seconds: 2))
        .asyncMap((_) => _fetchCart(cartId));
  }

  Future<Map<String, dynamic>> _fetchCart(String cartId) async {
    try {
      final res = await http.get(Uri.parse('$_base/carts/$cartId'));
      if (res.statusCode == 404) return {};
      return json.decode(res.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('ApiDataSource._fetchCart error: $e');
      return {};
    }
  }

  Future<void> addItemToCart(String cartId, Map<String, dynamic> item) async {
    await http.post(
      Uri.parse('$_base/carts/$cartId/items'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'productId':   item['id'],
        'productName': item['name'],
        'price':       item['price'],
        'category':    item['category'],
      }),
    );
  }

  Future<void> updateCartStatus(String cartId, String status,
      {String? paymentMethod}) async {
    final body = <String, dynamic>{'status': status};
    if (paymentMethod != null) body['paymentMethod'] = paymentMethod;
    final res = await http.put(
      Uri.parse('$_base/carts/$cartId/status'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    if (res.statusCode != 200) {
      final msg = (json.decode(res.body) as Map<String, dynamic>)['error']
              as String? ??
          'Status update failed (${res.statusCode})';
      throw Exception(msg);
    }
  }

  Future<void> verifyItemInCart(String cartId, String productId) async {
    await http.put(
      Uri.parse('$_base/carts/$cartId/items/$productId/verify'),
      headers: {'Content-Type': 'application/json'},
    );
  }

  // -------------------------------------------------------------------------
  // Orders
  // -------------------------------------------------------------------------

  Future<List<OrderModel>> getOrders(String userId) async {
    final res = await http.get(Uri.parse('$_base/orders/user/$userId'));
    final List data = json.decode(res.body) as List;
    return data.map((m) => OrderModel.fromApiMap(m as Map<String, dynamic>)).toList();
  }

  Future<List<OrderModel>> getAllOrders() async {
    final res = await http.get(Uri.parse('$_base/orders'));
    final List data = json.decode(res.body) as List;
    return data.map((m) => OrderModel.fromApiMap(m as Map<String, dynamic>)).toList();
  }

  Future<void> createOrder(OrderModel order, {String? cartId}) async {
    await http.post(
      Uri.parse('$_base/orders'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'id':          order.id,
        'userId':      order.userId,
        'cartId':      cartId,
        'totalAmount': order.totalAmount,
        'items':       order.items.map((i) => {
          'productId':   i.productId,
          'productName': i.productName,
          'quantity':    i.quantity,
          'price':       i.price,
        }).toList(),
      }),
    );
  }

  // -------------------------------------------------------------------------
  // Audits
  // -------------------------------------------------------------------------

  Future<List<AuditModel>> getAudits(String auditorId) async {
    final res = await http.get(Uri.parse('$_base/audits/auditor/$auditorId'));
    if (res.statusCode != 200) return [];
    final decoded = json.decode(res.body);
    if (decoded is! List) return [];
    return decoded.map((m) => AuditModel.fromApiMap(m as Map<String, dynamic>)).toList();
  }

  Future<List<AuditModel>> getAllAudits() async {
    final res = await http.get(Uri.parse('$_base/audits'));
    if (res.statusCode != 200) return [];
    final decoded = json.decode(res.body);
    if (decoded is! List) return [];
    return decoded.map((m) => AuditModel.fromApiMap(m as Map<String, dynamic>)).toList();
  }

  Future<void> createAudit({
    required String cartId,
    required String auditorId,
    required int discrepanciesCount,
    required String status,
    double? totalAmount,
  }) async {
    final body = <String, dynamic>{
      'cartId':             cartId,
      'auditorId':          auditorId,
      'discrepanciesCount': discrepanciesCount,
      'status':             status,
    };
    if (totalAmount != null) body['totalAmount'] = totalAmount;
    await http.post(
      Uri.parse('$_base/audits'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
  }

  // -------------------------------------------------------------------------
  // Users / Admin
  // -------------------------------------------------------------------------

  Future<int> getUserCount() async {
    final res = await http.get(Uri.parse('$_base/users'));
    final List data = json.decode(res.body) as List;
    return data.length;
  }

  Stream<List<UserModel>> getUsersStream() {
    return Stream.periodic(const Duration(seconds: 5))
        .asyncMap((_) async {
      final res = await http.get(Uri.parse('$_base/users'));
      final List data = json.decode(res.body) as List;
      return data.map((m) => UserModel.fromApiMap(m as Map<String, dynamic>)).toList();
    });
  }

  Future<void> updateUserStatus(String userId, bool isActive) async {
    await http.put(
      Uri.parse('$_base/users/$userId/status'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'isActive': isActive}),
    );
  }

  // -------------------------------------------------------------------------
  // Stats
  // -------------------------------------------------------------------------

  Future<Map<String, dynamic>> getDailyStats() async {
    final res = await http.get(Uri.parse('$_base/stats'));
    return json.decode(res.body) as Map<String, dynamic>;
  }

  // -------------------------------------------------------------------------
  // User profile (called by auth datasource after Firebase login/signup)
  // -------------------------------------------------------------------------

  Future<UserModel?> getUserProfile(String uid) async {
    final res = await http.get(Uri.parse('$_base/users/$uid'));
    if (res.statusCode == 404) return null;
    return UserModel.fromApiMap(json.decode(res.body) as Map<String, dynamic>);
  }

  Future<UserModel> upsertUserProfile({
    required String id,
    required String name,
    required String email,
    required String role,
    String? phone,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/users'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'id': id, 'name': name, 'email': email, 'role': role, 'phone': phone}),
    );
    return UserModel.fromApiMap(json.decode(res.body) as Map<String, dynamic>);
  }
}
