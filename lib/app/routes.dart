import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/pages/otp_verification_page.dart';
import '../features/alarm/presentation/pages/home_page.dart';
import '../features/alarm/presentation/pages/active_alert_page.dart';
import '../features/neighborhood/domain/entities/neighborhood.dart';
import '../features/neighborhood/presentation/pages/neighborhood_page.dart';
import '../features/neighborhood/presentation/pages/create_neighborhood_page.dart';
import '../features/neighborhood/presentation/pages/edit_neighborhood_page.dart';
import '../features/admin/presentation/pages/neighbors_page.dart';

/// Rutas de la aplicación.
abstract class AppRoutes {
  static const login = '/login';
  static const register = '/registro';
  static const otpVerification = '/verificar-otp';
  static const home = '/';
  static const activeAlert = '/alerta-activa';
  static const neighborhood = '/barrios';
  static const createNeighborhood = '/crear-barrio';
  static const editNeighborhood = '/editar-barrio';
  static const neighbors = '/vecinos';
}

GoRouter buildRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isAuth = authProvider.isAuthenticated;
      final loc = state.matchedLocation;
      final isOnLogin = loc == AppRoutes.login;
      final isOnRegister = loc == AppRoutes.register;
      final isOnOtp = loc == AppRoutes.otpVerification;

      if (!isAuth && !isOnLogin && !isOnRegister && !isOnOtp) return AppRoutes.login;
      if (isAuth && (isOnLogin || isOnRegister || isOnOtp)) return AppRoutes.home;

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.otpVerification,
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return OtpVerificationPage(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.activeAlert,
        builder: (context, state) => const ActiveAlertPage(),
      ),
      GoRoute(
        path: AppRoutes.neighborhood,
        builder: (context, state) => const NeighborhoodPage(),
      ),
      GoRoute(
        path: AppRoutes.createNeighborhood,
        builder: (context, state) => const CreateNeighborhoodPage(),
      ),
      GoRoute(
        path: AppRoutes.editNeighborhood,
        builder: (context, state) {
          final barrio = state.extra as Barrio;
          return EditNeighborhoodPage(barrio: barrio);
        },
      ),
      GoRoute(
        path: AppRoutes.neighbors,
        builder: (context, state) => const NeighborsPage(),
      ),
    ],
  );
}
