import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/models/employee.dart';
import '../../../../shared/models/store.dart';
import '../../../../shared/models/app_session.dart';
import '../../../../shared/providers/app_session_notifier.dart';
import '../../../auth/domain/auth_repository.dart';
import 'admin/admin_filters.dart';
import 'admin/admin_shell.dart';
import '../../../auth/ui/login_screen.dart';
import '../../../employees/ui/employee_pin_screen.dart';
import '../../../../shared/extensions/phone_x.dart';
import '../../../../shared/extensions/string_x.dart';



class DesktopLayout extends StatelessWidget {
  const DesktopLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSessionNotifier>(
      builder: (context, sessionNotifier, _) {
        if (sessionNotifier.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final session = sessionNotifier.session;
        if (session == null || session.stores.isEmpty) {
          // Sin negocio vinculado: solo login con correo y contraseña.
          // Si la carga falla, se muestra el error con reintento (antes era silencio).
          final loadError = sessionNotifier.error;
          return Column(
            children: [
              Expanded(
                child: LoginScreen(
                  onAuthenticated: () => sessionNotifier.refreshSession(),
                ),
              ),
              if (loadError != null)
                Container(
                  width: double.infinity,
                  color: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          loadError,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: () => sessionNotifier.refreshSession(),
                        child: const Text('Reintentar',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
            ],
          );
        }

        if (sessionNotifier.needsStoreSelection) {
          return _StoreSelectionScreen(
            businessName: session.business.name,
            stores: session.stores,
            onSelected: (store) => sessionNotifier.selectStore(store),
            onSignOut: () => context.read<AuthRepository>().signOut(),
          );
        }

        final selectedStore = sessionNotifier.resolvedStore;
        final employeesForStore = sessionNotifier.employeesForStore;

        if (sessionNotifier.needsPinEntry || !sessionNotifier.isCurrentEmployeeValid) {
          return EmployeePinScreen(
            store: selectedStore,
            stores: session.stores,
            employees: employeesForStore,
            onUnlocked: (employee) => sessionNotifier.selectEmployee(employee),
            onSelectStore: (store) => sessionNotifier.selectStore(store),
            onSignOut: () => context.read<AuthRepository>().signOut(),
          );
        }

        // .exe exclusivo administrador: shell unificado con sucursal global.
        // AdminScope persiste al cambiar de sección (Dashboard/Recibos/etc).
        return ChangeNotifierProvider(
          create: (_) => AdminScope(initialStoreId: null),
          child: _AdminRoot(
            session: session,
            initialStore: selectedStore,
            employee: sessionNotifier.resolvedEmployee,
          ),
        );
      },
    );
  }
}

/// Sincroniza la sucursal de la sesión con el alcance global del admin
/// y muestra el shell. Si la sesión cambia de sucursal fuera del TopBar
/// (pantalla de selección), se refleja una sola vez.
class _AdminRoot extends StatefulWidget {
  const _AdminRoot({
    required this.session,
    required this.initialStore,
    required this.employee,
  });

  final AppSession session;
  final Store initialStore;
  final Employee employee;

  @override
  State<_AdminRoot> createState() => _AdminRootState();
}

class _AdminRootState extends State<_AdminRoot> {
  @override
  Widget build(BuildContext context) {
    return AdminShell(
      businessId: widget.session.business.id,
      businessName: widget.session.business.name,
      stores: widget.session.stores,
      employee: widget.employee,
      onSignOut: () => context.read<AuthRepository>().signOut(),
    );
  }
}

class _StoreSelectionScreen extends StatelessWidget {
  const _StoreSelectionScreen({
    required this.businessName,
    required this.stores,
    required this.onSelected,
    required this.onSignOut,
  });

  final String businessName;
  final List<Store> stores;
  final ValueChanged<Store> onSelected;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store, size: 64, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text('Selecciona la sucursal', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 24),
                ...stores.map(
                  (store) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.storefront),
                      title: Text(store.name.orPlaceholder()),
                      subtitle: Text([if (store.address.isNotEmpty) store.address, if (store.phone.isNotEmpty) store.phone.maskPhoneNumber].join(' · ')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => onSelected(store),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}








