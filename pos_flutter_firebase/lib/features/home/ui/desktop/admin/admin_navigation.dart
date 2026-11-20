import 'package:flutter/material.dart';

import 'admin_filters.dart';
import 'admin_theme_tokens.dart';

/// Navegación lateral: blanca, estable, iconos + etiquetas horizontales.
/// Activo: fondo accentSoft + acento, radio 12, transición corta, sin barras gruesas.
class AdminNavigation extends StatelessWidget {
  const AdminNavigation({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.businessName,
    required this.employeeName,
    required this.employeeEmail,
    this.expanded = false,
  });

  final AdminDestination selected;
  final ValueChanged<AdminDestination> onSelected;
  final String businessName;
  final String employeeName;
  final String employeeEmail;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final width = expanded ? 248.0 : 80.0;

    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: AdminColors.card,
        border: Border(right: BorderSide(color: AdminColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AdminColors.accent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'P',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ),
                if (expanded) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          businessName.isEmpty ? 'PV Donald' : businessName,
                          style: AdminText.body.copyWith(fontWeight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text('Administrador', style: AdminText.bodySmall),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: AdminColors.border),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              children: [
                for (final item in AdminDestination.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _NavTile(
                      destination: item,
                      selected: item == selected,
                      expanded: expanded,
                      onTap: () => onSelected(item),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AdminColors.border),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AdminColors.accent,
                  child: Text(
                    employeeName.isNotEmpty ? employeeName[0].toUpperCase() : 'A',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                if (expanded) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(employeeName, style: AdminText.body.copyWith(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(
                          employeeEmail.isEmpty ? 'Administrador' : employeeEmail,
                          style: AdminText.bodySmall.copyWith(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.destination,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final AdminDestination destination;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  IconData get _icon {
    switch (destination) {
      case AdminDestination.dashboard:
        return selected ? Icons.dashboard : Icons.dashboard_outlined;
      case AdminDestination.receipts:
        return selected ? Icons.receipt_long : Icons.receipt_long_outlined;
      case AdminDestination.products:
        return selected ? Icons.inventory_2 : Icons.inventory_2_outlined;
      case AdminDestination.poultry:
        return selected ? Icons.egg_alt : Icons.egg_alt_outlined;
      case AdminDestination.backoffice:
        return selected ? Icons.admin_panel_settings : Icons.admin_panel_settings_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AdminColors.accent : AdminColors.textSecondary;
    return Tooltip(
      message: destination.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        hoverColor: AdminColors.track,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(vertical: 11, horizontal: expanded ? 12 : 0),
          decoration: BoxDecoration(
            color: selected ? AdminColors.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: expanded
              ? Row(
                  children: [
                    Icon(_icon, size: 22, color: fg),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        destination.label,
                        style: AdminText.body.copyWith(
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? AdminColors.accent : AdminColors.text,
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_icon, size: 24, color: fg),
                    const SizedBox(height: 4),
                    Text(
                      destination.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.1,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                        color: selected ? AdminColors.accent : AdminColors.textSecondary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
