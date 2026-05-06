import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:smart_sauda1/core/app_theme.dart';
import 'package:smart_sauda1/core/app_router.dart';
import 'package:smart_sauda1/data/datasources/api_datasource.dart';
import 'package:smart_sauda1/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:smart_sauda1/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:smart_sauda1/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_sauda1/features/admin/presentation/providers/admin_provider.dart';
import 'package:smart_sauda1/features/auditor/presentation/providers/auditor_provider.dart';
import 'package:smart_sauda1/features/auth/presentation/screens/splash_screen.dart';
import 'package:smart_sauda1/features/customer/presentation/providers/checkout_provider.dart';
import 'package:smart_sauda1/features/auth/domain/usecases/login_usecase.dart';
import 'package:smart_sauda1/features/auth/domain/usecases/signup_usecase.dart';
import 'package:smart_sauda1/features/admin/domain/usecases/get_admin_stats_usecase.dart';
import 'package:smart_sauda1/domain/usecases/process_payment_usecase.dart';
import 'package:smart_sauda1/domain/repositories/order_repository.dart';
import 'package:smart_sauda1/domain/repositories/audit_repository.dart';
import 'package:smart_sauda1/domain/repositories/product_repository.dart';
import 'package:smart_sauda1/data/repositories/order_repository_impl.dart';
import 'package:smart_sauda1/data/repositories/audit_repository_impl.dart';
import 'package:smart_sauda1/data/repositories/product_repository_impl.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiDataSource  = ApiDataSource();
    final authRemote     = AuthRemoteDataSource();
    final authRepo       = AuthRepositoryImpl(authRemote);

    final orderRepo      = OrderRepositoryImpl(apiDataSource);
    final auditRepo      = AuditRepositoryImpl(apiDataSource);
    final productRepo    = ProductRepositoryImpl(apiDataSource);

    final loginUseCase          = LoginUseCase(authRepo);
    final signupUseCase         = SignupUseCase(authRepo);
    final getAdminStatsUseCase  = GetAdminStatsUseCase(orderRepo);
    final processPaymentUseCase = ProcessPaymentUseCase(orderRepo);

    return MultiProvider(
      providers: [
        Provider<OrderRepository>.value(value: orderRepo),
        Provider<ProductRepository>.value(value: productRepo),
        Provider<AuditRepository>.value(value: auditRepo),
        ChangeNotifierProvider(
            create: (_) => AuthProvider(authRepo, loginUseCase, signupUseCase)),
        ChangeNotifierProvider(
            create: (_) => AdminProvider(orderRepo, getAdminStatsUseCase)),
        ChangeNotifierProvider(create: (_) => AuditorProvider(auditRepo)),
        ChangeNotifierProvider(
            create: (_) => CheckoutProvider(processPaymentUseCase, orderRepo, productRepo)),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Smart Sauda',
            theme: AppTheme.lightTheme,
            onGenerateRoute: AppRouter.generateRoute,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
