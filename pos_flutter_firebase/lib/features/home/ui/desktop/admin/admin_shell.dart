import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/models/employee.dart';
import '../../../../../shared/models/store.dart';
import '../../back_office_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_filters.dart';
import 'admin_navigation.dart';
import 'admin_poultry_screen.dart';
import 'admin_products_screen.dart';
import 'admin_receipts_screen.dart';
import 'admin_theme_tokens.dart';
import 'admin_topbar.dart';

/// Shell exclusivo administrador para .exe Windows.
/// Estructura: sidebar estable + columna (topbar global + contenido con
/// scroll independiente). El contexto AdminScope persiste entre secciones.
class AdminShell extends StatefulWidget {
  const AdminShell({
    super.key,
    required this.businessId,
    required this.businessName,
    required this.stores,
    required this.employee,
    required this.onSignOut,
  });

  final String businessId;
  final String businessName;
  final List<Store> stores;
  final Employee employee;
  final VoidCallback onSignOut;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  AdminDestination _destination = AdminDestination.dashboard;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // ≥1400 expandido; 1100–1399 según espacio; <1100 compacto.
        final expanded = constraints.maxWidth >= 1300;
        return Scaffold(
          backgroundColor: AdminColors.appBg,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminNavigation(
                selected: _destination,
                onSelected: (d) => setState(() => _destination = d),
                businessName: widget.businessName,
                employeeName: widget.employee.name,
                employeeEmail: widget.employee.email,
                expanded: expanded,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AdminTopBar(
                      stores: widget.stores,
                      employeeName: widget.employee.name,
                      employeeEmail: widget.employee.email,
                      onSignOut: widget.onSignOut,
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: _buildContent(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    switch (_destination) {
      case AdminDestination.dashboard:
        return AdminDashboardScreen(
          key: const ValueKey('dashboard'),
          businessId: widget.businessId,
          stores: widget.stores,
        );
      case AdminDestination.receipts:
        return AdminReceiptsScreen(
          key: const ValueKey('receipts'),
          businessId: widget.businessId,
          businessName: widget.businessName,
          stores: widget.stores,
          employee: widget.employee,
        );
      case AdminDestination.products:
        return AdminProductsScreen(
          key: const ValueKey('products'),
          businessId: widget.businessId,
          stores: widget.stores,
        );
      case AdminDestination.poultry:
        return AdminPoultryScreen(
          key: const ValueKey('poultry'),
          businessId: widget.businessId,
          stores: widget.stores,
          employee: widget.employee,
        );
      case AdminDestination.backoffice:
        // Back Office conserva su lógica interna; se envuelve en el tema
        // claro del dashboard. La clave reconstruye al cambiar de sucursal
        // para no mostrar datos stale de otra sucursal.
        return Theme(
          data: AdminTheme.light(),
          child: BackOfficeScreen(
            key: ValueKey(
              'backoffice-${context.watch<AdminScope>().selectedStoreId ?? 'all'}',
            ),
            businessId: widget.businessId,
            stores: widget.stores,
            currentEmployee: widget.employee,
          ),
        );
    }
  }
}
