import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/alarm/presentation/providers/alarm_provider.dart';
import '../features/neighborhood/presentation/providers/neighborhood_provider.dart';
import '../features/admin/presentation/providers/admin_provider.dart';
import '../features/admin/presentation/providers/neighbors_provider.dart';
import '../features/admin/data/repositories/admin_repository.dart';
import '../core/theme/app_theme.dart';
import 'routes.dart';

class AlarmaComunitariaApp extends StatefulWidget {
  const AlarmaComunitariaApp({super.key});

  @override
  State<AlarmaComunitariaApp> createState() => _AlarmaComunitariaAppState();
}

class _AlarmaComunitariaAppState extends State<AlarmaComunitariaApp> {
  late final AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    // Intentar auto-login al lanzar la app
    _authProvider.tryAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProxyProvider<AuthProvider, AlarmProvider>(
          create: (_) => AlarmProvider(authProvider: _authProvider),
          update: (_, auth, previous) =>
              previous ?? AlarmProvider(authProvider: auth),
        ),
        ChangeNotifierProvider<NeighborhoodProvider>(
          create: (_) => NeighborhoodProvider(),
        ),
        ChangeNotifierProvider<AdminProvider>(
          create: (_) => AdminProvider(AdminRepository()),
        ),
        ChangeNotifierProvider<NeighborsProvider>(
          create: (_) => NeighborsProvider(),
        ),
      ],
      child: Builder(
        builder: (context) {
          final router = buildRouter(context.read<AuthProvider>());
          return MaterialApp.router(
            title: 'Alarma Comunitaria',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getTheme(),
            routerConfig: router,
          );
        },
      ),
    );
  }
}
