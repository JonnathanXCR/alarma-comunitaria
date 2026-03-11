import 'package:flutter/material.dart';

import '../../data/repositories/neighborhood_repository.dart';
import '../../domain/entities/neighborhood.dart';

class NeighborhoodProvider extends ChangeNotifier {
  final NeighborhoodRepository _repository;

  List<Barrio> _barrios = [];
  Barrio? _selected;
  bool _loading = false;
  String? _error;

  NeighborhoodProvider({NeighborhoodRepository? repository})
    : _repository = repository ?? NeighborhoodRepository();

  List<Barrio> get barrios => List.unmodifiable(_barrios);
  Barrio? get selected => _selected;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadBarrios() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _barrios = await _repository.getBarrios();
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  void selectBarrio(Barrio barrio) {
    _selected = barrio;
    notifyListeners();
  }
}
