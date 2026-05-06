// dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/signup_usecase.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  final LoginUseCase _loginUseCase;
  final SignupUseCase _signupUseCase;

  AuthProvider(this._repository, this._loginUseCase, this._signupUseCase);

  UserEntity? _user;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  UserEntity? get user => _user;
  bool get isInitialized => _isInitialized;
  bool get loading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get userRole => _user?.role;
  String? get error => _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();
    try {
      final current = await _repository.getCurrentUser();
      _user = current;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  String _mapError(dynamic e) {
    final msg = e.toString().toLowerCase();
    debugPrint('[AuthProvider] _mapError: $e');
    // API backend errors
    if (msg.contains('invalid email or password')) return 'Invalid email or password.';
    if (msg.contains('email already registered')) return 'Email is already registered.';
    if (msg.contains('access denied')) return 'Access denied. Please use the correct login portal.';
    if (msg.contains('deactivated')) return 'Your account has been deactivated. Please contact admin.';
    if (msg.contains('current password is incorrect')) return 'Current password is incorrect.';
    if (msg.contains('user not found')) return 'No user found with this email.';
    // Legacy Firebase error codes (kept for safety)
    if (msg.contains('invalid-credential')) return 'Invalid email or password.';
    if (msg.contains('user-not-found')) return 'No user found with this email.';
    if (msg.contains('wrong-password')) return 'Incorrect password.';
    if (msg.contains('email-already-in-use')) return 'Email is already registered.';
    if (msg.contains('weak-password')) return 'Password is too weak.';
    if (msg.contains('invalid-email')) return 'Invalid email address.';
    if (msg.contains('too-many-requests')) return 'Too many attempts. Please try again later.';
    if (msg.contains('user-disabled')) return 'This account has been disabled.';
    if (msg.contains('connection refused') || msg.contains('socketexception') || msg.contains('network')) {
      return 'Cannot connect to server. Make sure the backend is running.';
    }
    debugPrint('[AuthProvider] Unrecognized error: $e');
    return 'An error occurred. Please try again.';
  }

  Future<bool> login(String email, String password, {String selectedRole = 'customer'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      debugPrint('[AuthProvider] Starting login for: $email with selectedRole: $selectedRole');
      final logged = await _loginUseCase.execute(email, password, selectedRole: selectedRole);
      debugPrint('[AuthProvider] Login result: ${logged?.email}, role: ${logged?.role}');
      if (logged == null) {
        _errorMessage = 'Login failed. User not found.';
        notifyListeners();
        return false;
      }

      if (logged.role != selectedRole) {
        debugPrint('[AuthProvider] Role mismatch. Expected: $selectedRole, Got: ${logged.role}');
        await _repository.logout();
        _errorMessage = 'Access denied. Please use the correct login portal.';
        notifyListeners();
        return false;
      }

      _user = logged;
      _errorMessage = null;
      debugPrint('[AuthProvider] Login successful, user set: ${_user?.email}');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[AuthProvider] Login error caught: $e');
      debugPrint('[AuthProvider] Login error type: ${e.runtimeType}');
      _errorMessage = _mapError(e);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signup(String name, String email, String password, String role) async {
    _isLoading = true;
    notifyListeners();
    try {
      final created = await _signupUseCase.execute(name, email, password, role);
      _user = created;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _mapError(e);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ... (keep other methods but apply mapping if critical, but login/signup are main ones)

  Future<void> logout() async {
    try {
      await _repository.logout();
      _user = null;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = _mapError(e); // Optional: logout errors rarely shown
      notifyListeners();
    }
  }
  
  // Update other methods similarly or leave generic for now, concentrating on Login/Signup
  Future<bool> updateProfile(String name, String phone) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.updateProfile(name, phone);
      if (_user != null) {
        final updatedUser = await _repository.getCurrentUser();
        _user = updatedUser; 
      }
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _mapError(e);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.resetPassword(email, newPassword);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _mapError(e);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.changePassword(currentPassword, newPassword);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _mapError(e);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setInitialized(bool value) {
    _isInitialized = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
