import 'package:flutter/material.dart';

import '../admin_theme_tokens.dart';

/// Badge suave: color concentrado en el estado, nunca toda la fila.
/// Siempre texto + punto, legible sin depender solo del color.
class AdminStatusBadge extends StatelessWidget {
  const AdminStatusBadge._({required this.label, required this.color, required this.bg});

  /// Badge genérico con colores explícitos.
  const AdminStatusBadge.custom({super.key, required this.label, required this.color, required this.bg});

  final String label;
  final Color color;
  final Color bg;

  /// Estado de inventario con la regla de negocio EXISTENTE:
  /// bajo = total <= alerta (con alerta <= 0, bajo solo si total <= 0).
  /// Crítico = sin existencias.
  factory AdminStatusBadge.stock({required double total, required double alert}) {
    if (total <= 0) {
      return const AdminStatusBadge._(label: 'Crítico', color: AdminColors.danger, bg: AdminColors.dangerBg);
    }
    final isLow = alert <= 0 ? false : total <= alert;
    if (isLow) {
      return const AdminStatusBadge._(label: 'Bajo', color: AdminColors.warning, bg: AdminColors.warningBg);
    }
    return const AdminStatusBadge._(label: 'Normal', color: AdminColors.success, bg: AdminColors.successBg);
  }

  factory AdminStatusBadge.saleStatus(String status, {bool isRefund = false}) {
    if (isRefund) {
      return const AdminStatusBadge._(label: 'Devolución', color: AdminColors.warning, bg: AdminColors.warningBg);
    }
    switch (status) {
      case 'cancelled':
        return const AdminStatusBadge._(label: 'Cancelado', color: AdminColors.danger, bg: AdminColors.dangerBg);
      case 'partially_cancelled':
        return const AdminStatusBadge._(label: 'Parcial', color: AdminColors.warning, bg: AdminColors.warningBg);
      default:
        return const AdminStatusBadge._(label: 'Pagado', color: AdminColors.success, bg: AdminColors.successBg);
    }
  }

  factory AdminStatusBadge.payment(String method) {
    switch (method) {
      case 'card':
        return const AdminStatusBadge._(label: 'Tarjeta', color: AdminColors.info, bg: AdminColors.infoBg);
      case 'split':
        return const AdminStatusBadge._(label: 'Mixto', color: AdminColors.accent, bg: AdminColors.accentSoft);
      default:
        return const AdminStatusBadge._(label: 'Efectivo', color: AdminColors.success, bg: AdminColors.successBg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AdminRadii.chip)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: AdminText.badge.copyWith(color: color)),
        ],
      ),
    );
  }
}

/// Banda de contexto multi-sucursal: imposible confundir el alcance.
/// TODAS = consolidado; una = vista individual.
class AdminScopeBanner extends StatelessWidget {
  const AdminScopeBanner({
    super.key,
    required this.isAllStores,
    required this.storeName,
    required this.rangeLabel,
    required this.activeStoreCount,
  });

  final bool isAllStores;
  final String storeName;
  final String rangeLabel;
  final int activeStoreCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isAllStores ? AdminColors.infoBg : AdminColors.accentSoft,
        borderRadius: BorderRadius.circular(AdminRadii.button),
        border: Border.all(
          color: isAllStores ? AdminColors.info.withValues(alpha: 0.25) : AdminColors.accent.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isAllStores ? Icons.domain_outlined : Icons.storefront_outlined,
            size: 18,
            color: isAllStores ? AdminColors.info : AdminColors.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isAllStores
                  ? 'TODAS LAS SUCURSALES · $activeStoreCount activas · consolidado · $rangeLabel'
                  : '${storeName.toUpperCase()} · vista individual · $rangeLabel',
              style: AdminText.badge.copyWith(
                color: isAllStores ? AdminColors.info : AdminColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
