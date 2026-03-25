import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../features/neighborhood/presentation/providers/neighborhood_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  late TextEditingController _telefonoController;
  late TextEditingController _direccionController;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // ── Paleta Stitch ──────────────────────────────
  static const _bg = Color(0xFF0D0D0D);
  static const _red = Color(0xFFD32F2F);
  static const _redLight = Color(0xFFEF5350);
  static const _textPrimary = Colors.white;
  static const _textSecondary = Color(0xFF9E9E9E);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(
        parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    final user = context.read<AuthProvider>().user;
    
    _nombreController = TextEditingController(text: user?.nombre ?? '');
    _apellidoController = TextEditingController(text: user?.apellido ?? '');
    _telefonoController = TextEditingController(text: user?.telefono ?? '');
    _direccionController = TextEditingController(text: user?.direccion ?? '');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final neighborhoodProvider = context.read<NeighborhoodProvider>();
      neighborhoodProvider.loadBarrios().then((_) {
        // Seleccionar el barrio actual del usuario
        if (user?.barrioId != null) {
          try {
            final currentBarrio = neighborhoodProvider.barrios.firstWhere(
                (b) => b.id == user!.barrioId);
            neighborhoodProvider.selectBarrio(currentBarrio);
          } catch (e) {
            // Barrio no encontrado en la lista
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    HapticFeedback.mediumImpact();

    final neighborhoodProvider = context.read<NeighborhoodProvider>();
    final barrioId = neighborhoodProvider.selected?.id;

    if (barrioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _red,
          content: const Text('Por favor selecciona tu barrio.'),
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();

    await authProvider.updateProfile(
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      telefono: _telefonoController.text.trim(),
      direccion: _direccionController.text.trim(),
      barrioId: barrioId,
    );

    if (mounted && authProvider.errorMessage == null) {
      // Regresa a la vista anterior; HomePage cambiará automáticamente a PendingApprovalPage
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final neighborProvider = context.watch<NeighborhoodProvider>();
    final isLoading = authProvider.status == AuthStatus.loading;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _textSecondary),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'EDITAR PERFIL',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          centerTitle: true,
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),

                    // Advertencia de re-aprobación
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF57C00).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFF57C00).withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: Color(0xFFF57C00)),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Importante: Si editas tu perfil, tu cuenta volverá a estado PENDIENTE y requerirá aprobación para usarse.',
                              style: TextStyle(
                                  color: Color(0xFFF57C00),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    const _FieldLabel('NOMBRES'),
                    const SizedBox(height: 8),
                    _StitchField(
                      controller: _nombreController,
                      hintText: 'Juan',
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requerido' : null,
                    ),

                    const SizedBox(height: 16),

                    const _FieldLabel('APELLIDOS'),
                    const SizedBox(height: 8),
                    _StitchField(
                      controller: _apellidoController,
                      hintText: 'Pérez',
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requerido' : null,
                    ),

                    const SizedBox(height: 16),

                    const _FieldLabel('TELÉFONO'),
                    const SizedBox(height: 8),
                    _StitchField(
                      controller: _telefonoController,
                      hintText: '09xxxxxxxx',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requerido' : null,
                    ),

                    const SizedBox(height: 16),

                    const _FieldLabel('DIRECCIÓN'),
                    const SizedBox(height: 8),
                    _StitchField(
                      controller: _direccionController,
                      hintText: 'Calle Principal y Secundaria',
                      prefixIcon: Icons.home_outlined,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requerido' : null,
                    ),

                    const SizedBox(height: 28),

                    const _FieldLabel('SELECCIONA TU BARRIO'),
                    const SizedBox(height: 8),
                    _BarrioDropdown(neighborProvider: neighborProvider),

                    const SizedBox(height: 28),

                    if (authProvider.errorMessage != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        authProvider.errorMessage!,
                        style: const TextStyle(color: _redLight, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                    ],

                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _red,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _red.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 4,
                          shadowColor: _red.withValues(alpha: 0.5),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'GUARDAR CAMBIOS',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Componentes de UI (reutilizados para EditProfilePage) ──

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF9E9E9E),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _StitchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _StitchField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  static const _surface = Color(0xFF1A1A1A);
  static const _border = Color(0xFF2C2C2C);
  static const _textSecondary = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      cursorColor: const Color(0xFFD32F2F),
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: _surface,
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF424242), fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: _textSecondary, size: 20),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFFEF5350), fontSize: 12),
      ),
    );
  }
}

class _BarrioDropdown extends StatelessWidget {
  final NeighborhoodProvider neighborProvider;
  const _BarrioDropdown({required this.neighborProvider});

  static const _surface = Color(0xFF1A1A1A);
  static const _border = Color(0xFF2C2C2C);

  @override
  Widget build(BuildContext context) {
    if (neighborProvider.loading) {
      return Container(
        height: 54,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border, width: 1.2),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Color(0xFF9E9E9E),
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          dropdownColor: const Color(0xFF1E1E1E),
          value: neighborProvider.selected?.id,
          hint: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Selecciona tu barrio…',
              style: TextStyle(color: Color(0xFF424242), fontSize: 14),
            ),
          ),
          icon: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.expand_more_rounded, color: Color(0xFF9E9E9E)),
          ),
          items: neighborProvider.barrios
              .map(
                (b) => DropdownMenuItem(
                  value: b.id,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '${b.nombre} • ${b.ciudadNombre ?? ''}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (id) {
            final barrio = neighborProvider.barrios.firstWhere(
              (b) => b.id == id,
            );
            context.read<NeighborhoodProvider>().selectBarrio(barrio);
          },
          selectedItemBuilder: (context) => neighborProvider.barrios
              .map(
                (b) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      b.nombre,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
