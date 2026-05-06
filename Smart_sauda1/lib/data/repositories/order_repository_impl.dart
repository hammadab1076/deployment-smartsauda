import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../datasources/api_datasource.dart';
import '../models/order_model.dart';

class OrderRepositoryImpl implements OrderRepository {
  final ApiDataSource _dataSource;

  OrderRepositoryImpl(this._dataSource);

  @override
  Future<List<OrderEntity>> getOrders(String userId) async {
    return await _dataSource.getOrders(userId);
  }

  @override
  Future<List<OrderEntity>> getAllOrders() async {
    return await _dataSource.getAllOrders();
  }

  @override
  Future<Map<String, dynamic>> getDailyStats() async {
    return await _dataSource.getDailyStats();
  }

  @override
  Future<void> createOrder(OrderEntity order, {String? cartId}) async {
    if (order is! OrderModel) throw Exception('OrderEntity must be OrderModel');
    await _dataSource.createOrder(order, cartId: cartId);
  }

  @override
  Future<void> createCartSession(String cartId, String userId,
      {String? scannerId, List<Map<String, dynamic>> initialItems = const []}) async {
    await _dataSource.createCartSession(cartId, userId, scannerId: scannerId, initialItems: initialItems);
  }

  @override
  Future<int> getUserCount() async {
    return await _dataSource.getUserCount();
  }

  @override
  Stream<Map<String, dynamic>> getCartStream(String cartId) {
    return _dataSource.getCartStream(cartId);
  }

  @override
  Future<void> addItemToCart(String cartId, Map<String, dynamic> item) async {
    await _dataSource.addItemToCart(cartId, item);
  }

  @override
  Future<void> updateCartStatus(String cartId, String status,
      {String? paymentMethod}) async {
    await _dataSource.updateCartStatus(cartId, status,
        paymentMethod: paymentMethod);
  }

  @override
  Stream<List<UserEntity>> getUsersStream() {
    return _dataSource.getUsersStream();
  }

  @override
  Future<void> updateUserStatus(String userId, bool isActive) async {
    await _dataSource.updateUserStatus(userId, isActive);
  }
}
