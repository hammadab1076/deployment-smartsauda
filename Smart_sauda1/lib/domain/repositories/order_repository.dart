import '../entities/order_entity.dart';
import '../../features/auth/domain/entities/user_entity.dart';

abstract class OrderRepository {
  Future<List<OrderEntity>> getOrders(String userId);
  Future<List<OrderEntity>> getAllOrders(); // For Admin
  Future<Map<String, dynamic>> getDailyStats(); // For Admin Dashboard
  Future<void> createOrder(OrderEntity order, {String? cartId});
  Future<void> createCartSession(String cartId, String userId, {String? scannerId, List<Map<String, dynamic>> initialItems = const []});
  Future<int> getUserCount();
  Stream<Map<String, dynamic>> getCartStream(String cartId);
  Future<void> addItemToCart(String cartId, Map<String, dynamic> item);
  Future<void> updateCartStatus(String cartId, String status, {String? paymentMethod});
  Stream<List<UserEntity>> getUsersStream();
  Future<void> updateUserStatus(String userId, bool isActive);
}
