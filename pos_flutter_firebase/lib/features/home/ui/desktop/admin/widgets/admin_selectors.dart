import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../shared/models/store.dart';
import '../admin_filters.dart';
import '../admin_theme_tokens.dart';

/// Selector de sucursal: el control más visible de la barra.
/// TODAS se diferencia visualmente (icono domain) de una sucursal (store).
///
/// OJO: el valor del menú es [String] no nulable con centinela [_kAll]:
/// un `PopupMenuItem` con `value: null` Flutter lo trata como cancelación
/// y `onSelected` jamás se dispara (por eso antes no se podía volver a TODAS).
class AdminStoreSelector extends StatelessWidget {
  const AdminStoreSelector({super.key, required this.stores});

  static const String kAll = '__all_stores__';

  final List<Store> stores;

  @override
  Widget build(BuildContext context) {
    final scope = context.watch<AdminScope>();
    final selected = _find(stores, scope.selectedStoreId);

    return PopupMenuButton<String>(
      tooltip: 'Cambiar sucursal',
      offset: const Offset(0, 48),
      color: AdminColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadii.inner)),
      onSelected: (value) => context.read<AdminScope>().selectStore(value == kAll ? null : value),
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          enabled: false,
          child: Text('Seleccionar sucursal', style: AdminText.bodySmall),
        ),
        PopupMenuItem<String>(
          value: kAll,
          child: _MenuRow(
            icon: Icons.domain_outlined,
            label: 'Todas las sucursales',
            checked: scope.isAllStores,
          ),
        ),
        const PopupMenuDivider(),
        for (final s in stores)
          PopupMenuItem<String>(
            value: s.id,
            child: _MenuRow(
              icon: Icons.storefront_outlined,
              label: s.name.isEmpty ? '(Sin nombre)' : s.name,
              checked: scope.selectedStoreId == s.id,
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: scope.isAllStores ? AdminColors.infoBg : AdminColors.accentSoft,
          borderRadius: BorderRadius.circular(AdminRadii.button),
          border: Border.all(
            color: scope.isAllStores
                ? AdminColors.info.withValues(alpha: 0.3)
                : AdminColors.accent.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected == null ? Icons.domain_outlined : Icons.storefront_outlined,
              size: 20,
              color: scope.isAllStores ? AdminColors.info : AdminColors.accent,
            ),
            const SizedBox(width: 10),
            Text(
              selected == null ? 'Todas las sucursales' : selected.name,
              style: AdminText.body.copyWith(
                fontWeight: FontWeight.w700,
                color: scope.isAllStores ? AdminColors.info : AdminColors.accent,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.expand_more,
              size: 18,
              color: scope.isAllStores ? AdminColors.info : AdminColors.accent,
            ),
          ],
        ),
      ),
    );
  }

  Store? _find(List<Store> stores, String? id) {
    if (id == null) return null;
    for (final s in stores) {
      if (s.id == id) return s;
    }
    return null;
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, required this.checked});

  final IconData icon;
  final String label;
  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AdminColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: AdminText.body)),
        if (checked) const Icon(Icons.check, size: 18, color: AdminColors.accent),
      ],
    );
  }
}

/// Selector de fecha global: Hoy / Ayer / Semana / Mes.
/// Estilo explícito claro (no hereda el tema): siempre legible.
class AdminDateSelector extends StatelessWidget {
  const AdminDateSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = context.watch<AdminScope>();
    return SegmentedButton<AdminDateRange>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        backgroundColor: AdminColors.card,
        foregroundColor: AdminColors.textSecondary,
        selectedBackgroundColor: AdminColors.accentSoft,
        selectedForegroundColor: AdminColors.accent,
        side: const BorderSide(color: AdminColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadii.button)),
      ),
      segments: const [
        ButtonSegment(value: AdminDateRange.today, label: Text('Hoy')),
        ButtonSegment(value: AdminDateRange.yesterday, label: Text('Ayer')),
        ButtonSegment(value: AdminDateRange.thisWeek, label: Text('Semana')),
        ButtonSegment(value: AdminDateRange.thisMonth, label: Text('Mes')),
      ],
      selected: {scope.range},
      onSelectionChanged: (set) {
        if (set.isNotEmpty) context.read<AdminScope>().setRange(set.first);
      },
    );
  }
}
