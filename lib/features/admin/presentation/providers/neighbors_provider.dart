import 'package:flutter/material.dart';
import '../../../../features/auth/data/models/user_model.dart';
import '../../data/repositories/admin_repository.dart';

class NeighborsProvider extends ChangeNotifier {
  final AdminRepository _repository;

  NeighborsProvider({AdminRepository? repository})
      : _repository = repository ?? AdminRepository();

  List<UserModel> _allNeighbors = [];
  List<UserModel> _filteredNeighbors = [];
  
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<UserModel> get neighbors => _filteredNeighbors;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchNeighbors(String barrioId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allNeighbors = await _repository.getUsersByBarrio(barrioId);
      _filterNeighbors();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    _searchQuery = query.toLowerCase();
    _filterNeighbors();
  }

  void _filterNeighbors() {
    if (_searchQuery.isEmpty) {
      _filteredNeighbors = List.unmodifiable(_allNeighbors);
    } else {
      _filteredNeighbors = _allNeighbors.where((user) {
        final nombreCompleto = '${user.nombre} ${user.apellido}'.toLowerCase();
        final cedula = user.cedula.toLowerCase();
        return nombreCompleto.contains(_searchQuery) || cedula.contains(_searchQuery);
      }).toList();
    }
    _isLoading = false;
    notifyListeners();
  }
}
