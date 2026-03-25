import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/alert.dart';
import '../providers/alarm_provider.dart';
import '../../../../core/globals.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ActiveAlertPage extends StatefulWidget {
  const ActiveAlertPage({super.key});

  @override
  State<ActiveAlertPage> createState() => _ActiveAlertPageState();
}

class _ActiveAlertPageState extends State<ActiveAlertPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _timer;
  Duration _activeTime = Duration.zero;
  DateTime? _createdAt;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final alarmProvider = context.watch<AlarmProvider>();
    final alert = alarmProvider.activeAlert;

    if (alert == null) {
      // Si entramos a esta vista y no hay alerta en memoria (ej. app cerrada), iniciar sync.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AlarmProvider>().init();
      });
    } else if (_createdAt == null) {
      _createdAt = alert.creadoEn;
      _updateTimer();
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _updateTimer(),
      );
    }
  }

  void _updateTimer() {
    if (_createdAt != null && mounted) {
      setState(() {
        _activeTime = DateTime.now().difference(_createdAt!);
      });
    }
  }

  Future<void> _openMap(double? lat, double? lng) async {
    if (lat == null || lng == null) return;
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    if (d.inHours > 0) {
      return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final alarmProvider = context.watch<AlarmProvider>();
    final alert = alarmProvider.activeAlert;

    final authProvider = context.watch<AuthProvider>();
    final rol = authProvider.user?.rol;
    final canDeactivate =
        rol == 'admin' ||
        ((rol == 'supervisor' || rol == 'presidente_barrio') &&
            alert?.barrioId == authProvider.user?.barrioId);

    // Si no hay alerta, mostramos un fallback básico (aunque el ruteo
    // de HomePage evitará llegar aquí).
    if (alert == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isReceived = alarmProvider.isAlertReceived(alert.id);

    final isSuspect = alert.tipoEmergencia == TipoEmergencia.sospechoso;

    // Colores condicionales
    final primaryColor = isSuspect
        ? AppColors.orangeBright
        : AppColors.redBright;
    const whatsappColor = Color(0xFF25D366);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : const Color(0xFFFFFFFF);
    final cardColor = isDark ? AppColors.cardDark : const Color(0xFFFFFFFF);
    final textColor = isDark
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF0F172A);
    final subtleTextColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Body content
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 240),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Map Section
                Stack(
                  children: [
                    GestureDetector(
                      onTap: () => _openMap(alert.latitud, alert.longitud),
                      child: SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.matrix([
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0,
                            0,
                            0,
                            1,
                            0,
                          ]),
                          child: Image.network(
                            'https://maps.googleapis.com/maps/api/staticmap?center=${alert.latitud ?? 0},${alert.longitud ?? 0}&zoom=15&size=600x300&key=MOCK_KEY', // Placeholder
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: isDark
                                      ? Colors.grey[900]
                                      : Colors.grey[300],
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.map,
                                    size: 120,
                                    color: subtleTextColor,
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ),
                    // Pulsing beacon
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () => _openMap(alert.latitud, alert.longitud),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Animated pulse halo — only the ring grows
                                  AnimatedBuilder(
                                    animation: _pulseController,
                                    builder: (context, _) {
                                      final size =
                                          58.0 + (_pulseController.value * 42);
                                      return Container(
                                        width: size,
                                        height: size,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: primaryColor.withOpacity(
                                            0.35 * (1 - _pulseController.value),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  // Fixed-size map pin
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black38,
                                          blurRadius: 14,
                                          offset: Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Action chip — static, always readable
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.72),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.open_in_new,
                                      color: Colors.white,
                                      size: 13,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'Toca para abrir el mapa',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Location Card Overlay
                  ],
                ),

                // Content section
                Transform.translate(
                  offset: const Offset(0, -16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Alerta Recibida Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: borderColor),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 16),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isSuspect
                                        ? 'REPORTE RECIBIDO'
                                        : 'ALERTA RECIBIDA',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: primaryColor,
                                      fontStyle: FontStyle.italic,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'VECINO: ${alert.usuarioNombre ?? alert.usuarioId.substring(0, 6).toUpperCase()}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: subtleTextColor,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatDuration(_activeTime),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: primaryColor,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  Text(
                                    'TIEMPO ACTIVO',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: subtleTextColor,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Detalles del reporte Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: borderColor),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 8),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.description_outlined,
                                    color: primaryColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'DETALLES DEL REPORTE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: subtleTextColor,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'TIPO',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: subtleTextColor,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: primaryColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              alert.tipoEmergencia.name
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w900,
                                                color: textColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'LUGAR',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: subtleTextColor,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          alert.lugar ?? 'N/A',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (alert.quePaso != null &&
                                  alert.quePaso!.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Divider(height: 1, color: borderColor),
                                const SizedBox(height: 12),
                                Text(
                                  '¿QUÉ PASÓ?',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  alert.quePaso!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: textColor,
                                  ),
                                ),
                              ],
                              if (alert.descripcion != null &&
                                  alert.descripcion!.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Divider(height: 1, color: borderColor),
                                const SizedBox(height: 12),
                                Text(
                                  'DESCRIPCIÓN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: subtleTextColor,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  alert.descripcion!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: textColor.withOpacity(0.8),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                              if (alert.imagenUrl != null &&
                                  alert.imagenUrl!.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Divider(height: 1, color: borderColor),
                                const SizedBox(height: 12),
                                Text(
                                  'FOTO DEL LUGAR',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: subtleTextColor,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    alert.imagenUrl!,
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 200,
                                        color: isDark
                                            ? Colors.grey[900]
                                            : Colors.grey[100],
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(
                                          height: 100,
                                          color: isDark
                                              ? Colors.grey[900]
                                              : Colors.grey[200],
                                          child: Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.broken_image_outlined,
                                                  color: subtleTextColor,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Error al cargar imagen',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: subtleTextColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        // Respondedores desde respuestas_alerta
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'RESPONDIENDO A LA ALERTA (${alarmProvider.alertResponses.length})',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: subtleTextColor,
                                letterSpacing: 1,
                              ),
                            ),
                            Icon(Icons.group, color: subtleTextColor, size: 18),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (alarmProvider.alertResponses.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor),
                            ),
                            child: Center(
                              child: Text(
                                'Sin respuestas aún',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: subtleTextColor,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          )
                        else
                          ...alarmProvider.alertResponses.asMap().entries.map((
                            entry,
                          ) {
                            final respuesta = entry.value;
                            final nombre = respuesta.usuarioNombre ?? 'Vecino';
                            final initials = nombre
                                .split(' ')
                                .where((w) => w.isNotEmpty)
                                .map((w) => w[0].toUpperCase())
                                .take(2)
                                .join();
                            final estado = respuesta.estado.toUpperCase();
                            Color statusColor;
                            switch (estado) {
                              case 'RECIBIDA':
                              case 'EN_CAMINO':
                                statusColor = Colors.green;
                                break;
                              case 'NOTIFICADO':
                                statusColor = Colors.blue;
                                break;
                              default:
                                statusColor = subtleTextColor;
                            }

                            return Padding(
                              padding: EdgeInsets.only(
                                top: entry.key == 0 ? 0 : 12,
                              ),
                              child: _buildResponderRow(
                                name: nombre,
                                subtitle: estado,
                                initials: initials,
                                status: estado,
                                statusColor: statusColor,
                                isDark: isDark,
                                cardColor: cardColor,
                                borderColor: borderColor,
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Actions Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    bgColor.withOpacity(0),
                    bgColor.withOpacity(0.8),
                    bgColor,
                    bgColor,
                  ],
                  stops: const [0, 0.2, 0.5, 1],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Alerta Recibida Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isReceived
                            ? null
                            : () {
                                alarmProvider.markAlertAsReceived(alert.id);
                                globalHasActiveAlert.value = false;
                                if (GoRouter.of(context).canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/');
                                }
                              },
                        borderRadius: BorderRadius.circular(16),
                        child: Ink(
                          decoration: BoxDecoration(
                            color: isReceived
                                ? Colors.grey.shade400
                                : primaryColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isReceived
                                ? []
                                : [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isReceived
                                          ? Icons.done_all
                                          : Icons.check_circle,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      isReceived
                                          ? 'ALERTA YA RECIBIDA'
                                          : 'ALERTA RECIBIDA',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isReceived
                                      ? 'HAS CONFIRMADO QUE ESTÁS AL TANTO'
                                      : 'CONFIRMAR QUE ESTÁS AL TANTO',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white.withOpacity(0.8),
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),


                    // Acciones Paralelas: Mapas y Grupos
                    Row(
                      children: [
                        // WhatsApp Button
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                // Lógica whatsapp
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Ink(
                                decoration: BoxDecoration(
                                  color: whatsappColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: whatsappColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.message,
                                        color: whatsappColor,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'WHATSAPP',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: whatsappColor,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (canDeactivate) ...[
                      const SizedBox(height: 12),
                      // Desactivar Alerta Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: isDark
                                    ? AppColors.bgDark
                                    : Colors.white,
                                title: Text(
                                  '¿Desactivar alerta?',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                content: Text(
                                  'Esta acción finalizará la alerta para todos los vecinos.',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.black87,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('CANCELAR'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                    ),
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text(
                                      'DESACTIVAR',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await alarmProvider.deactivateAlert(alert.id);
                              if (context.mounted) {
                                if (GoRouter.of(context).canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/');
                                }
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Ink(
                            decoration: BoxDecoration(
                              color: isDark ? Colors.transparent : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: primaryColor.withOpacity(0.5),
                              ),
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.power_settings_new,
                                    color: primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'DESACTIVAR ALERTA',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: primaryColor,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponderRow({
    required String name,
    required String subtitle,
    required String initials,
    required String status,
    required Color statusColor,
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
    double opacity = 1.0,
  }) {
    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                border: Border.all(color: statusColor.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
