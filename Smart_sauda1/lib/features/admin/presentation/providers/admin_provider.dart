import 'package:flutter/material.dart';
import '../../../../domain/repositories/order_repository.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/usecases/get_admin_stats_usecase.dart';

class AdminProvider extends ChangeNotifier {
  final OrderRepository _orderRepository;
  final GetAdminStatsUseCase _getAdminStatsUseCase;

  AdminProvider(this._orderRepository, this._getAdminStatsUseCase);

  Map<String, dynamic> _adminStats = {
    'todaysSales': 0.0,
    'todaysOrders': 0,
    'totalOrders': 0,
    'totalInvoices': 0,
    'activeUsers': 0,
  };
  Map<String, dynamic> get adminStats => _adminStats;

  List<double> _salesChartData = [0, 0, 0, 0, 0, 0, 0];
  List<String> _salesChartLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  List<double> get salesChartData => _salesChartData;
  List<String> get salesChartLabels => _salesChartLabels;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadAdminStats() async {
    _isLoading = true;
    notifyListeners();
    try {
      final stats = await _getAdminStatsUseCase.execute();
      final allOrders = await _orderRepository.getAllOrders();
      final now = DateTime.now();
      
      final userCount = await _orderRepository.getUserCount();
      
      double totalRevenue = allOrders.fold(0.0, (total, o) => total + o.totalAmount);
      double avgOrder = allOrders.isEmpty ? 0 : totalRevenue / allOrders.length;

      _adminStats = {
        ..._adminStats,
        ...stats,
        'totalRevenue': totalRevenue.toStringAsFixed(0),
        'averageOrder': avgOrder.toStringAsFixed(0),
        'activeUsers': userCount,
      };

      List<double> dailyTotals = List.filled(7, 0.0);
      List<String> labels = List.filled(7, "");

      for (int i = 0; i < 7; i++) {
        final day = now.subtract(Duration(days: 6 - i));
        labels[i] = _getDayName(day.weekday);
        
        final daysOrders = allOrders.where((o) => 
          o.timestamp.year == day.year && 
          o.timestamp.month == day.month && 
          o.timestamp.day == day.day
        );
        
        dailyTotals[i] = daysOrders.fold(0.0, (total, o) => total + o.totalAmount);
      }
      
      double maxVal = dailyTotals.reduce((curr, next) => curr > next ? curr : next);
      if (maxVal == 0) maxVal = 1;
      
      _salesChartData = dailyTotals.map((e) => e / maxVal).toList();
      _salesChartLabels = labels;

    } catch (e) {
      debugPrint("Error loading admin stats: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return "Mon";
      case 2: return "Tue";
      case 3: return "Wed";
      case 4: return "Thu";
      case 5: return "Fri";
      case 6: return "Sat";
      case 7: return "Sun";
      default: return "";
    }
  }

  // --- User Management ---
  Stream<List<UserEntity>> getUsersStream() {
    return _orderRepository.getUsersStream();
  }

  Future<void> toggleUserStatus(String userId, bool currentStatus) async {
    try {
      await _orderRepository.updateUserStatus(userId, !currentStatus);
    } catch (e) {
      debugPrint("Error toggling user status: $e");
    }
  }
}
