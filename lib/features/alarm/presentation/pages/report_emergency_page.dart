import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../providers/alarm_provider.dart';

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
      lugar: _lugarController.text.trim(),
      quePaso: _quePasoController.text.trim(),
      descripcion: _detailsController.text.trim(),
      latitud: position?.latitude,
      longitud: position?.longitude,
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

                      // Header (Type of Report)
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
                                color: secondaryColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: secondaryColor.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Icon(icon, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TIPO DE ALERTA',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    title,
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontSize: 18,
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
                              'Detalles Adicionales',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            const SizedBox(height: 20),

                            if (!_hasText)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Text(
                                  '* Debes completar todos los campos para habilitar el envío.',
                                  style: TextStyle(
                                    color: AppColors.red.withValues(alpha: 0.8),
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),

                            Text(
                              'Lugar',
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
                              '¿Qué pasó?',
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
                              'Descripción extra',
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
                                  ? 'Aspecto del sospechoso, hacia dónde fue...'
                                  : 'Detalles adicionales, número de heridos...',
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Acción Botones (Paralelos)
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
