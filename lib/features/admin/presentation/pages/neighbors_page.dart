import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/neighbors_provider.dart';

class NeighborsPage extends StatefulWidget {
  const NeighborsPage({super.key});

  @override
  State<NeighborsPage> createState() => _NeighborsPageState();
}

class _NeighborsPageState extends State<NeighborsPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadNeighbors() {
    final user = context.read<AuthProvider>().user;
    if (user != null && user.barrioId != null) {
      context.read<NeighborsProvider>().fetchNeighbors(user.barrioId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NeighborsProvider>();
    final neighbors = provider.neighbors;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Vecinos del Barrio', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
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
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
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
            child:Builder(
              builder: (context) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.profilePrimary));
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

                // Si aún no se han cargado los vecinos (lista vacía) o si simplemente no hay vecinos
                // Aquí, decidiremos si pedimos cargar.
                // Como propusiste un botón manual, mostraremos el botón si NO hemos buscado nada 
                // y la lista está vacía, indicando que hay que cargar.
                // Para esto podemos chequear si total loaded es 0.
                if (neighbors.isEmpty && _searchController.text.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.group_off_rounded, size: 60, color: AppColors.textSecondary),
                        const SizedBox(height: 16),
                        const Text(
                          'Aún no has cargado a los vecinos.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadNeighbors,
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Cargar Vecinos'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.profilePrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (neighbors.isEmpty && _searchController.text.isNotEmpty) {
                  return const Center(
                    child: Text(
                      'No se encontraron vecinos con esa búsqueda.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.surfaceLight,
                          child: Text(
                            neighbor.nombre.isNotEmpty ? neighbor.nombre[0].toUpperCase() : '?',
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
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
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rol: ${neighbor.rol.toUpperCase()}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                        trailing: isPending
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Pendiente',
                                  style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Aprobado',
                                  style: TextStyle(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
