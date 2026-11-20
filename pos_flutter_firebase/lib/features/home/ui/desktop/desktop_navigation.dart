import 'package:flutter/material.dart';
import '../../../../shared/models/employee.dart';
import '../../../../shared/models/store.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../shared/widgets/bottom_padding.dart';



class DesktopNavigation extends StatelessWidget {
  const DesktopNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.activeEmployee,
    required this.selectedStore,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Employee activeEmployee;
  final Store selectedStore;

  @override
  Widget build(BuildContext context) {
    final items = _navItems(activeEmployee);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.sidebarBg : AppColors.sidebarBg;

    return SizedBox(
      width: 72,
      child: Container(
        color: bgColor,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Icon(Icons.point_of_sale, size: 32, color: AppColors.accent),
            ),
            const Divider(height: 1, color: AppColors.sidebarBorder),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                padding: const EdgeInsets.symmetric(vertical: 8).copyWith(
                  bottom: BottomPadding.of(context, minimum: 8),
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = selectedIndex == index;
                  return InkWell(
                    onTap: () => onSelected(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.sidebarActive.withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Tooltip(
                        message: item.label,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(item.icon, size: 28, color: isSelected ? AppColors.accent : AppColors.sidebarTextSecondary),
                            const SizedBox(height: 2),
                            RotatedBox(
                              quarterTurns: 3,
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isSelected ? AppColors.accent : AppColors.sidebarTextSecondary,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.accent,
                    child: Text(
                      activeEmployee.name.isNotEmpty ? activeEmployee.name[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 4),
                  RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      activeEmployee.name.length > 8 ? '${activeEmployee.name.substring(0, 8)}...' : activeEmployee.name,
                      style: TextStyle(fontSize: 8, color: AppColors.sidebarTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_NavItem> _navItems(Employee employee) {
    return [
      _NavItem('dashboard', Icons.dashboard, 'Dashboard'),
      if (employee.isManager || employee.isAdmin || employee.hasPermission('receipts'))
        _NavItem('sales', Icons.receipt_long, 'Ventas'),
      if (employee.isManager || employee.isAdmin || employee.hasPermission('products'))
        _NavItem('products', Icons.inventory_2, 'Productos'),
      if (employee.isManager || employee.isAdmin || employee.hasPermission('inventory'))
        _NavItem('inventory', Icons.warehouse, 'Inventario'),
      if (employee.isManager || employee.isAdmin || employee.hasPermission('shift'))
        _NavItem('shifts', Icons.access_time, 'Turnos'),
      if (employee.isAdmin || employee.hasPermission('transfers'))
        _NavItem('transfers', Icons.swap_horiz, 'Traspasos'),
      if (employee.isAdmin || employee.hasPermission('poultry'))
        _NavItem('poultry', Icons.egg_alt, 'Polleria'),
      if (employee.isAdmin || employee.hasPermission('butcher'))
        _NavItem('butcher', Icons.restaurant_menu, 'Destazar'),
      if (employee.isAdmin || employee.hasPermission('employees'))
        _NavItem('employees', Icons.people, 'Empleados'),
        _NavItem('losses', Icons.delete_forever, 'Pérdidas'),
        if (employee.isAdmin)
          _NavItem('settings', Icons.settings, 'Configuracion'),
      if (employee.isAdmin)
        _NavItem('backoffice', Icons.admin_panel_settings, 'BackOffice'),
    ];
  }
}

class _NavItem {
  const _NavItem(this.key, this.icon, this.label);
  final String key;
  final IconData icon;
  final String label;
}








