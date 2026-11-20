import 'package:flutter/material.dart';

import '../admin_theme_tokens.dart';

/// Columna de [AdminDataTable]: ancho fijo o flexible.
///
/// - Si [width] != null: `FixedColumnWidth`.
/// - Si no: `FlexColumnWidth(flex)`.
/// - [align] controla la alineación del contenido de TODAS las celdas
///   (encabezado usa [headerAlign] ?? [align]).
/// Al usar el widget `Table` con estos anchos, cada campo queda en su
/// fila Y columna alineada en todos los registros.
class AdminColumn {
  const AdminColumn({
    required this.label,
    this.flex = 1,
    this.width,
    this.align = Alignment.centerLeft,
    this.headerAlign,
  });

  final String label;
  final int flex;
  final double? width;
  final Alignment align;
  final Alignment? headerAlign;
}

/// Tabla administrativa REAL (widget `Table`) para Recibos, Productos e
/// Inventario: los anchos se calculan del conjunto de filas, así que las
/// columnas jamás se concatenan ni se desalinean entre registros.
///
/// - Encabezado `#F8F9FC`, 11px semibold, altura 44.
/// - Filas con altura mínima, divisor suave, importes a la derecha.
/// - Si el ancho disponible es menor que [minWidth] (o el calculado),
///   la tabla mantiene su ancho con scroll horizontal en vez de colapsar.
class AdminDataTable extends StatelessWidget {
  const AdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.rowMinHeight = 68,
    this.emptyState,
    this.minWidth,
  });

  final List<AdminColumn> columns;
  final List<List<Widget>> rows;
  final double rowMinHeight;
  final Widget? emptyState;
  final double? minWidth;

  double _computedMinWidth() {
    if (minWidth != null) return minWidth!;
    var total = 0.0;
    for (final c in columns) {
      total += c.width ?? 150;
    }
    return total;
  }

  Map<int, TableColumnWidth> _columnWidths() {
    final map = <int, TableColumnWidth>{};
    for (var i = 0; i < columns.length; i++) {
      final c = columns[i];
      map[i] = c.width != null ? FixedColumnWidth(c.width!) : FlexColumnWidth(c.flex.toDouble());
    }
    return map;
  }

  Table _table() {
    return Table(
      columnWidths: _columnWidths(),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: const TableBorder(
        horizontalInside: BorderSide(color: AdminColors.border, width: 1),
      ),
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFF8F9FC)),
          children: [
            for (final c in columns)
              Container(
                alignment: c.headerAlign ?? c.align,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                child: Text(
                  c.label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        for (final cells in rows)
          TableRow(
            children: [
              for (var i = 0; i < cells.length; i++)
                Container(
                  constraints: BoxConstraints(minHeight: rowMinHeight),
                  alignment: columns[i].align,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  child: cells[i],
                ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty && emptyState != null) return emptyState!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final need = _computedMinWidth();
        if (constraints.maxWidth >= need) return _table();
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: need, child: _table()),
        );
      },
    );
  }
}
