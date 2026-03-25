import 'package:flutter/material.dart';
import '../../data/repositories/admin_repository.dart';
import '../../../auth/data/models/user_model.dart';

class AdminProvider extends ChangeNotifier {
  final AdminRepository _repository;
  
  AdminProvider(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<UserModel> _pendingUsers = [];
  List<UserModel> get pendingUsers => _pendingUsers;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchPendingUsers(String? barrioId, {bool isAdmin = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (isAdmin) {
        _pendingUsers = await _repository.getAllPendingUsers();
      } else if (barrioId != null) {
        _pendingUsers = await _repository.getPendingUsers(barrioId);
      } else {
        _pendingUsers = [];
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveUser(String userId, String barrioId) async {
    return await _updateUserStatus(userId, 'aprobado', barrioId);
  }

  Future<bool> rejectUser(String userId, String barrioId) async {
    return await _updateUserStatus(userId, 'rechazado', barrioId);
  }

  Future<bool> _updateUserStatus(String userId, String status, String barrioId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateUserStatus(userId, status);
      // Remove the user from the list instead of fetching again for better UX
      _pendingUsers.removeWhere((user) => user.id == userId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
