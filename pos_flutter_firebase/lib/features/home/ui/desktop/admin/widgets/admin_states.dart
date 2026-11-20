import 'package:flutter/material.dart';

import '../admin_theme_tokens.dart';

/// Estado vacío: mensaje claro + sugerencia, nunca tarjeta vacía.
class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({super.key, required this.icon, required this.title, required this.hint});

  final IconData icon;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: AdminColors.track, shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: AdminColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Text(title, style: AdminText.cardTitle, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(hint, style: AdminText.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Estado de error: nunca pantalla vacía; reintentar + detalle técnico opcional.
class AdminErrorState extends StatelessWidget {
  const AdminErrorState({super.key, required this.message, required this.onRetry, this.details});

  final String message;
  final VoidCallback onRetry;
  final String? details;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: AdminColors.dangerBg, shape: BoxShape.circle),
              child: const Icon(Icons.error_outline, size: 32, color: AdminColors.danger),
            ),
            const SizedBox(height: 12),
            const Text('No fue posible cargar esta información', style: AdminText.cardTitle, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(message, style: AdminText.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
            if (details != null) ...[
              const SizedBox(height: 8),
              Text(details!, style: AdminText.bodySmall.copyWith(fontSize: 11), textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

/// Skeleton de carga: bloques suaves, sin spinner gigante.
class AdminSkeleton extends StatelessWidget {
  const AdminSkeleton({super.key, this.lines = 4});

  final int lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: 18,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AdminColors.track,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
      ],
    );
  }
}

/// Tabla administrativa: encabezado gris sutil + filas con divisor.
/// [onTapRow] opcional por fila (mismo largo que [rows]).
class AdminTable extends StatelessWidget {
  const AdminTable({
    super.key,
    required this.columns,
    required this.flex,
    required this.rows,
    this.onTapRow,
    this.rowPadding = const EdgeInsets.symmetric(vertical: 10),
  });

  final List<String> columns;
  final List<int> flex;
  final List<List<Widget>> rows;
  final List<VoidCallback?>? onTapRow;

  /// Separación vertical de filas (productos usa más aire que el dashboard).
  final EdgeInsetsGeometry rowPadding;

  @override
  Widget build(BuildContext context) {
    assert(columns.length == flex.length);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              for (var i = 0; i < columns.length; i++)
                Expanded(
                  flex: flex[i],
                  child: Text(
                    columns[i].toUpperCase(),
                    style: AdminText.badge.copyWith(color: AdminColors.textSecondary),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: AdminColors.border),
        for (var r = 0; r < rows.length; r++) ...[
          _TableRow(
            cells: rows[r],
            flex: flex,
            padding: rowPadding,
            onTap: onTapRow != null && r < onTapRow!.length ? onTapRow![r] : null,
          ),
          const Divider(height: 1, color: AdminColors.border),
        ],
      ],
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({required this.cells, required this.flex, required this.padding, this.onTap});

  final List<Widget> cells;
  final List<int> flex;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < cells.length; i++) Expanded(flex: flex[i], child: cells[i]),
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      hoverColor: AdminColors.track,
      child: row,
    );
  }
}
