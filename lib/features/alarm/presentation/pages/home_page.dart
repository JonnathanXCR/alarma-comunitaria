import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/alarm_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import 'report_emergency_page.dart';
import 'active_alert_page.dart';
import 'inactive_alert_page.dart';
import '../../../../core/globals.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../admin/presentation/pages/approval_page.dart';
import '../../../admin/presentation/pages/neighbors_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _currentIndex = 0;

  // ── Animación del pulso del botón SOS ──
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  // ── Progreso del press prolongado ──
  late final AnimationController _holdController;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
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
    _holdController.dispose();
    super.dispose();
  }

  void _checkApprovalAndProceed(dynamic user, VoidCallback onProceed) {
    if (user != null && !user.isAprobado) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Perfil Pendiente',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: const Text(
            'Tu perfil aún está en estado de aprobación. Una vez que un administrador lo apruebe, podrás enviar alertas.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Entendido',
                style: TextStyle(
                  color: AppColors.redBright,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }
    onProceed();
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: _buildBody(user, alarmProvider),
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
    if (_currentIndex == 0) return _buildSOSPage(user, alarmProvider);
    if (_currentIndex == 1) {
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
    final showAdminTabs = _canApproveUsers(user);

    if (_currentIndex == 2) {
      return showAdminTabs
          ? const NeighborsPage()
          : const ProfilePage();
    }
    
    if (showAdminTabs) {
      if (_currentIndex == 3) {
        return const ApprovalPage();
      }
      if (_currentIndex == 4) {
        return const ProfilePage();
      }
    }
    
    return const SizedBox.shrink();
  }

  // ────────────────────────────────────────────
  //  Página principal SOS
  // ────────────────────────────────────────────
  Widget _buildSOSPage(dynamic user, AlarmProvider alarmProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),

          // ── Header ──
          _buildHeader(user),

          const SizedBox(height: 8),

          // ── Ubicación ──
          _buildLocationRow(user),

          // ── Banner Alerta Activa ──
          ValueListenableBuilder<bool>(
            valueListenable: globalHasActiveAlert,
            builder: (context, hasAlert, child) {
              if (!hasAlert) return const SizedBox.shrink();
              return GestureDetector(
                onTap: () => setState(() => _currentIndex = 1),
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.redLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.redLight.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.redLight,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                      Icon(Icons.chevron_right, color: AppColors.redLight),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // ── Botón SOS ──
          _buildSOSButton(alarmProvider),

          const SizedBox(height: 16),

          // ── Texto instrucción ──
          const Text(
            'Presiona prolongadamente para\nactivar alerta crítica',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 28),

          // ── Slider sospechoso ──
          _buildSuspectSlider(alarmProvider),

          const SizedBox(height: 32),

          // ── Servicios de respuesta ──
          _buildResponseServices(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Header: Centro de Control / Emergencia SOS ──
  Widget _buildHeader(dynamic user) {
    return Row(
      children: [
        // Escudo rojo
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.red,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.red.withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(
            Icons.shield_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        // Textos
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CENTRO DE CONTROL',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Emergencia SOS',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        // Badge GPS + Logout
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.gps_fixed, color: AppColors.green, size: 12),
              SizedBox(width: 4),
              Text(
                'GPS ACTIVO',
                style: TextStyle(
                  color: AppColors.orange,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => context.read<AuthProvider>().logout(),
          child: const Icon(
            Icons.logout_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
      ],
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
            child: Text(
              user?.direccion ?? 'Ubicación no disponible',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () {
              /* TODO: cambiar ubicación */
            },
            child: const Text(
              'CAMBIAR',
              style: TextStyle(
                color: AppColors.redLight,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Botón SOS con animación pulsante ──
  Widget _buildSOSButton(AlarmProvider alarmProvider) {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return GestureDetector(
            onLongPressStart: (_) {
              final user = context.read<AuthProvider>().user;
              if (user != null && !user.isAprobado) {
                _checkApprovalAndProceed(user, () {});
                return;
              }
              HapticFeedback.mediumImpact();
              setState(() => _isHolding = true);
              _holdController.forward();
            },
            onLongPressEnd: (_) {
              if (_holdController.status != AnimationStatus.completed) {
                _holdController.reset();
                setState(() => _isHolding = false);
              }
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow exterior
                Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.redBright.withValues(
                            alpha: _isHolding ? 0.6 : 0.25,
                          ),
                          blurRadius: _isHolding ? 60 : 35,
                          spreadRadius: _isHolding ? 8 : 2,
                        ),
                      ],
                    ),
                  ),
                ),
                // Botón principal
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.redBright,
                        AppColors.red,
                        AppColors.red.withValues(alpha: 0.8),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.red.withValues(alpha: 0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.health_and_safety_rounded,
                        color: Colors.white,
                        size: 52,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alarmProvider.isSending ? 'ENVIANDO...' : 'SOS',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                      const Text(
                        'MANTENER',
                        style: TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // Progreso del hold
                if (_isHolding)
                  AnimatedBuilder(
                    animation: _holdController,
                    builder: (context, _) {
                      return SizedBox(
                        width: 192,
                        height: 192,
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
          );
        },
      ),
    );
  }

  Widget _buildSuspectSlider(AlarmProvider alarmProvider) {
    return _SwipeToReportWidget(
      onSwipe: () {
        final user = context.read<AuthProvider>().user;
        _checkApprovalAndProceed(user, () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ReportEmergencyPage(isSuspect: true),
            ),
          );
        });
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
            items.add(
              const BottomNavigationBarItem(
                icon: Icon(Icons.how_to_reg),
                label: 'Aprobaciones',
              ),
            );
          }

          items.add(
            const BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_rounded),
              label: 'Perfil',
            ),
          );

          // Asegurarnos que el índice actual no sea mayor a la cantidad de items
          final validIndex = _currentIndex < items.length ? _currentIndex : items.length - 1;

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
                      color: AppColors.green,
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
