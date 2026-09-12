import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/models/employee.dart';
import '../../../../shared/models/store.dart';
import '../../../../shared/models/app_session.dart';
import '../../../../shared/providers/app_session_notifier.dart';
import '../../../auth/domain/auth_repository.dart';
import '../back_office_screen.dart';
import 'desktop_navigation.dart';
import 'dashboard_screen.dart';
import 'reports_screen.dart';
import 'inventory_view_screen.dart';
import 'employees_view_screen.dart';
import 'shifts_view_screen.dart';
import 'business_config_screen.dart';
import 'backup_export_screen.dart';
import 'transfers_view_screen.dart';
import '../../../poultry/ui/receive_chicken_screen.dart';
import '../../../butcher/ui/butcher_screen.dart';
import '../../../products/ui/products_screen.dart';
import '../../../business/ui/business_setup_screen.dart';
import '../../../employees/ui/employee_pin_screen.dart';
import '../../../losses/ui/losses_screen.dart';



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
          return BusinessSetupScreen(
            onCreated: () => sessionNotifier.refreshSession(),
            authRepository: context.read<AuthRepository>(),
          );
        }

        if (sessionNotifier.needsStoreSelection) {
          return _StoreSelectionScreen(
            businessName: session.business.name,
            stores: session.stores,
            onSelected: (store) => sessionNotifier.selectStore(store),
            onSignOut: () {},
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
            onSignOut: () {},
          );
        }

        return _DesktopContent(session: session, selectedStore: selectedStore, employee: sessionNotifier.resolvedEmployee);
      },
    );
  }
}

class _DesktopContent extends StatefulWidget {
  final AppSession session;
  final Store selectedStore;
  final Employee employee;

  const _DesktopContent({required this.session, required this.selectedStore, required this.employee});

  @override
  State<_DesktopContent> createState() => _DesktopContentState();
}

class _DesktopContentState extends State<_DesktopContent> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          DesktopNavigation(
            selectedIndex: _selectedIndex,
            onSelected: (index) => setState(() => _selectedIndex = index),
            activeEmployee: widget.employee,
            selectedStore: widget.selectedStore,
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildPage(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage() {
    final employee = widget.employee;
    switch (_navItems(employee)[_selectedIndex].key) {
      case 'dashboard':
        return const DashboardScreen();
      case 'sales':
        return SalesReportScreen(
          businessId: widget.session.business.id,
          businessName: widget.session.business.name,
          store: widget.selectedStore,
          employee: employee,
        );
      case 'products':
        return ProductsScreen(businessId: widget.session.business.id, storeId: widget.selectedStore.id);
      case 'inventory':
        return InventoryViewScreen(
          businessId: widget.session.business.id,
          selectedStoreId: widget.selectedStore.id,
          currentEmployee: employee,
          stores: widget.session.stores,
        );
      case 'shifts':
        return ShiftsViewScreen(
          businessId: widget.session.business.id,
          store: widget.selectedStore,
          employee: employee,
        );
      case 'poultry':
        return ReceiveChickenScreen(
          businessId: widget.session.business.id,
          storeId: widget.selectedStore.id,
          employee: employee,
        );
      case 'butcher':
        return ButcherScreen(
          businessId: widget.session.business.id,
          store: widget.selectedStore,
          employee: employee,
        );
      case 'transfers':
        return const TransfersViewScreen();
      case 'employees':
        return EmployeesViewScreen(
          businessId: widget.session.business.id,
          stores: widget.session.stores,
        );
       case 'losses':
         return LossesScreen(
           businessId: widget.session.business.id,
           store: widget.selectedStore,
           employee: employee,
         );
       case 'settings':
         return BusinessConfigScreen(businessId: widget.session.business.id);
      case 'backoffice':
        return BackOfficeScreen(
          businessId: widget.session.business.id,
          stores: widget.session.stores,
          currentEmployee: employee,
        );
      default:
        return const DashboardScreen();
    }
  }

  List<_NavItem> _navItems(Employee employee) {
    return [
      const _NavItem('dashboard', Icons.dashboard, 'Dashboard'),
      if (employee.isManager || employee.isAdmin || employee.hasPermission('receipts'))
        const _NavItem('sales', Icons.receipt_long, 'Ventas'),
      if (employee.isManager || employee.isAdmin || employee.hasPermission('products'))
        const _NavItem('products', Icons.inventory_2, 'Productos'),
      if (employee.isManager || employee.isAdmin || employee.hasPermission('inventory'))
        const _NavItem('inventory', Icons.warehouse, 'Inventario'),
      if (employee.isManager || employee.isAdmin || employee.hasPermission('shift'))
        const _NavItem('shifts', Icons.access_time, 'Turnos'),
      if (employee.isAdmin || employee.hasPermission('transfers'))
        const _NavItem('transfers', Icons.swap_horiz, 'Traspasos'),
      if (employee.isAdmin || employee.hasPermission('poultry'))
        const _NavItem('poultry', Icons.egg_alt, 'Polleria'),
      if (employee.isAdmin || employee.hasPermission('butcher'))
        const _NavItem('butcher', Icons.restaurant_menu, 'Destazar'),
      if (employee.isAdmin || employee.hasPermission('employees'))
        const _NavItem('employees', Icons.people, 'Empleados'),
       if (employee.isAdmin || employee.hasPermission('losses'))
         const _NavItem('losses', Icons.delete_forever, 'Pérdidas'),
       if (employee.isAdmin) const _NavItem('settings', Icons.settings, 'Configuracion'),
      if (employee.isAdmin) const _NavItem('backoffice', Icons.admin_panel_settings, 'Back Office'),
    ];
  }
}

class _NavItem {
  const _NavItem(this.key, this.icon, this.label);
  final String key;
  final IconData icon;
  final String label;
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
                      title: Text(store.name),
                      subtitle: Text([if (store.address.isNotEmpty) store.address, if (store.phone.isNotEmpty) store.phone].join(' · ')),
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








