import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../providers/neighborhood_provider.dart';
import 'edit_neighborhood_page.dart';
import 'add_neighborhood_page.dart';

class NeighborhoodsPage extends StatefulWidget {
  const NeighborhoodsPage({super.key});

  @override
  State<NeighborhoodsPage> createState() => _NeighborhoodsPageState();
}

class _NeighborhoodsPageState extends State<NeighborhoodsPage> {
  String? _selectedProvinciaId;
  String? _selectedCiudadId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBarrios();
      context.read<LocationProvider>().loadProvincias();
    });
  }

  void _loadBarrios() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      context.read<NeighborhoodProvider>().loadBarrios(
            role: user.rol,
            userId: user.id,
            userBarrioId: user.barrioId,
            provinciaId: _selectedProvinciaId,
            ciudadId: _selectedCiudadId,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NeighborhoodProvider>();
    final locationProvider = context.watch<LocationProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Gestión de Barrios', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddNeighborhoodPage()),
        ).then((_) => _loadBarrios()),
        backgroundColor: AppColors.profilePrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: AppBackground(
        backgroundColor: AppColors.bg,
        child: Column(
          children: [
            // Filtros
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface.withOpacity(0.8),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedProvinciaId,
                      decoration: InputDecoration(
                        labelText: 'Provincia',
                        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      dropdownColor: AppColors.surface,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Todas')),
                        ...locationProvider.provincias.map((p) => DropdownMenuItem(value: p.id, child: Text(p.nombre))),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedProvinciaId = val;
                          _selectedCiudadId = null;
                        });
                        if (val != null) {
                          context.read<LocationProvider>().loadCiudades(val);
                        } else {
                          context.read<LocationProvider>().clearCiudades();
                        }
                        _loadBarrios();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCiudadId,
                      decoration: InputDecoration(
                        labelText: 'Ciudad',
                        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      dropdownColor: AppColors.surface,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Todas')),
                        ...locationProvider.ciudades.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre))),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedCiudadId = val);
                        _loadBarrios();
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: () {
                if (provider.loading) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.profilePrimary));
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${provider.error}', style: const TextStyle(color: AppColors.textPrimary)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadBarrios,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.profilePrimary),
                          child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.barrios.isEmpty) {
                  return const Center(
                    child: Text('No hay barrios con estos filtros.', style: TextStyle(color: AppColors.textSecondary)),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _loadBarrios(),
                  color: AppColors.profilePrimary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.barrios.length,
                    itemBuilder: (context, index) {
                      final b = provider.barrios[index];
                      return Card(
                        color: AppColors.surface.withOpacity(0.9),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(b.nombre, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Text(b.ciudadNombre ?? '', style: const TextStyle(color: AppColors.textSecondary)),
                          trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                          onTap: () {
                            // Navigate to Edit page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditNeighborhoodPage(barrio: b),
                              ),
                            ).then((_) => _loadBarrios());
                          },
                        ),
                      );
                    },
                  ),
                );
              }(),
            ),
          ],
        ),
      ),
    );
  }
}
