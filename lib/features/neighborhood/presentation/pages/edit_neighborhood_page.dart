import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_background.dart';
import '../providers/neighborhood_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/data/models/user_model.dart';
import '../../domain/entities/neighborhood.dart';
import '../../../location/presentation/providers/location_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditNeighborhoodPage extends StatefulWidget {
  final Barrio barrio;

  const EditNeighborhoodPage({super.key, required this.barrio});

  @override
  State<EditNeighborhoodPage> createState() => _EditNeighborhoodPageState();
}

class _EditNeighborhoodPageState extends State<EditNeighborhoodPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _whatsappController;
  String? _selectedProvinciaId;
  String? _selectedCiudadId;
  String? _selectedSupervisorId;
  String? _selectedPresidenteId;

  UserModel? _currentSupervisor;
  UserModel? _currentPresidente;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.barrio.nombre);
    _whatsappController = TextEditingController(
      text: widget.barrio.whatsappUrl ?? '',
    );
    _selectedCiudadId = widget.barrio.ciudadId.isNotEmpty
        ? widget.barrio.ciudadId
        : null;
    _selectedSupervisorId = widget.barrio.supervisorId;
    _selectedPresidenteId = widget.barrio.presidenteId;

    _loadInitialUsers();
    _loadLocationData();
  }

  Future<void> _loadLocationData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final locationProvider = context.read<LocationProvider>();
      await locationProvider.loadProvincias();

      if (_selectedCiudadId != null) {
        try {
          final res = await Supabase.instance.client
              .from('ciudades')
              .select('provincia_id')
              .eq('id', _selectedCiudadId!)
              .maybeSingle();
          if (res != null && mounted) {
            setState(() {
              _selectedProvinciaId = res['provincia_id'];
            });
            await locationProvider.loadCiudades(_selectedProvinciaId!);
          }
        } catch (_) {}
      }
    });
  }

  Future<void> _loadInitialUsers() async {
    try {
      if (_selectedSupervisorId != null) {
        final res = await Supabase.instance.client
            .from('perfiles')
            .select('*, barrios:barrios!perfiles_barrio_id_fkey(nombre)')
            .eq('id', _selectedSupervisorId!)
            .maybeSingle();
        if (res != null && mounted)
          setState(() => _currentSupervisor = UserModel.fromJson(res));
      }
      if (_selectedPresidenteId != null) {
        final res = await Supabase.instance.client
            .from('perfiles')
            .select('*, barrios:barrios!perfiles_barrio_id_fkey(nombre)')
            .eq('id', _selectedPresidenteId!)
            .maybeSingle();
        if (res != null && mounted)
          setState(() => _currentPresidente = UserModel.fromJson(res));
      }
    } catch (_) {}
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

    final success = await context.read<NeighborhoodProvider>().updateBarrio(
      widget.barrio.id,
      nombre: _nombreController.text.trim(),
      ciudadId: _selectedCiudadId!,
      whatsappUrl: _whatsappController.text.trim().isEmpty
          ? null
          : _whatsappController.text.trim(),
      supervisorId: _selectedSupervisorId,
      presidenteId: _selectedPresidenteId,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Barrio actualizado exitosamente'),
          backgroundColor: AppColors.green,
        ),
      );
      context.pop();
    } else {
      final error = context.read<NeighborhoodProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Error al actualizar el barrio'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Verificamos que el usuario tiene el rol 'admin' o 'presidente_barrio'
    // Verificamos que el usuario tiene el rol 'admin' o 'presidente_barrio' o 'supervisor'
    final user = context.watch<AuthProvider>().user;
    final isAdmin = user?.rol == 'admin';
    final canEdit =
        isAdmin ||
        user?.rol == 'presidente_barrio' ||
        user?.rol == 'supervisor';

    if (!canEdit) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acceso Denegado')),
        body: const Center(
          child: Text('No tienes permisos para editar este barrio.'),
        ),
      );
    }

    // Si es presidente de barrio o supervisor, solo puede editar su propio barrio
    if ((user?.rol == 'presidente_barrio' || user?.rol == 'supervisor') &&
        user?.barrioId != widget.barrio.id) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acceso Denegado')),
        body: const Center(child: Text('Solo puedes editar tu propio barrio.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text(
          'Editar Barrio',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                  'Modifica los datos del barrio según sea necesario.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    prefixIcon: const Icon(
                      Icons.location_city,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'El nombre es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedProvinciaId,
                  decoration: InputDecoration(
                    labelText: 'Provincia',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    prefixIcon: const Icon(
                      Icons.map,
                      color: AppColors.textSecondary,
                    ),
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
                  validator: (val) =>
                      val == null ? 'Seleccione una provincia' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCiudadId,
                  decoration: InputDecoration(
                    labelText: 'Ciudad',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    prefixIcon: const Icon(
                      Icons.location_city,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary),
                  items: context.watch<LocationProvider>().ciudades.map((c) {
                    return DropdownMenuItem(value: c.id, child: Text(c.nombre));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedCiudadId = val;
                      });
                    }
                  },
                  validator: (val) =>
                      val == null ? 'Seleccione una ciudad' : null,
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    prefixIcon: const Icon(
                      Icons.link,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  validator: (val) {
                    if (val != null && val.isNotEmpty) {
                      final uri = Uri.tryParse(val.trim());
                      if (uri == null ||
                          !uri.hasAbsolutePath ||
                          !val.contains('whatsapp.com')) {
                        return 'Ingresa una URL de WhatsApp válida (ej: chat.whatsapp.com/...)';
                      }
                    }
                    return null;
                  },
                ),
                if (isAdmin) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Asignación de Roles (Solo Admin)',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRoleSelector(
                    title: 'Supervisor Asignado',
                    icon: Icons.security,
                    currentUser: _currentSupervisor,
                    onSelect: () => _openSearchDialog(
                      roleName: 'Supervisor',
                      mustBeFromBarrio: false,
                      onAssign: (user) {
                        setState(() {
                          _selectedSupervisorId = user.id;
                          _currentSupervisor = user;
                        });
                      },
                    ),
                    onClear: () {
                      setState(() {
                        _selectedSupervisorId = null;
                        _currentSupervisor = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildRoleSelector(
                    title: 'Presidente de Barrio',
                    icon: Icons.person,
                    currentUser: _currentPresidente,
                    onSelect: () => _openSearchDialog(
                      roleName: 'Presidente',
                      mustBeFromBarrio: true,
                      onAssign: (user) {
                        setState(() {
                          _selectedPresidenteId = user.id;
                          _currentPresidente = user;
                        });
                      },
                    ),
                    onClear: () {
                      setState(() {
                        _selectedPresidenteId = null;
                        _currentPresidente = null;
                      });
                    },
                  ),
                ],
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Guardar Cambios',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector({
    required String title,
    required IconData icon,
    required UserModel? currentUser,
    required VoidCallback onSelect,
    required VoidCallback onClear,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: currentUser != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUser.nombreCompleto,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'C.I: ${currentUser.cedula}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Ninguno asignado',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
              ),
              if (currentUser != null)
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.red),
                  onPressed: onClear,
                  tooltip: 'Remover asignación',
                ),
              ElevatedButton.icon(
                onPressed: onSelect,
                icon: const Icon(Icons.search, size: 16),
                label: const Text('Buscar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success.withOpacity(0.1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openSearchDialog({
    required String roleName,
    required bool mustBeFromBarrio,
    required Function(UserModel) onAssign,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return _UserSearchDialog(
          roleName: roleName,
          mustBeFromBarrio: mustBeFromBarrio,
          barrioId: widget.barrio.id,
          onAssign: onAssign,
        );
      },
    );
  }
}

class _UserSearchDialog extends StatefulWidget {
  final String roleName;
  final bool mustBeFromBarrio;
  final String barrioId;
  final Function(UserModel) onAssign;

  const _UserSearchDialog({
    required this.roleName,
    required this.mustBeFromBarrio,
    required this.barrioId,
    required this.onAssign,
  });

  @override
  State<_UserSearchDialog> createState() => _UserSearchDialogState();
}

class _UserSearchDialogState extends State<_UserSearchDialog> {
  final _cedulaController = TextEditingController();
  bool _isLoading = false;
  UserModel? _foundUser;
  String? _errorMsg;

  Future<void> _search() async {
    final cedula = _cedulaController.text.trim();
    if (cedula.isEmpty) return;

    setState(() {
      _isLoading = true;
      _foundUser = null;
      _errorMsg = null;
    });

    try {
      final res = await Supabase.instance.client
          .from('perfiles')
          .select('*, barrios:barrios!perfiles_barrio_id_fkey(nombre)')
          .eq('cedula', cedula)
          .maybeSingle();

      if (res == null) {
        setState(
          () => _errorMsg = 'No se encontró ningún usuario con esa cédula.',
        );
      } else {
        final user = UserModel.fromJson(res);
        if (widget.mustBeFromBarrio && user.barrioId != widget.barrioId) {
          setState(
            () => _errorMsg =
                'El usuario existe pero pertenece a otro barrio (${user.barrioNombre ?? "ninguno"}). Para Presidente, el usuario debe pertenecer a este barrio.',
          );
        } else {
          setState(() => _foundUser = user);
        }
      }
    } catch (e) {
      setState(() => _errorMsg = 'Ocurrió un error al buscar.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardDark,
      title: Text(
        'Buscar',
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ingrese el número de cédula del usuario que desea asignar.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cedulaController,
              style: const TextStyle(color: AppColors.textPrimary),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Número de Cédula',
                labelStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.bgDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.profilePrimary),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.search,
                    color: AppColors.profilePrimary,
                  ),
                  onPressed: _search,
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 24),
              const Center(
                child: CircularProgressIndicator(
                  color: AppColors.profilePrimary,
                ),
              ),
            ],
            if (_errorMsg != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMsg!,
                style: const TextStyle(color: AppColors.red, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
            if (_foundUser != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.profilePrimary.withOpacity(0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Datos Encontrados:',
                      style: TextStyle(
                        color: AppColors.profilePrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nombre: ${_foundUser!.nombreCompleto}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Cédula: ${_foundUser!.cedula}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Ciudad/Dirección: ${_foundUser!.direccion}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Barrio: ${_foundUser!.barrioNombre ?? "No asignado"}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
        ElevatedButton(
          onPressed: _foundUser == null
              ? null
              : () {
                  widget.onAssign(_foundUser!);
                  Navigator.of(context).pop();
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.profilePrimary,
            foregroundColor: Colors.white,
          ),
          child: const Text(
            'Asignar',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
