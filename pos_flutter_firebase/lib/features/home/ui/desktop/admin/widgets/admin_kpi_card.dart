import 'package:flutter/material.dart';

import '../admin_theme_tokens.dart';

/// KPI principal: icono en cuadro suave, etiqueta, valor grande tabular.
/// Sin porcentajes inventados: solo muestra [trendLabel] si se provee
/// con datos reales (puede ser null para ocultarlo).
class AdminKpiCard extends StatelessWidget {
  const AdminKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.softBg,
    this.trendLabel,
    this.trendUp,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color softBg;
  final String? trendLabel;
  final bool? trendUp;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(AdminRadii.inner + 4),
        border: Border.all(color: AdminColors.border),
        boxShadow: AdminShadows.card,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: softBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(label, style: AdminText.kpiLabel),
          const SizedBox(height: 4),
          Text(value, style: AdminText.kpiValue, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (trendLabel != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  (trendUp ?? true) ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: (trendUp ?? true) ? AdminColors.success : AdminColors.danger,
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    trendLabel!,
                    style: AdminText.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Fila de métrica secundaria (Resumen del periodo): etiqueta + valor.
class AdminStatRow extends StatelessWidget {
  const AdminStatRow({super.key, required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AdminColors.textSecondary),
            const SizedBox(width: 10),
          ],
          Expanded(child: Text(label, style: AdminText.body)),
          Text(value, style: AdminText.body.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
