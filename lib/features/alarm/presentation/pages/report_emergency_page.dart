import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/alarm_provider.dart';
import '../../domain/entities/alert.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/globals.dart';

class ReportEmergencyPage extends StatefulWidget {
  final bool isSuspect;

  const ReportEmergencyPage({super.key, required this.isSuspect});

  @override
  State<ReportEmergencyPage> createState() => _ReportEmergencyPageState();
}

class _ReportEmergencyPageState extends State<ReportEmergencyPage> {
  final _lugarController = TextEditingController();
  final _quePasoController = TextEditingController();
  final _detailsController = TextEditingController();
  bool _hasText = false;
  bool _isGettingLocation = false;
  File? _selectedImage;
  TipoEmergencia _selectedTipo = TipoEmergencia.roboVia;

  @override
  void initState() {
    super.initState();
    void updateState() {
      setState(() {
        _hasText =
            _lugarController.text.trim().isNotEmpty &&
            _quePasoController.text.trim().isNotEmpty &&
            _detailsController.text.trim().isNotEmpty;
      });
    }

    _lugarController.addListener(updateState);
    _quePasoController.addListener(updateState);
    _detailsController.addListener(updateState);
  }

  @override
  void dispose() {
    _lugarController.dispose();
    _quePasoController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1024,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al capturar la foto: $e'),
            backgroundColor: AppColors.redBright,
          ),
        );
      }
    }
  }

  void _submitReport() async {
    if (!_hasText) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Por favor, completa todos los campos antes de enviar el reporte.',
          ),
          backgroundColor: AppColors.redBright,
        ),
      );
      return;
    }

    setState(() {
      _isGettingLocation = true;
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }

      if (!mounted) return;
      bool? sendWithoutGps = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'GPS Desactivado',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: const Text(
            'Para poder enviar el reporte con tu ubicación, es necesario activar el GPS del dispositivo.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Enviar sin GPS',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
                Geolocator.openLocationSettings();
              },
              child: Text(
                'Activar GPS',
                style: TextStyle(
                  color: widget.isSuspect
                      ? AppColors.orangeBright
                      : AppColors.redBright,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );

      if (sendWithoutGps != true) {
        return;
      }
    }

    LocationPermission permission = LocationPermission.denied;
    if (serviceEnabled) {
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Permisos de ubicación denegados. Enviando reporte sin GPS.',
              ),
              backgroundColor: AppColors.orange,
            ),
          );
        }
      } else if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _isGettingLocation = false);
        }

        if (!mounted) return;
        bool? sendWithoutGps = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text(
              'Permisos Denegados',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: const Text(
              'Los permisos de ubicación están denegados permanentemente. Por favor, actívalos en la configuración de la aplicación.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Enviar sin GPS',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                  Geolocator.openAppSettings();
                },
                child: Text(
                  'Abrir Configuración',
                  style: TextStyle(
                    color: widget.isSuspect
                        ? AppColors.orangeBright
                        : AppColors.redBright,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );

        if (sendWithoutGps != true) {
          return;
        }
      }
    }

    Position? position;
    if (serviceEnabled &&
        (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always)) {
      try {
        if (mounted && !_isGettingLocation) {
          setState(() => _isGettingLocation = true);
        }
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (_) {
        // En caso de error, position será null y se enviará sin GPS
      }
    }

    if (mounted) {
      setState(() {
        _isGettingLocation = false;
      });
    }

    if (!mounted) return;

    final provider = context.read<AlarmProvider>();
    await provider.sendEmergencyAlert(
      tipo: widget.isSuspect ? TipoEmergencia.sospechoso : _selectedTipo,
      lugar: _lugarController.text.trim(),
      quePaso: _quePasoController.text.trim(),
      descripcion: _detailsController.text.trim(),
      latitud: position?.latitude,
      longitud: position?.longitude,
      imageFile: _selectedImage,
    );

    if (!mounted) return;

    if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar: ${provider.error}'),
          backgroundColor: AppColors.redBright,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      globalHasActiveAlert.value = true;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isSuspect
                ? 'Reporte de sospechoso enviado'
                : 'Alerta de emergencia enviada',
          ),
          backgroundColor: widget.isSuspect
              ? AppColors.orange
              : AppColors.redBright,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.isSuspect
        ? AppColors.orangeBright
        : AppColors.redBright;
    final secondaryColor = widget.isSuspect ? AppColors.orange : AppColors.red;
    final title = widget.isSuspect ? 'REPORTE DE SOSPECHOSO' : 'EMERGENCIA SOS';
    final icon = widget.isSuspect
        ? Icons.visibility_rounded
        : Icons.health_and_safety_rounded;
    final alarmProvider = context.watch<AlarmProvider>();
    final isBusy = alarmProvider.isSending || _isGettingLocation;

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
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Reporte Detallado',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      const SizedBox(height: 12),

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
                            Text(
                              title,
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 20),

                            if (!widget.isSuspect) ...[
                              const Text(
                                'Tipo de Emergencia',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _buildTypeButton('Robo en la Vía', TipoEmergencia.roboVia, primaryColor),
                                  _buildTypeButton('Robo de Casa', TipoEmergencia.roboCasa, primaryColor),
                                  _buildTypeButton('Secuestro', TipoEmergencia.secuestro, primaryColor),
                                  _buildTypeButton('Asesinato', TipoEmergencia.asesinato, primaryColor),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],

                            if (!_hasText)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Text(
                                  '* COMPLETA TODOS LOS CAMPOS PARA PODER ENVIAR EL REPORTE.',
                                  style: TextStyle(
                                    color: AppColors.red.withValues(alpha: 0.8),
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),

                            Text(
                              'Dirección - Lugar de Referencia \n Se enviara la ubicación GPS',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildTextField(
                              controller: _lugarController,
                              hintText: 'Ej: Frente al parque, calle principal',
                            ),
                            const SizedBox(height: 16),

                            Text(
                              '¿Cual es la emergencia?',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildTextField(
                              controller: _quePasoController,
                              hintText: 'Breve resumen de la situación',
                            ),
                            const SizedBox(height: 16),

                            Text(
                              'Datos del Sospechoso',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),

                            _buildTextField(
                              controller: _detailsController,
                              maxLines: 4,
                              hintText: widget.isSuspect
                                  ? 'Características del sospechoso, Ropa  \n Hacia dónde se dirige\n Vehículo: Carro/Moto,  Color, Tipo, Placa'
                                  : 'Características del sospechoso, Ropa  \n Hacia dónde se dirige\n Vehículo: Carro/Moto,  Color, Tipo, Placa',
                            ),
                            const SizedBox(height: 16),

                            Text(
                              'Foto Adjunta (Opcional)',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (_selectedImage != null)
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      _selectedImage!,
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _selectedImage = null),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              OutlinedButton.icon(
                                onPressed: _takePhoto,
                                icon: Icon(
                                  Icons.camera_alt,
                                  color: primaryColor,
                                ),
                                label: Text(
                                  'Tomar Foto',
                                  style: TextStyle(color: primaryColor),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  side: BorderSide(
                                    color: primaryColor.withOpacity(0.3),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Acción Botones (Paralelos)
                      const Text(
                        'Enviar más información al grupo de WhatsApp',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
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
                                  side: BorderSide(color: AppColors.border),
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
                              onPressed: (isBusy || !_hasText)
                                  ? null
                                  : _submitReport,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: isBusy
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'ENVIAR REPORTE',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String text, TipoEmergencia type, Color primaryColor) {
    final isSelected = _selectedTipo == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTipo = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
  }) {
    final primaryColor = widget.isSuspect
        ? AppColors.orangeBright
        : AppColors.redBright;

    return TextField(
      controller: controller,
      maxLines: maxLines,
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
          borderSide: BorderSide(color: primaryColor),
        ),
      ),
    );
  }
}
