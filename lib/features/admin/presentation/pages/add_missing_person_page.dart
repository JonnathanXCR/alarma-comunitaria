import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/missing_person_model.dart';
import '../providers/missing_persons_provider.dart';

class AddMissingPersonPage extends StatefulWidget {
  final MissingPersonModel? personToEdit;

  const AddMissingPersonPage({super.key, this.personToEdit});

  bool get isEditing => personToEdit != null;

  @override
  State<AddMissingPersonPage> createState() => _AddMissingPersonPageState();
}

class _AddMissingPersonPageState extends State<AddMissingPersonPage> {
  final _formKey = GlobalKey<FormState>();

  // Basic info
  final _nombreController = TextEditingController();
  final _contactoController = TextEditingController();
  final _edadController = TextEditingController();
  String? _selectedSexo;

  // Disappearance details
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _ubicacionController = TextEditingController();
  final _ultimoLugarVistoController = TextEditingController();
  final _ciudadBarrioController = TextEditingController();

  // Physical description
  final _estaturaController = TextEditingController();
  String? _selectedContextura;
  final _colorPielController = TextEditingController();
  final _colorCabelloController = TextEditingController();
  final _tipoCabelloController = TextEditingController();
  final _colorOjosController = TextEditingController();
  final _tatuajesController = TextEditingController();
  final _cicatricesController = TextEditingController();
  bool _usoLentes = false;

  // Clothing
  final _vestimentaSuperiorController = TextEditingController();
  final _vestimentaInferiorController = TextEditingController();
  final _zapatosController = TextEditingController();
  final _accesoriosController = TextEditingController();

  File? _imageFile;
  String? _existingImageUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final person = widget.personToEdit;
    if (person != null) {
      _nombreController.text = person.nombre;
      _contactoController.text = person.contacto;
      _edadController.text = person.edad?.toString() ?? '';
      _selectedSexo = person.sexo;
      _selectedDate = person.fechaDesaparicion ?? person.fecha;
      _selectedTime = person.fechaDesaparicion != null
          ? TimeOfDay.fromDateTime(person.fechaDesaparicion!)
          : TimeOfDay.fromDateTime(person.fecha);
      _ubicacionController.text = person.ubicacion ?? '';
      _ultimoLugarVistoController.text = person.ultimoLugarVisto ?? '';
      _ciudadBarrioController.text = person.ciudadBarrio ?? '';
      _estaturaController.text = person.estaturaAproximada ?? '';
      _selectedContextura = person.contextura;
      _colorPielController.text = person.colorPiel ?? '';
      _colorCabelloController.text = person.colorCabello ?? '';
      _tipoCabelloController.text = person.tipoCabello ?? '';
      _colorOjosController.text = person.colorOjos ?? '';
      _tatuajesController.text = person.tatuajes ?? '';
      _cicatricesController.text = person.cicatrices ?? '';
      _usoLentes = person.usoLentes ?? false;
      _vestimentaSuperiorController.text = person.vestimentaSuperior ?? '';
      _vestimentaInferiorController.text = person.vestimentaInferior ?? '';
      _zapatosController.text = person.zapatos ?? '';
      _accesoriosController.text = person.accesorios ?? '';
      _existingImageUrl = person.imagenUrl;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _contactoController.dispose();
    _edadController.dispose();
    _ubicacionController.dispose();
    _ultimoLugarVistoController.dispose();
    _ciudadBarrioController.dispose();
    _estaturaController.dispose();
    _colorPielController.dispose();
    _colorCabelloController.dispose();
    _tipoCabelloController.dispose();
    _colorOjosController.dispose();
    _tatuajesController.dispose();
    _cicatricesController.dispose();
    _vestimentaSuperiorController.dispose();
    _vestimentaInferiorController.dispose();
    _zapatosController.dispose();
    _accesoriosController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.orangeBright,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      if (!mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: _selectedTime ?? TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.orangeBright,
                onPrimary: Colors.white,
                surface: AppColors.surface,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = pickedDate;
          _selectedTime = pickedTime;
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor revisa los campos requeridos marcados en rojo.',
          ),
          backgroundColor: AppColors.orange,
        ),
      );
      return;
    }

    if (_imageFile == null && _existingImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La foto reciente es obligatoria.'),
          backgroundColor: AppColors.orange,
        ),
      );
      return;
    }

    if (_selectedSexo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona el sexo'),
          backgroundColor: AppColors.orange,
        ),
      );
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona la fecha y hora de desaparición'),
          backgroundColor: AppColors.orange,
        ),
      );
      return;
    }

    final provider = context.read<MissingPersonsProvider>();

    final dateTimeCombined = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    // We get the bytes from the file if we selected an image
    dynamic fileBytes = _imageFile;
    String? fileName = _imageFile?.path.split('/').last ?? _imageFile?.path.split('\\').last;

    int? parsedAge = int.tryParse(_edadController.text.trim());

    final bool success;

    if (widget.isEditing) {
      success = await provider.updateMissingPerson(
        id: widget.personToEdit!.id,
        nombre: _nombreController.text.trim(),
        contacto: _contactoController.text.trim(),
        lugar: _ubicacionController.text.trim().isNotEmpty
            ? _ubicacionController.text.trim()
            : _ciudadBarrioController.text.trim(),
        fecha: dateTimeCombined,
        fechaDesaparicion: dateTimeCombined,
        imageFileBytes: fileBytes,
        originalFileName: fileName,
        existingImageUrl: _existingImageUrl,
        edad: parsedAge,
        sexo: _selectedSexo,
        ubicacion: _ubicacionController.text.trim(),
        ultimoLugarVisto: _ultimoLugarVistoController.text.trim(),
        ciudadBarrio: _ciudadBarrioController.text.trim(),
        estaturaAproximada: _estaturaController.text.trim(),
        contextura: _selectedContextura,
        colorPiel: _colorPielController.text.trim(),
        colorCabello: _colorCabelloController.text.trim(),
        tipoCabello: _tipoCabelloController.text.trim(),
        colorOjos: _colorOjosController.text.trim(),
        tatuajes: _tatuajesController.text.trim(),
        cicatrices: _cicatricesController.text.trim(),
        usoLentes: _usoLentes,
        vestimentaSuperior: _vestimentaSuperiorController.text.trim(),
        vestimentaInferior: _vestimentaInferiorController.text.trim(),
        zapatos: _zapatosController.text.trim(),
        accesorios: _accesoriosController.text.trim(),
      );
    } else {
      success = await provider.addMissingPerson(
        nombre: _nombreController.text.trim(),
        contacto: _contactoController.text.trim(),
        lugar: _ubicacionController.text.trim().isNotEmpty
            ? _ubicacionController.text.trim()
            : _ciudadBarrioController.text.trim(),
        fecha: dateTimeCombined,
        fechaDesaparicion: dateTimeCombined,
        imageFileBytes: fileBytes,
        originalFileName: fileName,
        edad: parsedAge,
        sexo: _selectedSexo,
        ubicacion: _ubicacionController.text.trim(),
        ultimoLugarVisto: _ultimoLugarVistoController.text.trim(),
        ciudadBarrio: _ciudadBarrioController.text.trim(),
        estaturaAproximada: _estaturaController.text.trim(),
        contextura: _selectedContextura,
        colorPiel: _colorPielController.text.trim(),
        colorCabello: _colorCabelloController.text.trim(),
        tipoCabello: _tipoCabelloController.text.trim(),
        colorOjos: _colorOjosController.text.trim(),
        tatuajes: _tatuajesController.text.trim(),
        cicatrices: _cicatricesController.text.trim(),
        usoLentes: _usoLentes,
        vestimentaSuperior: _vestimentaSuperiorController.text.trim(),
        vestimentaInferior: _vestimentaInferiorController.text.trim(),
        zapatos: _zapatosController.text.trim(),
        accesorios: _accesoriosController.text.trim(),
      );
    }

    if (!mounted) return;

    if (success) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEditing ? 'Caso actualizado exitosamente' : 'Caso registrado exitosamente'),
          backgroundColor: AppColors.green,
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Error', style: TextStyle(color: AppColors.red)),
          content: Text(
            provider.error ?? 'Error desconocido',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Aceptar',
                style: TextStyle(color: AppColors.orangeBright),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MissingPersonsProvider>();
    final isBusy = provider.isLoading;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            widget.isEditing ? 'Editar Caso' : 'Registrar Caso',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: isBusy
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.orangeBright,
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Header Card
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.orange,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.orange.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person_search_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'REGISTRO OFICIAL',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'PERSONA DESAPARECIDA',
                                    style: TextStyle(
                                      color: AppColors.orangeBright,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Section: Identificación básica
                      _buildSectionHeader(
                        'Identificación Básica',
                        Icons.badge_rounded,
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildLabel('Foto Reciente (Obligatoria) *'),
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                height: 180,
                                decoration: BoxDecoration(
                                  color: AppColors.bg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: (_imageFile != null || _existingImageUrl != null)
                                        ? AppColors.orange
                                        : AppColors.border,
                                    width: (_imageFile != null || _existingImageUrl != null) ? 2 : 1,
                                  ),
                                  image: _imageFile != null
                                      ? DecorationImage(
                                          image: FileImage(_imageFile!),
                                          fit: BoxFit.cover,
                                        )
                                      : _existingImageUrl != null
                                          ? DecorationImage(
                                              image: NetworkImage(_existingImageUrl!),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                ),
                                child: (_imageFile == null && _existingImageUrl == null)
                                    ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceLight,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.add_a_photo_rounded,
                                              color: AppColors.orangeBright,
                                              size: 32,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Toque para añadir una foto vital',
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 16),

                            _buildLabel('Nombre Completo *'),
                            _buildTextField(
                              controller: _nombreController,
                              hintText: 'Ej: Juan Pérez',
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('Edad *'),
                                      _buildTextField(
                                        controller: _edadController,
                                        hintText: 'Ej: 25',
                                        keyboardType: TextInputType.number,
                                        validator: (v) =>
                                            (v == null || v.isEmpty) ? 'Requerido' : null,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('Sexo *'),
                                      _buildDropdown(
                                        value: _selectedSexo,
                                        hint: 'Seleccione',
                                        items: const [
                                          'Masculino',
                                          'Femenino',
                                          'Otro',
                                        ],
                                        onChanged: (v) =>
                                            setState(() => _selectedSexo = v),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            _buildLabel(
                              'Teléfono de Contacto (Para reportes) *',
                            ),
                            _buildTextField(
                              controller: _contactoController,
                              hintText: 'Ej: 0991234567',
                              keyboardType: TextInputType.phone,
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Requerido' : null,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Section: Circunstancias de Desaparición
                      _buildSectionHeader(
                        'Circunstancias de Desaparición',
                        Icons.location_on_rounded,
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildLabel('Fecha y Hora de Desaparición *'),
                            InkWell(
                              onTap: _pickDateTime,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.bg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _selectedDate == null ||
                                              _selectedTime == null
                                          ? 'Seleccionar Fecha y Hora'
                                          : '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year} - ${_selectedTime!.format(context)}',
                                      style: TextStyle(
                                        color: _selectedDate == null
                                            ? AppColors.textSecondary
                                            : AppColors.textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.calendar_month_rounded,
                                      color: AppColors.orange,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            _buildLabel('Ubicación General'),
                            _buildTextField(
                              controller: _ubicacionController,
                              hintText: 'Ej: Sector sur de la ciudad',
                            ),
                            const SizedBox(height: 16),

                            _buildLabel('Último Lugar Donde Fue Visto *'),
                            _buildTextField(
                              controller: _ultimoLugarVistoController,
                              hintText: 'Ej: Saliendo del colegio Técnico',
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 16),

                            _buildLabel('Ciudad / Barrio *'),
                            _buildTextField(
                              controller: _ciudadBarrioController,
                              hintText: 'Ej: Cuenca / Totoracocha',
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Requerido' : null,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Section: Descripción Física
                      _buildSectionHeader(
                        'Descripción Física',
                        Icons.accessibility_new_rounded,
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('Estatura *'),
                                      _buildTextField(
                                        controller: _estaturaController,
                                        hintText: 'Ej: 1.70m',
                                        validator: (v) =>
                                            (v == null || v.isEmpty) ? 'Requerido' : null,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('Contextura'),
                                      _buildDropdown(
                                        value: _selectedContextura,
                                        hint: 'Seleccione',
                                        items: const [
                                          'Delgado',
                                          'Medio',
                                          'Robusto',
                                        ],
                                        onChanged: (v) => setState(
                                          () => _selectedContextura = v,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('Color de piel *'),
                                      _buildTextField(
                                        controller: _colorPielController,
                                        hintText: 'Ej: Trigueña',
                                        validator: (v) =>
                                            (v == null || v.isEmpty) ? 'Requerido' : null,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('Color de ojos'),
                                      _buildTextField(
                                        controller: _colorOjosController,
                                        hintText: 'Ej: Cafés',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('Color de cabello'),
                                      _buildTextField(
                                        controller: _colorCabelloController,
                                        hintText: 'Ej: Negro',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('Tipo de cabello'),
                                      _buildTextField(
                                        controller: _tipoCabelloController,
                                        hintText: 'Ej: Lacio, corto',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            _buildLabel('Tatuajes'),
                            _buildTextField(
                              controller: _tatuajesController,
                              hintText: 'Ej: Rosa en el antebrazo derecho',
                            ),
                            const SizedBox(height: 16),

                            _buildLabel('Cicatrices o marcas'),
                            _buildTextField(
                              controller: _cicatricesController,
                              hintText: 'Ej: Cicatriz en la ceja izquierda',
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                _buildLabel('¿Usa lentes?'),
                                const Spacer(),
                                Switch(
                                  value: _usoLentes,
                                  onChanged: (val) =>
                                      setState(() => _usoLentes = val),
                                  activeColor: AppColors.orangeBright,
                                  inactiveTrackColor: AppColors.border,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Section: Vestimenta
                      _buildSectionHeader(
                        'Vestimenta al Desaparecer',
                        Icons.checkroom_rounded,
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildLabel('Camiseta / Chaqueta (Colores)'),
                            _buildTextField(
                              controller: _vestimentaSuperiorController,
                              hintText: 'Ej: Chompa negra, camiseta roja',
                            ),
                            const SizedBox(height: 16),

                            _buildLabel('Pantalón / Falda (Colores)'),
                            _buildTextField(
                              controller: _vestimentaInferiorController,
                              hintText: 'Ej: Jean azul oscuro',
                            ),
                            const SizedBox(height: 16),

                            _buildLabel('Zapatos'),
                            _buildTextField(
                              controller: _zapatosController,
                              hintText: 'Ej: Deportivos blancos marca Nike',
                            ),
                            const SizedBox(height: 16),

                            _buildLabel('Accesorios (mochila, gorra, etc.)'),
                            _buildTextField(
                              controller: _accesoriosController,
                              hintText: 'Ej: Mochila negra, gorra azul',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                foregroundColor: AppColors.textSecondary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                              ),
                              child: const Text(
                                'CANCELAR',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.orangeBright,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                widget.isEditing ? 'ACTUALIZAR REPORTE' : 'GUARDAR REPORTE',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.orangeBright, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
        filled: true,
        fillColor: AppColors.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.orangeBright),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: value,
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      dropdownColor: AppColors.surface,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
        filled: true,
        fillColor: AppColors.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.orangeBright),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      icon: const Icon(
        Icons.arrow_drop_down_rounded,
        color: AppColors.textSecondary,
      ),
    );
  }
}
