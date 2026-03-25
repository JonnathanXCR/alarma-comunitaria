import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_background.dart';
import '../providers/neighborhood_provider.dart';
import '../../../location/presentation/providers/location_provider.dart';

class AddNeighborhoodPage extends StatefulWidget {
  const AddNeighborhoodPage({super.key});

  @override
  State<AddNeighborhoodPage> createState() => _AddNeighborhoodPageState();
}

class _AddNeighborhoodPageState extends State<AddNeighborhoodPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _whatsappController = TextEditingController();
  String? _selectedProvinciaId;
  String? _selectedCiudadId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().loadProvincias();
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await context.read<NeighborhoodProvider>().createBarrio(
          _nombreController.text.trim(),
          _selectedCiudadId!,
          whatsappUrl: _whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Barrio creado exitosamente'),
          backgroundColor: AppColors.green,
        ),
      );
      context.pop();
    } else {
      final error = context.read<NeighborhoodProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Error al crear el barrio'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Añadir Barrio', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: AppBackground(
        backgroundColor: AppColors.bg,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Ingresa los datos para registrar un nuevo barrio.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nombreController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Nombre del Barrio',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    prefixIcon: const Icon(Icons.location_city, color: AppColors.textSecondary),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'El nombre es requerido' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedProvinciaId,
                  decoration: InputDecoration(
                    labelText: 'Provincia',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    prefixIcon: const Icon(Icons.map, color: AppColors.textSecondary),
                  ),
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary),
                  items: context.watch<LocationProvider>().provincias.map((p) {
                    return DropdownMenuItem(value: p.id, child: Text(p.nombre));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedProvinciaId = val;
                        _selectedCiudadId = null;
                      });
                      context.read<LocationProvider>().loadCiudades(val);
                    }
                  },
                  validator: (val) => val == null ? 'Seleccione una provincia' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCiudadId,
                  decoration: InputDecoration(
                    labelText: 'Ciudad',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    prefixIcon: const Icon(Icons.location_city, color: AppColors.textSecondary),
                  ),
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary),
                  items: context.watch<LocationProvider>().ciudades.map((c) {
                    return DropdownMenuItem(value: c.id, child: Text(c.nombre));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCiudadId = val),
                  validator: (val) => val == null ? 'Seleccione una ciudad' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _whatsappController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: 'URL del Chat de WhatsApp (Opcional)',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    prefixIcon: const Icon(Icons.link, color: AppColors.textSecondary),
                  ),
                  validator: (val) {
                    if (val != null && val.isNotEmpty) {
                      final uri = Uri.tryParse(val.trim());
                      if (uri == null || !uri.hasAbsolutePath || !val.contains('whatsapp.com')) {
                        return 'Ingresa una URL de WhatsApp válida';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.profilePrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Crear Barrio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
