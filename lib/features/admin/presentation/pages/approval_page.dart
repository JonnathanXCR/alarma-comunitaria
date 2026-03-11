import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/admin_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';

class ApprovalPage extends StatefulWidget {
  const ApprovalPage({super.key});

  @override
  State<ApprovalPage> createState() => _ApprovalPageState();
}

class _ApprovalPageState extends State<ApprovalPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPendingUsers();
    });
  }

  void _loadPendingUsers() {
    final user = context.read<AuthProvider>().user;
    if (user != null && user.barrioId != null) {
      context.read<AdminProvider>().fetchPendingUsers(user.barrioId!);
    }
  }

  void _handleApproval(String userId, String userName) async {
    final user = context.read<AuthProvider>().user;
    if (user == null || user.barrioId == null) return;
    
    final success = await context.read<AdminProvider>().approveUser(userId, user.barrioId!);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Usuario $userName aprobado' : 'Error al aprobar usuario'),
          backgroundColor: success ? AppColors.green : AppColors.red,
        ),
      );
    }
  }

  void _handleRejection(String userId, String userName) async {
    final user = context.read<AuthProvider>().user;
    if (user == null || user.barrioId == null) return;

    final success = await context.read<AdminProvider>().rejectUser(userId, user.barrioId!);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Usuario $userName rechazado' : 'Error al rechazar usuario'),
          backgroundColor: success ? AppColors.orange : AppColors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Aprobar Usuarios', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingUsers,
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading && adminProvider.pendingUsers.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.redBright));
          }

          if (adminProvider.errorMessage != null && adminProvider.pendingUsers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${adminProvider.errorMessage}',
                      style: const TextStyle(color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadPendingUsers,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.redBright),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (adminProvider.pendingUsers.isEmpty) {
            return const Center(
              child: Text(
                'No hay usuarios pendientes de aprobación.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadPendingUsers();
            },
            color: AppColors.redBright,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: adminProvider.pendingUsers.length,
              itemBuilder: (context, index) {
                final pendingUser = adminProvider.pendingUsers[index];
                return Card(
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${pendingUser.nombre} ${pendingUser.apellido}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cédula: ${pendingUser.cedula}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dirección: ${pendingUser.direccion}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Teléfono: ${pendingUser.telefono}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _handleRejection(pendingUser.id, pendingUser.nombre),
                              icon: const Icon(Icons.close, color: AppColors.orange, size: 18),
                              label: const Text('Rechazar', style: TextStyle(color: AppColors.orange)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _handleApproval(pendingUser.id, pendingUser.nombre),
                              icon: const Icon(Icons.check, color: Colors.white, size: 18),
                              label: const Text('Aprobar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.green,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
