import 'package:flutter/material.dart';
import '../../data/repositories/location_repository.dart';
import '../../domain/entities/provincia.dart';
import '../../domain/entities/ciudad.dart';

class LocationProvider extends ChangeNotifier {
  final LocationRepository _repository;

  List<Provincia> _provincias = [];
  List<Ciudad> _ciudades = []; 
  
  bool _loadingProvincias = false;
  bool _loadingCiudades = false;
  String? _error;

  LocationProvider({LocationRepository? repository}) 
    : _repository = repository ?? LocationRepository();

  List<Provincia> get provincias => List.unmodifiable(_provincias);
  List<Ciudad> get ciudades => List.unmodifiable(_ciudades);
  bool get loadingProvincias => _loadingProvincias;
  bool get loadingCiudades => _loadingCiudades;
  String? get error => _error;

  Future<void> loadProvincias() async {
    _loadingProvincias = true;
    _error = null;
    notifyListeners();
    try {
      _provincias = await _repository.getProvincias();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loadingProvincias = false;
      notifyListeners();
    }
  }

  Future<void> loadCiudades(String provinciaId) async {
    _loadingCiudades = true;
    _error = null;
    notifyListeners();
    try {
      _ciudades = await _repository.getCiudadesByProvincia(provinciaId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loadingCiudades = false;
      notifyListeners();
    }
  }

  void clearCiudades() {
    _ciudades = [];
    notifyListeners();
  }
}
