import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';

class ProcessPaymentUseCase {
  final OrderRepository repository;

  ProcessPaymentUseCase(this.repository);

  Future<void> execute(OrderEntity order, {String? cartId}) async {
    await repository.createOrder(order, cartId: cartId);
  }
}
