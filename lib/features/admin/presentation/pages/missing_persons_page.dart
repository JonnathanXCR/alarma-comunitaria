import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/missing_persons_provider.dart';
import 'add_missing_person_page.dart';

class MissingPersonsPage extends StatefulWidget {
  const MissingPersonsPage({super.key});

  @override
  State<MissingPersonsPage> createState() => _MissingPersonsPageState();
}

class _MissingPersonsPageState extends State<MissingPersonsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MissingPersonsProvider>().fetchMissingPersons();
    });
  }

  bool _hasPhysicalDescription(person) {
    return (person.estaturaAproximada?.isNotEmpty ?? false) ||
        (person.contextura?.isNotEmpty ?? false) ||
        (person.colorPiel?.isNotEmpty ?? false) ||
        (person.colorCabello?.isNotEmpty ?? false) ||
        (person.tipoCabello?.isNotEmpty ?? false) ||
        (person.colorOjos?.isNotEmpty ?? false) ||
        (person.tatuajes?.isNotEmpty ?? false) ||
        (person.cicatrices?.isNotEmpty ?? false) ||
        (person.usoLentes == true);
  }

  bool _hasClothing(person) {
    return (person.vestimentaSuperior?.isNotEmpty ?? false) ||
        (person.vestimentaInferior?.isNotEmpty ?? false) ||
        (person.zapatos?.isNotEmpty ?? false) ||
        (person.accesorios?.isNotEmpty ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final bool isAdmin = user != null &&
        (user.rol == 'presidente_barrio' ||
            user.rol == 'admin' ||
            user.rol == 'supervisor');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Personas Desaparecidas',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.orange),
            onPressed: () =>
                context.read<MissingPersonsProvider>().fetchMissingPersons(),
          ),
        ],
      ),
      body: AppBackground(
        child: Consumer<MissingPersonsProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.missingPersons.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.orange),
              );
            }

            if (provider.error != null && provider.missingPersons.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 48, color: AppColors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar:\n${provider.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.fetchMissingPersons(),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            if (provider.missingPersons.isEmpty) {
              return const Center(
                child: Text(
                  'No hay casos registrados.',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.orange,
              onRefresh: () => provider.fetchMissingPersons(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: provider.missingPersons.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final person = provider.missingPersons[index];
                  final isActive = person.activoEstado;

                  return Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (person.imagenUrl != null)
                          Stack(
                            children: [
                              Image.network(
                                person.imagenUrl!,
                                height: 250,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  height: 200,
                                  color: AppColors.surfaceLight,
                                  child: const Icon(
                                    Icons.image_not_supported_rounded,
                                    color: AppColors.textSecondary,
                                    size: 48,
                                  ),
                                ),
                              ),
                              if (isAdmin || person.usuarioId == user?.id)
                                if ((user?.rol == 'admin') ||
                                    ((user?.rol == 'supervisor' ||
                                            user?.rol == 'presidente_barrio') &&
                                        person.creatorBarrioId ==
                                            user?.barrioId) ||
                                    (person.usuarioId == user?.id))
                                  Positioned(
                                    bottom: 10,
                                    right: 10,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            provider.toggleStatus(
                                                person.id, isActive);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.black
                                                  .withValues(alpha: 0.6),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isActive
                                                      ? Icons
                                                          .check_circle_outline_rounded
                                                      : Icons.restore_rounded,
                                                  color: isActive
                                                      ? AppColors.green
                                                      : AppColors.orangeBright,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  isActive
                                                      ? 'Encontrado'
                                                      : 'Reabrir',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (person.usuarioId == user?.id) ...[
                                          const SizedBox(height: 8),
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      AddMissingPersonPage(
                                                    personToEdit: person,
                                                  ),
                                                ),
                                              ).then((_) {
                                                provider.fetchMissingPersons();
                                              });
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.black
                                                    .withValues(alpha: 0.6),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.edit_rounded,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'Editar',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                            ],
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      person.nombre,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? AppColors.orange
                                              .withValues(alpha: 0.15)
                                          : AppColors.textSecondary
                                              .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isActive ? 'Activo' : 'Cerrado',
                                      style: TextStyle(
                                        color: isActive
                                            ? AppColors.orangeBright
                                            : AppColors.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Basic Info
                              _buildInfoRow(Icons.phone_rounded, 'Contacto',
                                  person.contacto),
                              if (person.edad != null) ...[
                                const SizedBox(height: 4),
                                _buildInfoRow(Icons.cake_rounded, 'Edad',
                                    '${person.edad} años'),
                              ],
                              if (person.sexo != null) ...[
                                const SizedBox(height: 4),
                                _buildInfoRow(Icons.person_outline_rounded,
                                    'Sexo', person.sexo!),
                              ],
                              const SizedBox(height: 4),
                              _buildInfoRow(
                                Icons.calendar_today_rounded,
                                'Fecha de desaparición',
                                person.fechaDesaparicion != null
                                    ? '${person.fechaDesaparicion!.day.toString().padLeft(2, '0')}/${person.fechaDesaparicion!.month.toString().padLeft(2, '0')}/${person.fechaDesaparicion!.year} - ${TimeOfDay.fromDateTime(person.fechaDesaparicion!).format(context)}'
                                    : '${person.fecha.day.toString().padLeft(2, '0')}/${person.fecha.month.toString().padLeft(2, '0')}/${person.fecha.year}',
                              ),
                              const SizedBox(height: 4),
                              _buildInfoRow(Icons.location_on_rounded,
                                  'Ubicación General', person.lugar),
                              if (person.usuarioNombre != null &&
                                  person.usuarioNombre!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                _buildInfoRow(Icons.person_pin_rounded,
                                    'Reportado por', person.usuarioNombre!),
                              ],
                              if (person.ultimoLugarVisto != null &&
                                  person.ultimoLugarVisto!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                _buildInfoRow(Icons.directions_walk_rounded,
                                    'Último lugar visto', person.ultimoLugarVisto!),
                              ],
                              if (person.ciudadBarrio != null &&
                                  person.ciudadBarrio!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                _buildInfoRow(Icons.map_rounded,
                                    'Ciudad/Barrio', person.ciudadBarrio!),
                              ],

                              // Extended Description
                              if (_hasPhysicalDescription(person) ||
                                  _hasClothing(person)) ...[
                                const SizedBox(height: 16),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceLight
                                        .withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.border
                                            .withValues(alpha: 0.5)),
                                  ),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                        dividerColor: Colors.transparent),
                                    child: ExpansionTile(
                                      title: const Text(
                                        'Ver descripción física y vestimenta',
                                        style: TextStyle(
                                          color: AppColors.orangeBright,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      iconColor: AppColors.orangeBright,
                                      collapsedIconColor:
                                          AppColors.textSecondary,
                                      childrenPadding: const EdgeInsets.fromLTRB(
                                          16, 0, 16, 16),
                                      expandedCrossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (_hasPhysicalDescription(person)) ...[
                                          const Text(
                                            'Rasgos Físicos',
                                            style: TextStyle(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13),
                                          ),
                                          const SizedBox(height: 6),
                                          if (person.estaturaAproximada?.isNotEmpty ??
                                              false)
                                            _buildBullet('Estatura aproximada',
                                                person.estaturaAproximada!),
                                          if (person.contextura?.isNotEmpty ??
                                              false)
                                            _buildBullet('Contextura',
                                                person.contextura!),
                                          if (person.colorPiel?.isNotEmpty ??
                                              false)
                                            _buildBullet('Color de piel',
                                                person.colorPiel!),
                                          if (person.colorCabello?.isNotEmpty ??
                                              false)
                                            _buildBullet('Color de cabello',
                                                person.colorCabello!),
                                          if (person.tipoCabello?.isNotEmpty ??
                                              false)
                                            _buildBullet('Tipo de cabello',
                                                person.tipoCabello!),
                                          if (person.colorOjos?.isNotEmpty ??
                                              false)
                                            _buildBullet('Color de ojos',
                                                person.colorOjos!),
                                          if (person.tatuajes?.isNotEmpty ??
                                              false)
                                            _buildBullet(
                                                'Tatuajes', person.tatuajes!),
                                          if (person.cicatrices?.isNotEmpty ??
                                              false)
                                            _buildBullet('Cicatrices/Marcas',
                                                person.cicatrices!),
                                          if (person.usoLentes == true)
                                            _buildBullet('Lentes', 'Sí usa'),
                                          const SizedBox(height: 12),
                                        ],
                                        if (_hasClothing(person)) ...[
                                          const Text(
                                            'Vestimenta al Desaparecer',
                                            style: TextStyle(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13),
                                          ),
                                          const SizedBox(height: 6),
                                          if (person.vestimentaSuperior?.isNotEmpty ??
                                              false)
                                            _buildBullet('Chaqueta / Camiseta',
                                                person.vestimentaSuperior!),
                                          if (person.vestimentaInferior?.isNotEmpty ??
                                              false)
                                            _buildBullet('Pantalón / Falda',
                                                person.vestimentaInferior!),
                                          if (person.zapatos?.isNotEmpty ??
                                              false)
                                            _buildBullet(
                                                'Zapatos', person.zapatos!),
                                          if (person.accesorios?.isNotEmpty ??
                                              false)
                                            _buildBullet('Accesorios',
                                                person.accesorios!),
                                        ]
                                      ],
                                    ),
                                  ),
                                ),
                              ],

                              if (person.descripcion != null &&
                                  person.descripcion!.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  'Detalles adicionales:',
                                  style: TextStyle(
                                    color: AppColors.textPrimary
                                        .withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  person.descripcion!,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AddMissingPersonPage(),
            ),
          );
        },
        backgroundColor: AppColors.orangeBright,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Nuevo Caso',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                  fontSize: 13, fontFamily: 'Outfit'), // assuming Outfit font
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: text,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBullet(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6.0, right: 6.0),
            child: Icon(Icons.circle, size: 6, color: AppColors.orange),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, fontFamily: 'Outfit'),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
