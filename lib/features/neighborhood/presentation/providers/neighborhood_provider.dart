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

  Future<void> loadBarrios({
    String? role,
    String? userId,
    String? userBarrioId,
    String? provinciaId,
    String? ciudadId,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _barrios = await _repository.getBarrios(
        role: role,
        userId: userId,
        userBarrioId: userBarrioId,
        provinciaId: provinciaId,
        ciudadId: ciudadId,
      );
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

  Future<bool> createBarrio(String nombre, String ciudadId, {String? whatsappUrl}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final newBarrio = await _repository.createBarrio(nombre, ciudadId, whatsappUrl: whatsappUrl);
      _barrios = List.from(_barrios)..add(newBarrio);
      _barrios.sort((a, b) => a.nombre.compareTo(b.nombre));
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBarrio(
    String id, {
    String? nombre,
    String? ciudadId,
    String? whatsappUrl,
    String? supervisorId,
    String? presidenteId,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final updatedBarrio = await _repository.updateBarrio(
        id,
        nombre: nombre,
        ciudadId: ciudadId,
        whatsappUrl: whatsappUrl,
        supervisorId: supervisorId,
        presidenteId: presidenteId,
      );
      final index = _barrios.indexWhere((b) => b.id == id);
      if (index != -1) {
        _barrios[index] = updatedBarrio;
        _barrios.sort((a, b) => a.nombre.compareTo(b.nombre));
      }
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }
}
