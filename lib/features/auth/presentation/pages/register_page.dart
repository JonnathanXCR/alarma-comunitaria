import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../features/neighborhood/presentation/providers/neighborhood_provider.dart';
import '../providers/auth_provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // ── Paleta Stitch ──────────────────────────────
  static const _bg = Color(0xFF0D0D0D);
  static const _red = Color(0xFFD32F2F);
  static const _redLight = Color(0xFFEF5350);
  static const _textPrimary = Colors.white;
  static const _textSecondary = Color(0xFF9E9E9E);
  static const _textMuted = Color(0xFF424242);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
    // Cargar barrios al abrir la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NeighborhoodProvider>().loadBarrios();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cedulaController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _red,
          content: const Text('Debes aceptar los términos y condiciones.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();

    final neighborhoodProvider = context.read<NeighborhoodProvider>();
    final barrioId = neighborhoodProvider.selected?.id;

    final authProvider = context.read<AuthProvider>();
    final email = _emailController.text.trim();

    await authProvider.register(
      email: email,
      password: _passwordController.text,
      cedula: _cedulaController.text.trim(),
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      telefono: _telefonoController.text.trim(),
      direccion: _direccionController.text.trim(),
      barrioId: barrioId,
    );

    if (mounted && authProvider.errorMessage == null && authProvider.successMessage != null) {
      context.push(AppRoutes.otpVerification, extra: email);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final neighborProvider = context.watch<NeighborhoodProvider>();
    final isLoading = authProvider.status == AuthStatus.loading;

    // Si el registro fue exitoso, _listenAuthChanges en AuthProvider se encarga
    // de navegar. Aquí manejamos un banner de pendiente.
    final isPendiente =
        authProvider.status == AuthStatus.authenticated &&
        authProvider.user?.estadoAprobacion == 'pendiente';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
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
                    const SizedBox(height: 48),

                    // ── Encabezado ──────────────────────────────
                    _buildHeader(),

                    const SizedBox(height: 36),

                    // ── Sección: Cuenta ──────────────────────────
                    _SectionHeader(
                      icon: Icons.lock_person_rounded,
                      label: 'DATOS DE ACCESO',
                    ),
                    const SizedBox(height: 16),

                    const _FieldLabel('CORREO ELECTRÓNICO'),
                    const SizedBox(height: 8),
                    _StitchField(
                      controller: _emailController,
                      hintText: 'ejemplo@correo.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        final re = RegExp(
                          r'^[\w\-.]+@[\w\-]+(\.[a-zA-Z]{2,})+$',
                        );
                        if (!re.hasMatch(v.trim())) {
                          return 'Correo inválido';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    const _FieldLabel('CONTRASEÑA'),
                    const SizedBox(height: 8),
                    _StitchField(
                      controller: _passwordController,
                      hintText: '••••••••',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      suffixWidget: _EyeToggle(
                        isObscure: _obscurePassword,
                        onTap: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (v.length < 8) {
                          return 'Mínimo 8 caracteres';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    const _FieldLabel('CONFIRMAR CONTRASEÑA'),
                    const SizedBox(height: 8),
                    _StitchField(
                      controller: _confirmPasswordController,
                      hintText: '••••••••',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscureConfirm,
                      suffixWidget: _EyeToggle(
                        isObscure: _obscureConfirm,
                        onTap: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (v != _passwordController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 28),

                    // ── Sección: Perfil personal ─────────────────
                    _SectionHeader(
                      icon: Icons.person_rounded,
                      label: 'DATOS PERSONALES',
                    ),
                    const SizedBox(height: 16),

                    const _FieldLabel('CÉDULA / DOCUMENTO'),
                    const SizedBox(height: 8),
                    _StitchField(
                      controller: _cedulaController,
                      hintText: '010xxxxxxx',
                      prefixIcon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (v.length != 10) return 'Debe tener 10 dígitos';
                        if (!_isValidEcuadorianCedula(v)) {
                          return 'Cédula ecuatoriana inválida';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldLabel('NOMBRES'),
                              const SizedBox(height: 8),
                              _StitchField(
                                controller: _nombreController,
                                hintText: 'Juan',
                                prefixIcon: Icons.person_outline_rounded,
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Requerido' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldLabel('APELLIDOS'),
                              const SizedBox(height: 8),
                              _StitchField(
                                controller: _apellidoController,
                                hintText: 'Pérez',
                                prefixIcon: Icons.person_outline_rounded,
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Requerido' : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    const _FieldLabel('TELÉFONO'),
                    const SizedBox(height: 8),
                    _StitchField(
                      controller: _telefonoController,
                      hintText: '09xxxxxxxx',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (v.length != 10) return 'Debe tener 10 dígitos';
                        return null;
                      },
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

                    // ── Sección: Barrio ───────────────────────────
                    _SectionHeader(
                      icon: Icons.location_city_rounded,
                      label: 'BARRIO',
                    ),
                    const SizedBox(height: 16),

                    const _FieldLabel('SELECCIONA TU BARRIO'),
                    const SizedBox(height: 8),
                    _BarrioDropdown(neighborProvider: neighborProvider),

                    const SizedBox(height: 28),

                    // ── Estado pendiente banner ───────────────────
                    if (isPendiente)
                      _InfoBanner(
                        icon: Icons.hourglass_top_rounded,
                        color: const Color(0xFFF57C00),
                        text:
                            'Tu cuenta está pendiente de aprobación por un supervisor.',
                      ),

                    // ── Error ─────────────────────────────────────
                    if (authProvider.errorMessage != null) ...[
                      const SizedBox(height: 4),
                      _InfoBanner(
                        icon: Icons.warning_amber_rounded,
                        color: _redLight,
                        text: authProvider.errorMessage!,
                      ),
                    ],

                    // ── Éxito (Verificación de email) ────────────────
                    if (authProvider.successMessage != null) ...[
                      const SizedBox(height: 4),
                      _InfoBanner(
                        icon: Icons.mark_email_read_rounded,
                        color: const Color(0xFF4CAF50), // Verde
                        text: authProvider.successMessage!,
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Términos ──────────────────────────────────
                    _TermsCheckbox(
                      value: _acceptTerms,
                      onChanged: (v) => setState(() => _acceptTerms = v!),
                    ),

                    const SizedBox(height: 28),

                    // ── Botón Registrar ───────────────────────────
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
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'CREAR CUENTA',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Icon(Icons.person_add_rounded, size: 20),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Volver a login ────────────────────────────
                    Column(
                      children: [
                        const Text(
                          '¿Ya tienes una cuenta?',
                          style: TextStyle(color: _textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: const Text(
                            'INICIA SESIÓN',
                            style: TextStyle(
                              color: _redLight,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              decoration: TextDecoration.underline,
                              decorationColor: _redLight,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 36),

                    // ── Footer ────────────────────────────────────
                    const Text(
                      'Alarma Comunitaria v1.0.0 • 2025',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Icono escudo con pulso rojo
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: _red,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _red.withValues(alpha: 0.45),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.shield_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'ALARMA\nCOMUNITARIA',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 3.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Únete a la red de seguridad vecinal',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _textSecondary,
            fontSize: 13,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        // Chip "CREAR CUENTA"
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: _red.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _red.withValues(alpha: 0.4)),
          ),
          child: const Text(
            'CREAR CUENTA',
            style: TextStyle(
              color: _redLight,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  bool _isValidEcuadorianCedula(String cedula) {
    if (cedula.length != 10) return false;

    try {
      final provinceNum = int.parse(cedula.substring(0, 2));
      if (provinceNum < 1 || (provinceNum > 24 && provinceNum != 30)) {
        return false;
      }

      final thirdDigit = int.parse(cedula[2]);
      if (thirdDigit > 5) return false;

      final coefficients = [2, 1, 2, 1, 2, 1, 2, 1, 2];
      int sum = 0;

      for (int i = 0; i < 9; i++) {
        int result = int.parse(cedula[i]) * coefficients[i];
        if (result >= 10) result -= 9;
        sum += result;
      }

      final lastDigit = int.parse(cedula[9]);
      int checkDigit = 10 - (sum % 10);
      if (checkDigit == 10) checkDigit = 0;

      return checkDigit == lastDigit;
    } catch (e) {
      return false;
    }
  }
}

// ─────────────────────────────────────────────────────────
// Widgets reutilizables
// ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFD32F2F), size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFD32F2F),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: const Color(0xFF2C2C2C))),
      ],
    );
  }
}

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

class _EyeToggle extends StatelessWidget {
  final bool isObscure;
  final VoidCallback onTap;
  const _EyeToggle({required this.isObscure, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        isObscure ? 'VER' : 'OCULTAR',
        style: const TextStyle(
          color: Color(0xFF9E9E9E),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _StitchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixWidget;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  const _StitchField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixWidget,
    this.validator,
    this.inputFormatters,
  });

  static const _surface = Color(0xFF1A1A1A);
  static const _border = Color(0xFF2C2C2C);
  static const _textSecondary = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      cursorColor: const Color(0xFFD32F2F),
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: _surface,
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF424242), fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: _textSecondary, size: 20),
        suffix: suffixWidget,
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

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  const _TermsCheckbox({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFD32F2F),
            checkColor: Colors.white,
            side: const BorderSide(color: Color(0xFF9E9E9E), width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Acepto que mis datos serán usados para operaciones de seguridad vecinal de la red Alarma Comunitaria.',
            style: TextStyle(
              color: Color(0xFF9E9E9E),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
