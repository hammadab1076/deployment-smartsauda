// dart
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  Future<UserEntity> login(String email, String password, {String selectedRole = 'customer'}) async {
    try {
      final userModel = await _dataSource.login(email, password, selectedRole: selectedRole);
      return userModel;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserEntity> signup(String name, String email, String password, String role) async {
    try {
      final userModel = await _dataSource.signup(name, email, password, role);
      return userModel;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final userModel = await _dataSource.getCurrentUser();
      return userModel;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updateProfile(String name, String phone) async {
    try {
      await _dataSource.updateProfile(name, phone);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> resetPassword(String email, String newPassword) async {
    try {
      await _dataSource.resetPassword(email, newPassword);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      await _dataSource.changePassword(currentPassword, newPassword);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dataSource.logout();
    } catch (e) {
      rethrow;
    }
  }
}
