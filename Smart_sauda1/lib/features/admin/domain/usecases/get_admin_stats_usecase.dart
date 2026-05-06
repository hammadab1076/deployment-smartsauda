import '../../../../domain/repositories/order_repository.dart';

class GetAdminStatsUseCase {
  final OrderRepository repository;

  GetAdminStatsUseCase(this.repository);

  Future<Map<String, dynamic>> execute() async {
    return await repository.getDailyStats();
  }
}
