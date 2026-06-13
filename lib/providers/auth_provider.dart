import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// Kimlik doğrulama state yönetimi
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  String get token => _user?.token ?? '';

  /// Başlangıçta token kontrolü
  Future<bool> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    final storedUser = await _authService.loadStoredUser();
    _user = storedUser;

    _isLoading = false;
    _isInitialized = true;
    notifyListeners();

    return _user != null;
  }

  /// Giriş yap
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.login(
      username: username,
      password: password,
    );

    _isLoading = false;

    if (result.success && result.user != null) {
      _user = result.user;
      _error = null;
      notifyListeners();
      return true;
    } else {
      _error = result.error;
      notifyListeners();
      return false;
    }
  }

  /// Kayıt ol
  Future<bool> register({
    required String inviteCode,
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.register(
      inviteCode: inviteCode,
      username: username,
      password: password,
    );

    _isLoading = false;

    if (result.success && result.user != null) {
      _user = result.user;
      _error = null;
      notifyListeners();
      return true;
    } else {
      _error = result.error;
      notifyListeners();
      return false;
    }
  }

  /// Davet kodunu doğrula
  Future<({bool valid, String? error})> validateInvite(String code) async {
    return await _authService.validateInviteCode(code);
  }

  /// Hatayı temizle
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Çıkış yap
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _error = null;
    notifyListeners();
  }
}
