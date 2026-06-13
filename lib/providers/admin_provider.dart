import 'package:flutter/foundation.dart';
import '../models/invite.dart';
import '../models/user.dart';
import '../services/admin_api_service.dart';

class AdminProvider extends ChangeNotifier {
  AdminApiService _apiService;

  AdminProvider(this._apiService);

  void updateApiService(AdminApiService newService) {
    final bool tokenChanged = _apiService.token != newService.token;
    _apiService = newService;

    if (tokenChanged && newService.token != null) {
      fetchInvites();
      fetchUsers();
    }
  }

  List<Invite> _invites = [];
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;

  List<Invite> get invites => _invites;
  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Davet kodlarını yükle
  Future<void> fetchInvites() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _invites = await _apiService.getInviteCodes();
    } catch (e) {
      _error = 'Davet kodları yüklenirken hata oluştu: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Kullanıcıları yükle
  Future<void> fetchUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _users = await _apiService.getUsers();
    } catch (e) {
      _error = 'Kullanıcılar yüklenirken hata oluştu: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Yeni davet kodu oluştur
  Future<bool> createInvite({required int maxUses, DateTime? expiresAt}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newInvite = await _apiService.createInviteCode(
        maxUses: maxUses,
        expiresAt: expiresAt,
      );
      if (newInvite != null) {
        _invites.insert(0, newInvite);
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Davet kodu oluşturulurken hata oluştu: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Davet kodunu sil
  Future<bool> deleteInvite(String code) async {
    try {
      final success = await _apiService.deleteInviteCode(code);
      if (success) {
        _invites.removeWhere((i) => i.code == code);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Kodu silerken hata oluştu: $e';
      return false;
    }
  }

  /// Kullanıcıyı sil
  Future<bool> deleteUser(String username) async {
    try {
      final success = await _apiService.deleteUser(username);
      if (success) {
        _users.removeWhere((u) => u.username == username);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Kullanıcı silinirken hata oluştu: $e';
      return false;
    }
  }
}
