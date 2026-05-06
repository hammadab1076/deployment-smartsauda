// import '../entities/user_entity.dart';
//
// abstract class AuthRepository {
//   Future<UserEntity> login(String email, String password);
//   Future<UserEntity> signup(String name, String email, String password);
//   Future<void> logout();
// }

import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Authenticates user with email and password
  /// Throws [AuthException] on failure
  Future<UserEntity> login(String email, String password, {String selectedRole = 'customer'});

  /// Creates new user account
  /// Throws [AuthException] on failure
  Future<UserEntity> signup(String name, String email, String password, String role);

  /// Retrieves currently authenticated user
  /// Returns null if no user is authenticated
  Future<UserEntity?> getCurrentUser();

  /// Updates user profile information
  /// Throws [AuthException] on failure
  Future<void> updateProfile(String name, String phone);

  /// Resets password without requiring the current password (forgot password flow)
  Future<void> resetPassword(String email, String newPassword);

  /// Changes user password
  /// Throws [AuthException] on failure
  Future<void> changePassword(String currentPassword, String newPassword);

  /// Signs out the current user
  /// Throws [AuthException] on failure
  Future<void> logout();
}
