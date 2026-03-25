import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/alarm_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/pages/pending_approval_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import 'report_emergency_page.dart';
import 'active_alert_page.dart';
import 'inactive_alert_page.dart';
import '../../../../core/globals.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../admin/presentation/pages/neighbors_page.dart';
import '../../../admin/presentation/pages/missing_persons_page.dart';
import '../../../../core/widgets/app_background.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _currentIndex = 0;

  // ── Animación del pulso del botón SOS ──
  late final AnimationController _pulseController;   // onda 1 (primera)
  late final AnimationController _pulse2Controller;  // onda 2 (desfasada)
  late final Animation<double> _pulseAnimation;      // breathing del botón
  late final Animation<double> _ring1Animation;      // expansión onda 1
  late final Animation<double> _ring2Animation;      // expansión onda 2

  // ── Progreso del press prolongado ──
  late final AnimationController _holdController;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = globalHasActiveAlert.value ? 1 : 0;

    // Onda 1: ciclo completo de 2 s
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Onda 2: misma duración, arranca desfasada 1 s
    _pulse2Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward(from: 0.5);
    _pulse2Controller.addStatusListener((s) {
      if (s == AnimationStatus.completed) _pulse2Controller.repeat();
    });

    // Breathing: escala del botón principal (0.97 → 1.0)
    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Expansión de los anillos (0 → 1)
    _ring1Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _ring2Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulse2Controller, curve: Curves.easeOut),
    );

    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.heavyImpact();
        _triggerSOS();
        _holdController.reset();
        setState(() => _isHolding = false);
      }
    });

    globalHasActiveAlert.addListener(_onGlobalAlertChanged);
  }

  void _onGlobalAlertChanged() {
    if (globalHasActiveAlert.value) {
      if (mounted && _currentIndex != 1) {
        setState(() => _currentIndex = 1);
      }
    }
  }

  @override
  void dispose() {
    globalHasActiveAlert.removeListener(_onGlobalAlertChanged);
    _pulseController.dispose();
    _pulse2Controller.dispose();
    _holdController.dispose();
    super.dispose();
  }

  void _triggerSOS() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ReportEmergencyPage(isSuspect: false),
      ),
    );
  }

  Future<void> _call911() async {
    final uri = Uri.parse('tel:911');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final alarmProvider = context.watch<AlarmProvider>();
    final user = authProvider.user;

    if (user != null && !user.isAprobado) {
      return const PendingApprovalPage();
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: AppBackground(
          child: SafeArea(child: _buildBody(user, alarmProvider)),
        ),
        bottomNavigationBar: _buildBottomNav(user),
      ),
    );
  }

  // ────────────────────────────────────────────
  //  Manejo dinámico de vistas
  // ────────────────────────────────────────────

  bool _canApproveUsers(dynamic user) {
    if (user == null) return false;
    final rol = user.rol;
    return rol == 'presidente_barrio' || rol == 'admin' || rol == 'supervisor';
  }

  Widget _buildBody(dynamic user, AlarmProvider alarmProvider) {
    final showAdminTabs = _canApproveUsers(user);
    final maxIndex = showAdminTabs ? 4 : 3;

    // Ajustar el índice si el rol del usuario cambió
    final int safeIndex = _currentIndex > maxIndex ? 0 : _currentIndex;

    if (safeIndex == 0) return _buildSOSPage(user, alarmProvider);
    if (safeIndex == 1) {
      return ValueListenableBuilder<bool>(
        valueListenable: globalHasActiveAlert,
        builder: (context, hasAlert, _) {
          final localAlert = alarmProvider.activeAlert;
          if (hasAlert || localAlert != null) {
            return const ActiveAlertPage();
          }
          return InactiveAlertPage(
            onSwitchToSOS: () {
              if (mounted) setState(() => _currentIndex = 0);
            },
          );
        },
      );
    }

    if (showAdminTabs) {
      if (safeIndex == 2) return const NeighborsPage();
      if (safeIndex == 3) return const MissingPersonsPage();
      if (safeIndex == 4) return const ProfilePage();
    } else {
      if (safeIndex == 2) return const MissingPersonsPage();
      if (safeIndex == 3) return const ProfilePage();
    }

    return const SizedBox.shrink();
  }

  // ────────────────────────────────────────────
  //  Página principal SOS
  // ────────────────────────────────────────────
  Widget _buildSOSPage(dynamic user, AlarmProvider alarmProvider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Sección Superior ──
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      _buildLocationRow(user),
                      ValueListenableBuilder<bool>(
                        valueListenable: globalHasActiveAlert,
                        builder: (context, hasAlert, child) {
                          if (!hasAlert) return const SizedBox.shrink();
                          return GestureDetector(
                            onTap: () => setState(() => _currentIndex = 1),
                            child: Container(
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.redLight.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.redLight.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    'assets/images/logo.png',
                                    width: 24,
                                    height: 24,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'Alerta Activa',
                                          style: TextStyle(
                                            color: AppColors.redLight,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Hay una emergencia en curso. Toca para ver.',
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: AppColors.redLight,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // ── Sección Central ──
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 24),
                      RepaintBoundary(child: _buildSOSButton(alarmProvider)),
                      const SizedBox(height: 12),
                      const Text(
                        'Mantén presionado para activar la alarma',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          letterSpacing: 0.2,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),

                  // ── Sección Inferior ──
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.border,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSuspectSlider(alarmProvider),
                      const SizedBox(height: 20),
                      _buildResponseServices(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Fila de ubicación ──
  Widget _buildLocationRow(dynamic user) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.redLight, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.barrioNombre ?? 'Barrio no asignado',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user?.nombreCompleto ?? 'Usuario no identificado',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 1,
                height: 20,
                color: AppColors.border,
                margin: const EdgeInsets.symmetric(horizontal: 10),
              ),
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 14,
              ),
              const SizedBox(width: 4),
              const Text(
                'SISTEMA EN LÍNEA',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Botón SOS con animación pulsante (radar/ripple) ──
  Widget _buildSOSButton(AlarmProvider alarmProvider) {
    // Tamaño base del botón principal
    const double btnSize = 220.0;
    // Tamaño máximo al que se expanden los anillos
    const double maxRing = 340.0;

    return Center(
      child: SizedBox(
        width: maxRing,
        height: maxRing,
        child: AnimatedBuilder(
          animation: Listenable.merge([_ring1Animation, _ring2Animation, _pulseAnimation]),
          builder: (context, child) {
            final ring1Scale = 1.0 + _ring1Animation.value * ((maxRing - btnSize) / btnSize);
            final ring1Opacity = (1.0 - _ring1Animation.value).clamp(0.0, 1.0);
            final ring2Scale = 1.0 + _ring2Animation.value * ((maxRing - btnSize) / btnSize);
            final ring2Opacity = (1.0 - _ring2Animation.value).clamp(0.0, 1.0);

            return Stack(
              alignment: Alignment.center,
              children: [
                // ── Onda de pulso 1 ──
                Transform.scale(
                  scale: ring1Scale,
                  child: Opacity(
                    opacity: ring1Opacity * (_isHolding ? 0.0 : 0.45),
                    child: Container(
                      width: btnSize,
                      height: btnSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.redBright,
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Onda de pulso 2 (desfasada) ──
                Transform.scale(
                  scale: ring2Scale,
                  child: Opacity(
                    opacity: ring2Opacity * (_isHolding ? 0.0 : 0.35),
                    child: Container(
                      width: btnSize,
                      height: btnSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.redBright,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Glow halo (fijo, solo se intensifica al hacer hold) ──
                Container(
                  width: btnSize + 28,
                  height: btnSize + 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.redBright.withOpacity(
                          _isHolding ? 0.55 : 0.18,
                        ),
                        blurRadius: _isHolding ? 60 : 32,
                        spreadRadius: _isHolding ? 10 : 0,
                      ),
                    ],
                  ),
                ),

                // ── Botón principal con efecto breathing ──
                GestureDetector(
                  onLongPressStart: (_) {
                    if (alarmProvider.isSending) return;
                    HapticFeedback.mediumImpact();
                    setState(() => _isHolding = true);
                    _holdController.forward();
                  },
                  onLongPressEnd: (_) {
                    if (alarmProvider.isSending) return;
                    if (_holdController.status != AnimationStatus.completed) {
                      _holdController.reset();
                      setState(() => _isHolding = false);
                    }
                  },
                  child: Transform.scale(
                    scale: _isHolding ? 1.04 : _pulseAnimation.value,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Círculo principal
                        Container(
                          width: btnSize,
                          height: btnSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.redBright,
                                AppColors.red,
                                AppColors.red.withValues(alpha: 0.85),
                              ],
                              center: const Alignment(-0.25, -0.25),
                              radius: 0.85,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.red.withOpacity(0.55),
                                blurRadius: _isHolding ? 36 : 20,
                                offset: const Offset(0, 6),
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.18),
                                blurRadius: 10,
                                spreadRadius: -6,
                                offset: const Offset(-3, -3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Logo
                              Image.asset(
                                'assets/images/logo.png',
                                width: 60,
                                height: 60,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 10),
                              // Título principal
                              Text(
                                alarmProvider.isSending
                                    ? 'ENVIANDO...'
                                    : 'SOS',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 6,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Subtítulo acción
                              Text(
                                alarmProvider.isSending
                                    ? 'Por favor espera'
                                    : 'REPORTAR EMERGENCIA',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xF0FFFFFF),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Indicador de instrucción
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'MANTÉN PRESIONADO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Arco de progreso del hold ──
                        if (_isHolding)
                          AnimatedBuilder(
                            animation: _holdController,
                            builder: (context, _) {
                              return SizedBox(
                                width: btnSize + 12,
                                height: btnSize + 12,
                                child: CustomPaint(
                                  painter: _HoldProgressPainter(
                                    progress: _holdController.value,
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSuspectSlider(AlarmProvider alarmProvider) {
    return _SwipeToReportWidget(
      onSwipe: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const ReportEmergencyPage(isSuspect: true),
          ),
        );
      },
    );
  }

  // ── Servicios de respuesta ──
  Widget _buildResponseServices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SERVICIOS DE RESPUESTA',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),

        // Llamar al 911
        GestureDetector(
          onTap: _call911,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.phone_in_talk_rounded,
                  color: AppColors.textPrimary,
                  size: 28,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LLAMAR AL 911',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'CONEXIÓN DIRECTA EMERGENCIAS',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Bottom Navigation Bar ──
  Widget _buildBottomNav(dynamic user) {
    final showApprovals = _canApproveUsers(user);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: ValueListenableBuilder<bool>(
        valueListenable: globalHasActiveAlert,
        builder: (context, hasAlert, child) {
          final items = [
            const BottomNavigationBarItem(
              icon: Icon(Icons.emergency_rounded),
              label: 'SOS',
            ),
            BottomNavigationBarItem(
              icon: hasAlert
                  ? AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_pulseController.value * 0.2),
                          child: Icon(
                            Icons.notifications_active_rounded,
                            color: AppColors.redBright.withOpacity(
                              0.6 + (_pulseController.value * 0.4),
                            ),
                          ),
                        );
                      },
                    )
                  : const Icon(Icons.notifications_active_rounded),
              label: 'Alertas',
            ),
          ];

          if (showApprovals) {
            items.add(
              const BottomNavigationBarItem(
                icon: Icon(Icons.groups_rounded),
                label: 'Vecinos',
              ),
            );
          }

          items.add(
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_search_rounded),
              label: 'Desaparecidos',
            ),
          );

          items.add(
            const BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_rounded),
              label: 'Perfil',
            ),
          );

          // Asegurarnos que el índice actual no sea mayor a la cantidad de items
          final validIndex = _currentIndex < items.length
              ? _currentIndex
              : items.length - 1;

          return BottomNavigationBar(
            currentIndex: validIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.redBright,
            unselectedItemColor: AppColors.textSecondary,
            selectedFontSize: 10,
            unselectedFontSize: 10,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            items: items,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Painter para el arco de progreso del hold
// ─────────────────────────────────────────────
class _HoldProgressPainter extends CustomPainter {
  final double progress;
  _HoldProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, paint);
  }

  @override
  bool shouldRepaint(_HoldProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _SwipeToReportWidget extends StatefulWidget {
  final VoidCallback onSwipe;

  const _SwipeToReportWidget({required this.onSwipe});

  @override
  State<_SwipeToReportWidget> createState() => _SwipeToReportWidgetState();
}

class _SwipeToReportWidgetState extends State<_SwipeToReportWidget> {
  double _dragPosition = 0.0;
  bool _isSwiping = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double containerHeight = 60.0;
        final double thumbSize = 44.0;
        final double padding = 8.0;
        final double maxDrag = constraints.maxWidth - thumbSize - (padding * 2);

        return Container(
          height: containerHeight,
          padding: EdgeInsets.symmetric(horizontal: padding),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              const Center(
                child: Text(
                  'DESLIZA PARA SOSPECHOSO',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: _isSwiping
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                left: _dragPosition,
                child: GestureDetector(
                  onHorizontalDragStart: (_) {
                    setState(() {
                      _isSwiping = true;
                    });
                  },
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _dragPosition += details.delta.dx;
                      if (_dragPosition < 0) _dragPosition = 0;
                      if (_dragPosition > maxDrag) _dragPosition = maxDrag;
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    setState(() {
                      _isSwiping = false;
                    });
                    if (_dragPosition > maxDrag * 0.8) {
                      _dragPosition = maxDrag;
                      widget.onSwipe();
                      // Regresa a la posición original luego de invocar el callback
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted) {
                          setState(() {
                            _dragPosition = 0;
                          });
                        }
                      });
                    } else {
                      _dragPosition = 0;
                    }
                  },
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: const BoxDecoration(
                      color: AppColors.orangeBright,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.swipe_right_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
