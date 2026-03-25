import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/neighbors_provider.dart';
import '../providers/admin_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../neighborhood/presentation/pages/neighborhoods_page.dart';

class NeighborsPage extends StatefulWidget {
  const NeighborsPage({super.key});

  @override
  State<NeighborsPage> createState() => _NeighborsPageState();
}

class _NeighborsPageState extends State<NeighborsPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPendingUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadNeighbors() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      final isAdmin = user.rol == 'admin';
      if (user.barrioId != null || isAdmin) {
        context.read<NeighborsProvider>().fetchNeighbors(
          user.barrioId,
          isAdmin: isAdmin,
        );
      }
    }
  }

  void _loadPendingUsers() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      final isAdmin = user.rol == 'admin';
      if (user.barrioId != null || isAdmin) {
        context.read<AdminProvider>().fetchPendingUsers(
          user.barrioId,
          isAdmin: isAdmin,
        );
      }
    }
  }

  void _handleApproval(String userId, String userName) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final isAdmin = user.rol == 'admin';
    if (user.barrioId == null && !isAdmin) return;

    final success = await context.read<AdminProvider>().approveUser(
      userId,
      user.barrioId ?? '',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Usuario $userName aprobado' : 'Error al aprobar usuario',
          ),
          backgroundColor: success ? AppColors.green : AppColors.red,
        ),
      );
    }
  }

  void _handleRejection(String userId, String userName) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final isAdmin = user.rol == 'admin';
    if (user.barrioId == null && !isAdmin) return;

    final success = await context.read<AdminProvider>().rejectUser(
      userId,
      user.barrioId ?? '',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Usuario $userName rechazado'
                : 'Error al rechazar usuario',
          ),
          backgroundColor: success ? AppColors.orange : AppColors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().user?.rol == 'admin';

    return DefaultTabController(
      length: isAdmin ? 3 : 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'Vecinos del Barrio',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          bottom: TabBar(
            labelColor: AppColors.redLight,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.redLight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            tabs: [
              const Tab(text: 'Todos'),
              const Tab(text: 'Pendientes'),
              if (isAdmin) const Tab(text: 'Barrios'),
            ],
          ),
        ),
        body: AppBackground(
          child: TabBarView(
            children: [
              _buildTodosTab(),
              _buildPendientesTab(),
              if (isAdmin) const NeighborhoodsPage(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodosTab() {
    final provider = context.watch<NeighborsProvider>();
    final neighbors = provider.neighbors;

    return Column(
      children: [
        // Búsqueda flotante arriba
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => context.read<NeighborsProvider>().search(val),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Buscar por cédula, nombre o apellido...',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textSecondary,
              ),
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                onPressed: () {
                  _searchController.clear();
                  context.read<NeighborsProvider>().search('');
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
          ),
        ),

        Expanded(
          child: Builder(
            builder: (context) {
              if (provider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.profilePrimary,
                  ),
                );
              }

              if (provider.errorMessage != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.redLight),
                    ),
                  ),
                );
              }

              if (neighbors.isEmpty && _searchController.text.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.group_off_rounded,
                        size: 60,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Aún no has cargado a los vecinos.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadNeighbors,
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Cargar Vecinos'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.profilePrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } else if (neighbors.isEmpty &&
                  _searchController.text.isNotEmpty) {
                return const Center(
                  child: Text(
                    'No se encontraron vecinos con esa búsqueda.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: neighbors.length,
                itemBuilder: (context, index) {
                  final neighbor = neighbors[index];
                  final isPending = neighbor.estadoAprobacion == 'pendiente';

                  return Card(
                    color: AppColors.surface,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.surfaceLight,
                        child: Text(
                          neighbor.nombre.isNotEmpty
                              ? neighbor.nombre[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        '${neighbor.nombre} ${neighbor.apellido}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'C.I: ${neighbor.cedula}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Rol: ${neighbor.rol.toUpperCase()}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      trailing: isPending
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Pendiente',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Aprobado',
                                style: TextStyle(
                                  color: AppColors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPendientesTab() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        if (adminProvider.isLoading && adminProvider.pendingUsers.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.redBright),
          );
        }

        if (adminProvider.errorMessage != null &&
            adminProvider.pendingUsers.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${adminProvider.errorMessage}',
                    style: const TextStyle(color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadPendingUsers,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.redBright,
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        if (adminProvider.pendingUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 60,
                  color: AppColors.green,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No hay usuarios pendientes de aprobación.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                IconButton(
                  onPressed: _loadPendingUsers,
                  icon: const Icon(
                    Icons.refresh,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
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
                          const Icon(
                            Icons.person,
                            color: AppColors.textSecondary,
                          ),
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
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dirección: ${pendingUser.direccion}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Teléfono: ${pendingUser.telefono}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _handleRejection(
                              pendingUser.id,
                              pendingUser.nombre,
                            ),
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.orange,
                              size: 18,
                            ),
                            label: const Text(
                              'Rechazar',
                              style: TextStyle(color: AppColors.orange),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _handleApproval(
                              pendingUser.id,
                              pendingUser.nombre,
                            ),
                            icon: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            ),
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
    );
  }
}
