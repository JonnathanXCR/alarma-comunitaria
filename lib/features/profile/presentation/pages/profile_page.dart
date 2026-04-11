import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'edit_profile_page.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/neighborhood/presentation/pages/neighborhoods_page.dart';
import '../../../../core/theme/app_colors.dart';
import 'donations_page.dart';
import '../../../../core/widgets/app_background.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final email =
        Supabase.instance.client.auth.currentUser?.email ?? 'No disponible';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AppBackground(
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Column(
                      children: [
                        _buildUserAvatar(user),
                        const SizedBox(height: 32),
                        _buildPersonalInfo(user, email),
                        const SizedBox(height: 32),
                        _buildActions(context, user),
                        const SizedBox(height: 32),
                        _buildFooter(),
                      ],
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

  // ── Header ──
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40), // Spacing to match the settings button width
          const Text(
            'PERFIL',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.settings,
              color: AppColors.textSecondary,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            style: const ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  // ── User Avatar ──
  Widget _buildUserAvatar(dynamic user) {
    final userName = user?.nombreCompleto ?? 'Usuario Desconocido';
    final role = user?.rol ?? 'vecino';
    final isAprobado = user?.estadoAprobacion == 'aprobado';

    // Capitalize role
    final roleStr = role.isNotEmpty
        ? '${role[0].toUpperCase()}${role.substring(1)}'
        : 'Vecino';
    final subtitle =
        '$roleStr${isAprobado ? ' Verificado' : ''} • Alarma Comunitaria';

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderLight, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                color: AppColors.textMuted,
                size: 56,
              ),
            ),
            if (isAprobado)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.bgDark, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'VERIFICADO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          userName,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Personal Info ──
  Widget _buildPersonalInfo(dynamic user, String email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'INFORMACIÓN PERSONAL',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              _buildInfoRow(
                icon: Icons.badge_outlined,
                title: 'Mi Cédula',
                value: user?.cedula ?? 'No disponible',
              ),
              const Divider(height: 1, color: AppColors.borderLight),
              _buildInfoRow(
                icon: Icons.mail_outline,
                title: 'Correo Electrónico',
                value: email,
              ),
              const Divider(height: 1, color: AppColors.borderLight),
              _buildInfoRow(
                icon: Icons.smartphone_outlined,
                title: 'Teléfono',
                value: user?.telefono ?? 'No disponible',
              ),
              const Divider(height: 1, color: AppColors.borderLight),
              _buildInfoRow(
                icon: Icons.location_city_outlined,
                title: 'Barrio',
                value: user?.barrioNombre ?? 'No asignado',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ──
  Widget _buildActions(BuildContext context, dynamic user) {
    final canManageBarrios = user?.rol == 'admin' || user?.rol == 'supervisor' || user?.rol == 'presidente_barrio';

    return Column(
      children: [
        if (canManageBarrios) ...[
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NeighborhoodsPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardDark,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.borderLight),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.business_outlined, size: 20),
                SizedBox(width: 8),
                Text(
                  'Gestión de Barrios',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EditProfilePage()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.cardDark,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.borderLight),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit_outlined, size: 20),
              SizedBox(width: 8),
              Text(
                'Editar Perfil',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DonationsPage()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.red.withOpacity(0.15),
            foregroundColor: AppColors.redLight,
            elevation: 0,
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.red, width: 1.5),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.volunteer_activism_rounded, size: 20),
              SizedBox(width: 8),
              Text(
                'Hacer una Donación',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, color: AppColors.borderLight),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () {
            context.read<AuthProvider>().logout();
          },
          icon: const Icon(Icons.logout, size: 20),
          label: const Text('Cerrar Sesión'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ── Footer ──
  Widget _buildFooter() {
    return const Opacity(
      opacity: 0.4,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'ALUMBRA Comunidad V1.0.1',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
      ),
    );
  }
}
