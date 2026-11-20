import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../shared/providers/app_session_notifier.dart';
import '../../features/home/ui/desktop/admin/admin_theme_tokens.dart';

import '../../shared/models/store.dart';
import '../../shared/models/product.dart';
import '../../shared/models/sale.dart';
import '../../features/auth/ui/login_screen.dart';
import '../../features/home/ui/home_screen.dart';
import '../../features/products/ui/add_product_screen.dart';
import '../../features/pos/ui/ticket_detail_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Web y escritorio abren páginas sin transición; móvil usa la nativa.
bool get _isDesktopOrWeb =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.linux ||
    defaultTargetPlatform == TargetPlatform.macOS;

/// Re-evalúa el `redirect` de go_router en cada cambio de sesión de
/// Firebase. Sin esto, cerrar sesión no saca de `/home` y entrar no
/// recarga nada: los botones de entrar/salir parecen no hacer nada.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable() {
    _sub = FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }

  late final StreamSubscription<User?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  refreshListenable: _AuthListenable(),
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthGate(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => _ShellWrapper(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
          routes: [
            GoRoute(
              path: 'products/add',
              parentNavigatorKey: _rootNavigatorKey,
              pageBuilder: (context, state) {
                final params = state.extra as Map<String, dynamic>? ?? {};
                final child = AddProductScreen(
                  businessId: params['businessId'] as String? ?? '',
                  storeId: params['storeId'] as String? ?? '',
                );
                if (_isDesktopOrWeb) {
                  // .exe administrador: paleta clara del dashboard.
                  return NoTransitionPage(
                    child: Theme(data: AdminTheme.light(), child: child),
                  );
                }
                return MaterialPage(child: child);
              },
            ),
            GoRoute(
              path: 'products/edit',
              parentNavigatorKey: _rootNavigatorKey,
              pageBuilder: (context, state) {
                final params = state.extra as Map<String, dynamic>? ?? {};
                final child = AddProductScreen(
                  businessId: params['businessId'] as String? ?? '',
                  storeId: params['storeId'] as String? ?? '',
                  product: params['product'] as Product?,
                );
                if (_isDesktopOrWeb) {
                  // .exe administrador: paleta clara del dashboard.
                  return NoTransitionPage(
                    child: Theme(data: AdminTheme.light(), child: child),
                  );
                }
                return MaterialPage(child: child);
              },
            ),
            GoRoute(
              path: 'tickets/:saleId',
              parentNavigatorKey: _rootNavigatorKey,
              pageBuilder: (context, state) {
                final params = state.extra as Map<String, dynamic>? ?? {};
                final child = TicketDetailScreen(
                  businessName: params['businessName'] as String? ?? '',
                  store: params['store'] as Store,
                  sale: params['sale'] as Sale,
                );
                if (_isDesktopOrWeb) return NoTransitionPage(child: child);
                return MaterialPage(child: child);
              },
            ),
          ],
        ),
      ],
    ),
  ],
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final path = state.matchedLocation;

    if (user == null && path != '/') {
      return '/';
    }
    if (user != null && path == '/') {
      return '/home';
    }
    return null;
  },
);

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _lastUid;

  void _syncSession(User? user) {
    if (user != null) {
      // Cuenta nueva o distinta: recargar sucursales/empleados/negocio.
      if (_lastUid == user.uid) return;
      _lastUid = user.uid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<AppSessionNotifier>().refreshSession();
      });
    } else {
      // Sesión cerrada: soltar negocio/sucursal/empleado en caché.
      if (_lastUid == null) return;
      _lastUid = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<AppSessionNotifier>().clearSession();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        _syncSession(user);
        if (user != null) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

String titleForPath(String path) {
  final List<String> segments = Uri.parse(path).pathSegments;
  final String? page = switch (segments) {
    [] => null,
    ['home'] => null,
    ['home', 'products', 'add'] => 'Nuevo producto',
    ['home', 'products', 'edit'] => 'Editar producto',
    ['home', 'tickets', _] => 'Ticket',
    _ => null,
  };

  return page == null ? 'PV Donald' : '$page · PV Donald';
}

/// Actualiza el título de la pestaña del navegador en cada navegación.
class RouteTitle extends StatelessWidget {
  final Widget child;

  const RouteTitle({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        goRouter.routerDelegate,
        goRouter.routeInformationProvider,
      ]),
      builder: (context, _) {
        final String path = goRouter.routeInformationProvider.value.uri.path;

        return Title(
          title: titleForPath(path),
          color: const Color(0xFFFFFFFF),
          child: child,
        );
      },
    );
  }
}

class _ShellWrapper extends StatelessWidget {
  const _ShellWrapper({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }
}
