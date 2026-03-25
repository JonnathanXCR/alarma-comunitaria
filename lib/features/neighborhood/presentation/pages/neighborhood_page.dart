import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_background.dart';
import '../providers/neighborhood_provider.dart';

class NeighborhoodPage extends StatefulWidget {
  const NeighborhoodPage({super.key});

  @override
  State<NeighborhoodPage> createState() => _NeighborhoodPageState();
}

class _NeighborhoodPageState extends State<NeighborhoodPage> {
  @override
  void initState() {
    super.initState();
    // Se elimina la carga automática:
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   context.read<NeighborhoodProvider>().loadBarrios();
    // });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NeighborhoodProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Selecciona tu Barrio')),
      body: AppBackground(
        backgroundColor: AppColors.bg,
        child: () {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }
          if (provider.barrios.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Lista de barrios vacía.'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<NeighborhoodProvider>().loadBarrios();
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Cargar Barrios'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: provider.barrios.length,
            itemBuilder: (context, index) {
              final n = provider.barrios[index];
              return ListTile(
                title: Text(n.nombre),
                subtitle: Text(n.ciudadNombre ?? ''),
                onTap: () => provider.selectBarrio(n),
              );
            },
          );
        }(),
      ),
    );
  }
}
