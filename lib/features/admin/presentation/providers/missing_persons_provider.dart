import 'package:flutter/material.dart';
import '../../data/models/missing_person_model.dart';
import '../../data/repositories/admin_repository.dart';

class MissingPersonsProvider extends ChangeNotifier {
  final AdminRepository _repository;

  List<MissingPersonModel> _missingPersons = [];
  bool _isLoading = false;
  String? _error;

  MissingPersonsProvider(this._repository);

  List<MissingPersonModel> get missingPersons => _missingPersons;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMissingPersons() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _missingPersons = await _repository.getMissingPersons();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addMissingPerson({
    required String nombre,
    required String contacto,
    required String lugar,
    required DateTime fecha,
    String? descripcion,
    dynamic imageFileBytes,
    String? originalFileName,
    int? edad,
    String? sexo,
    DateTime? fechaDesaparicion,
    String? ubicacion,
    String? ultimoLugarVisto,
    String? ciudadBarrio,
    String? estaturaAproximada,
    String? contextura,
    String? colorPiel,
    String? colorCabello,
    String? tipoCabello,
    String? colorOjos,
    String? tatuajes,
    String? cicatrices,
    bool? usoLentes,
    String? vestimentaSuperior,
    String? vestimentaInferior,
    String? zapatos,
    String? accesorios,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String? imageUrl;
      if (imageFileBytes != null && originalFileName != null) {
        final ext = originalFileName.split('.').last;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '$timestamp.$ext';
        imageUrl = await _repository.uploadMissingPersonImage(fileName, imageFileBytes);
      }

      final newPerson = await _repository.addMissingPerson(
        nombre: nombre,
        contacto: contacto,
        lugar: lugar,
        fecha: fecha,
        descripcion: descripcion,
        imagenUrl: imageUrl,
        edad: edad,
        sexo: sexo,
        fechaDesaparicion: fechaDesaparicion,
        ubicacion: ubicacion,
        ultimoLugarVisto: ultimoLugarVisto,
        ciudadBarrio: ciudadBarrio,
        estaturaAproximada: estaturaAproximada,
        contextura: contextura,
        colorPiel: colorPiel,
        colorCabello: colorCabello,
        tipoCabello: tipoCabello,
        colorOjos: colorOjos,
        tatuajes: tatuajes,
        cicatrices: cicatrices,
        usoLentes: usoLentes,
        vestimentaSuperior: vestimentaSuperior,
        vestimentaInferior: vestimentaInferior,
        zapatos: zapatos,
        accesorios: accesorios,
      );

      _missingPersons.insert(0, newPerson);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateMissingPerson({
    required String id,
    required String nombre,
    required String contacto,
    required String lugar,
    required DateTime fecha,
    String? descripcion,
    dynamic imageFileBytes,
    String? originalFileName,
    String? existingImageUrl,
    int? edad,
    String? sexo,
    DateTime? fechaDesaparicion,
    String? ubicacion,
    String? ultimoLugarVisto,
    String? ciudadBarrio,
    String? estaturaAproximada,
    String? contextura,
    String? colorPiel,
    String? colorCabello,
    String? tipoCabello,
    String? colorOjos,
    String? tatuajes,
    String? cicatrices,
    bool? usoLentes,
    String? vestimentaSuperior,
    String? vestimentaInferior,
    String? zapatos,
    String? accesorios,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String? imageUrl = existingImageUrl;
      if (imageFileBytes != null && originalFileName != null) {
        final ext = originalFileName.split('.').last;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '$timestamp.$ext';
        final uploadedUrl = await _repository.uploadMissingPersonImage(fileName, imageFileBytes);
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        }
      }

      final updated = await _repository.updateMissingPerson(
        id: id,
        nombre: nombre,
        contacto: contacto,
        lugar: lugar,
        fecha: fecha,
        descripcion: descripcion,
        imagenUrl: imageUrl,
        edad: edad,
        sexo: sexo,
        fechaDesaparicion: fechaDesaparicion,
        ubicacion: ubicacion,
        ultimoLugarVisto: ultimoLugarVisto,
        ciudadBarrio: ciudadBarrio,
        estaturaAproximada: estaturaAproximada,
        contextura: contextura,
        colorPiel: colorPiel,
        colorCabello: colorCabello,
        tipoCabello: tipoCabello,
        colorOjos: colorOjos,
        tatuajes: tatuajes,
        cicatrices: cicatrices,
        usoLentes: usoLentes,
        vestimentaSuperior: vestimentaSuperior,
        vestimentaInferior: vestimentaInferior,
        zapatos: zapatos,
        accesorios: accesorios,
      );

      final index = _missingPersons.indexWhere((p) => p.id == id);
      if (index != -1) {
        _missingPersons[index] = updated;
      }
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleStatus(String id, bool currentStatus) async {
    final index = _missingPersons.indexWhere((p) => p.id == id);
    if (index == -1) return;

    try {
      final newStatus = !currentStatus;
      await _repository.updateMissingPersonStatus(id, newStatus);
      
      _missingPersons[index] = _missingPersons[index].copyWith(activoEstado: newStatus);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
