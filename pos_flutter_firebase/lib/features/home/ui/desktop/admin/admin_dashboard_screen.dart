import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/models/product.dart';
import '../../../../../shared/models/sale.dart';
import '../../../../../shared/models/store.dart';
import '../../../../../shared/widgets/bottom_padding.dart';
import 'admin_filters.dart';
import 'admin_theme_tokens.dart';
import 'widgets/admin_card.dart';
import 'widgets/admin_kpi_card.dart';
import 'widgets/admin_section_header.dart';
import 'widgets/admin_states.dart';
import 'widgets/admin_status_badge.dart';

/// Dashboard exclusivo administrador (.exe) — rediseño visual.
///
/// Jerarquía: contexto → 4 KPIs → sucursales + pagos → artículos + resumen →
/// resumen de sucursales (solo TODAS) → inventario expandible.
/// Lógica de datos intacta: queries acotadas, stockByStore como verdad,
/// split repartido, devoluciones/cancelados excluidos de brutas.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key, required this.businessId, required this.stores});

  final String businessId;
  final List<Store> stores;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId)
          .collection('sales')
          .orderBy('clientCreatedAt', descending: true)
          .limit(500)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: const [AdminSectionHeader(title: 'Dashboard', subtitle: 'Resumen general del negocio'), SizedBox(height: 16), AdminCard(child: AdminSkeleton(lines: 6))],
          );
        }
        if (snapshot.hasError) {
          return AdminErrorState(
            message: 'No fue posible cargar las ventas.',
            details: '${snapshot.error}',
            onRetry: () => context.read<AdminScope>().touch(),
          );
        }
        final scope = context.watch<AdminScope>();
        final now = DateTime.now();
        final range = scope.range.resolve(now);
        final allSales = <Sale>[];
        for (final d in snapshot.data?.docs ?? const []) {
          try {
            allSales.add(Sale.fromDoc(d));
          } catch (_) {
            // Documento malformado: se ignora, no tumba el dashboard.
          }
        }
        final filtered = allSales.where((s) {
          if (!scope.isAllStores && s.storeId != scope.selectedStoreId) return false;
          final date = s.clientCreatedAt ?? s.createdAt;
          if (date == null) return false;
          return !date.isBefore(range.start) && !date.isAfter(range.end);
        }).toList();

        return _DashboardBody(
          sales: filtered,
          businessId: businessId,
          stores: stores,
        );
      },
    );
  }
}

/// Totales con las reglas de negocio existentes (sin cambios).
class _DashboardTotals {
  _DashboardTotals(this.sales);

  final List<Sale> sales;

  List<Sale> get originals => sales.where((s) => !s.isRefund && !s.isCancelled).toList();
  List<Sale> get refunds => sales.where((s) => s.isRefund).toList();

  double get gross => originals.fold(0, (t, s) => t + s.total);
  double get refundTotal => refunds.fold(0, (t, s) => t + s.total);
  double get net => gross - refundTotal;

  /// Descuentos del ticket + descuentos por línea (item['discount']).
  /// Antes solo se sumaba discountTotal y las ventas con descuento
  /// por producto no se reflejaban aquí.
  double get discounts {
    var total = originals.fold<double>(0, (t, s) => t + s.discountTotal);
    for (final s in originals) {
      for (final item in s.items) {
        total += (item['discount'] as num? ?? 0).toDouble();
      }
    }
    return total;
  }

  double get cash {
    double total = 0;
    for (final s in originals) {
      if (s.paymentMethod == 'cash') {
        total += s.total;
      } else if (s.paymentMethod == 'split') {
        total += s.cashAmount ?? 0;
      }
    }
    return total;
  }

  double get card {
    double total = 0;
    for (final s in originals) {
      if (s.paymentMethod == 'card') {
        total += s.total;
      } else if (s.paymentMethod == 'split') {
        total += s.cardAmount ?? 0;
      }
    }
    return total;
  }

  double get avgTicket => originals.isEmpty ? 0 : gross / originals.length;
}

/// Stocks cargados UNA vez y compartidos por resumen + inventario.
class _StocksData {
  _StocksData({required this.products, required this.perStore});

  final List<Product> products;
  final Map<String, Map<String, double>> perStore;

  double totalOf(String productId) {
    var total = 0.0;
    for (final v in (perStore[productId] ?? const <String, double>{}).values) {
      total += v;
    }
    return total;
  }
}

class _DashboardBody extends StatefulWidget {
  const _DashboardBody({required this.sales, required this.businessId, required this.stores});

  final List<Sale> sales;
  final String businessId;
  final List<Store> stores;

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  late Future<_StocksData> _stocksFuture;

  @override
  void initState() {
    super.initState();
    _stocksFuture = _loadStocks();
  }

  Future<_StocksData> _loadStocks() async {
    final db = FirebaseFirestore.instance;
    final prodSnap = await db
        .collection('businesses')
        .doc(widget.businessId)
        .collection('products')
        .where('active', isEqualTo: true)
        .limit(60)
        .get();
    final products = <Product>[];
    for (final d in prodSnap.docs) {
      try {
        products.add(Product.fromDoc(d));
      } catch (_) {}
    }
    final perStore = <String, Map<String, double>>{};
    for (final p in products) {
      final byStore = <String, double>{};
      for (final s in widget.stores.take(6)) {
        double qty = 0;
        try {
          final doc = await db
              .collection('businesses')
              .doc(widget.businessId)
              .collection('products')
              .doc(p.id)
              .collection('stockByStore')
              .doc(s.id)
              .get();
          if (doc.exists) {
            final data = doc.data() ?? {};
            qty = ((data['stockQuantity'] as num?) ?? (data['stock'] as num?) ?? 0).toDouble();
          }
        } catch (_) {
          qty = 0;
        }
        byStore[s.id] = qty;
      }
      perStore[p.id] = byStore;
    }
    return _StocksData(products: products, perStore: perStore);
  }

  String _storeName(String id) {
    for (final s in widget.stores) {
      if (s.id == id) return s.name.isEmpty ? '(Sin nombre)' : s.name;
    }
    return id.isEmpty ? '(Sin sucursal)' : id.substring(0, id.length.clamp(0, 6));
  }

  @override
  Widget build(BuildContext context) {
    final scope = context.watch<AdminScope>();
    final totals = _DashboardTotals(widget.sales);
    final activeStores = widget.stores.where((s) => s.active).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1100;
        final kpiCols = constraints.maxWidth >= 1400 ? 4 : (wide ? 4 : 2);
        return ListView(
          padding: EdgeInsets.all(wide ? 24 : 16).copyWith(
            bottom: BottomPadding.of(context, minimum: 24),
          ),
          children: [
            const AdminSectionHeader(
              title: 'Dashboard',
              subtitle: 'Resumen general del negocio',
            ),
            const SizedBox(height: 12),
            AdminScopeBanner(
              isAllStores: scope.isAllStores,
              storeName: _storeName(scope.selectedStoreId ?? ''),
              rangeLabel: scope.range.label,
              activeStoreCount: activeStores,
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: kpiCols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.55,
              children: [
                AdminKpiCard(
                  label: 'Ventas netas',
                  value: AdminFormat.money(totals.net),
                  icon: Icons.trending_up_outlined,
                  color: AdminColors.success,
                  softBg: AdminColors.successBg,
                ),
                AdminKpiCard(
                  label: 'Ventas brutas',
                  value: AdminFormat.money(totals.gross),
                  icon: Icons.point_of_sale_outlined,
                  color: AdminColors.accent,
                  softBg: AdminColors.accentSoft,
                ),
                AdminKpiCard(
                  label: 'Devoluciones',
                  value: AdminFormat.money(totals.refundTotal),
                  icon: Icons.undo_outlined,
                  color: AdminColors.danger,
                  softBg: AdminColors.dangerBg,
                ),
                AdminKpiCard(
                  label: 'Tickets',
                  value: '${totals.originals.length}',
                  icon: Icons.receipt_long_outlined,
                  color: AdminColors.info,
                  softBg: AdminColors.infoBg,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _SalesByStoreCard(sales: widget.sales, storeName: _storeName, showAll: scope.isAllStores)),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: _PaymentCard(totals: totals)),
                ],
              )
            else ...[
              _SalesByStoreCard(sales: widget.sales, storeName: _storeName, showAll: scope.isAllStores),
              const SizedBox(height: 12),
              _PaymentCard(totals: totals),
            ],
            const SizedBox(height: 12),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _TopArticlesCard(sales: widget.sales)),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: _PeriodSummaryCard(totals: totals)),
                ],
              )
            else ...[
              _TopArticlesCard(sales: widget.sales),
              const SizedBox(height: 12),
              _PeriodSummaryCard(totals: totals),
            ],
            const SizedBox(height: 12),
            if (scope.isAllStores) ...[
              _StoresSummaryCard(
                sales: widget.sales,
                stores: widget.stores,
                storeName: _storeName,
                stocksFuture: _stocksFuture,
                onRetry: () => setState(() => _stocksFuture = _loadStocks()),
              ),
              const SizedBox(height: 12),
            ],
            _InventoryCard(
              stores: widget.stores,
              storeName: _storeName,
              stocksFuture: _stocksFuture,
              onRetry: () => setState(() => _stocksFuture = _loadStocks()),
            ),
          ],
        );
      },
    );
  }
}

/// Ventas por sucursal: barras horizontales legibles, top 8.
class _SalesByStoreCard extends StatelessWidget {
  const _SalesByStoreCard({required this.sales, required this.storeName, required this.showAll});

  final List<Sale> sales;
  final String Function(String) storeName;
  final bool showAll;

  @override
  Widget build(BuildContext context) {
    final byStore = <String, double>{};
    for (final s in sales) {
      if (s.isRefund || s.isCancelled) continue;
      byStore[s.storeId] = (byStore[s.storeId] ?? 0) + s.total;
    }
    final entries = byStore.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final max = entries.isEmpty ? 1.0 : entries.first.value;

    return AdminCard(
      title: 'Ventas por sucursal',
      subtitle: showAll ? 'Todas las sucursales' : 'Sucursal seleccionada',
      child: entries.isEmpty
          ? const AdminEmptyState(
              icon: Icons.storefront_outlined,
              title: 'Sin ventas en este periodo',
              hint: 'Prueba otro rango de fechas o selecciona otra sucursal.',
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < entries.length.clamp(0, 8); i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(
                            storeName(entries[i].key),
                            style: AdminText.body,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (entries[i].value / max).clamp(0.0, 1.0),
                              minHeight: 10,
                              backgroundColor: AdminColors.track,
                              valueColor: AlwaysStoppedAnimation(
                                i == 0 ? AdminColors.accent : AdminColors.info,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 92,
                          child: Text(
                            AdminFormat.money(entries[i].value),
                            style: AdminText.body.copyWith(fontWeight: FontWeight.w700),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (entries.length > 8)
                  Text(
                    'Mostrando 8 de ${entries.length} sucursales',
                    style: AdminText.bodySmall,
                  ),
              ],
            ),
    );
  }
}

/// Métodos de pago: dona compacta + montos. Split ya viene repartido.
class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.totals});

  final _DashboardTotals totals;

  @override
  Widget build(BuildContext context) {
    final total = totals.cash + totals.card;
    final cashPct = total > 0 ? totals.cash / total * 100 : 0;

    return AdminCard(
      title: 'Métodos de pago',
      subtitle: 'Efectivo y tarjeta del periodo',
      child: total <= 0
          ? const AdminEmptyState(
              icon: Icons.payments_outlined,
              title: 'Sin cobros en este periodo',
              hint: 'Prueba otro rango de fechas o selecciona otra sucursal.',
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 170,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 52,
                          sections: [
                            PieChartSectionData(
                              value: totals.cash,
                              color: AdminColors.success,
                              title: '',
                              radius: 26,
                            ),
                            PieChartSectionData(
                              value: totals.card,
                              color: AdminColors.accent,
                              title: '',
                              radius: 26,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${cashPct.toStringAsFixed(0)}%',
                              style: AdminText.kpiValue.copyWith(fontSize: 26)),
                          const Text('Efectivo', style: AdminText.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _PayRow(dot: AdminColors.success, label: 'Efectivo', value: AdminFormat.money(totals.cash)),
                _PayRow(dot: AdminColors.accent, label: 'Tarjeta', value: AdminFormat.money(totals.card)),
                const SizedBox(height: 4),
                const Text(
                  'Mixto: se reparte entre efectivo y tarjeta.',
                  style: AdminText.bodySmall,
                ),
              ],
            ),
    );
  }
}

class _PayRow extends StatelessWidget {
  const _PayRow({required this.dot, required this.label, required this.value});

  final Color dot;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: AdminText.body)),
          Text(value, style: AdminText.body.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Productos más vendidos: ranking numerado con barra, sin gráficas complejas.
class _TopArticlesCard extends StatelessWidget {
  const _TopArticlesCard({required this.sales});

  final List<Sale> sales;

  @override
  Widget build(BuildContext context) {
    final qtyByName = <String, double>{};
    final totalByName = <String, double>{};
    for (final s in sales) {
      if (s.isRefund || s.isCancelled) continue;
      for (final item in s.items) {
        final name = ((item['name'] as String?) ?? 'Producto').trim();
        if (name.isEmpty) continue;
        final qty = (item['quantity'] as num? ?? 0).toDouble();
        final subtotal =
            ((item['subtotal'] as num?) ?? ((item['unitPrice'] as num? ?? 0).toDouble() * qty)).toDouble();
        qtyByName[name] = (qtyByName[name] ?? 0) + qty;
        totalByName[name] = (totalByName[name] ?? 0) + subtotal;
      }
    }
    final sorted = qtyByName.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(6).toList();
    final maxQty = top.isEmpty ? 1.0 : top.first.value;

    return AdminCard(
      title: 'Productos más vendidos',
      subtitle: 'Por cantidad del periodo',
      child: top.isEmpty
          ? const AdminEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Sin artículos en este periodo',
              hint: 'Prueba otro rango de fechas o selecciona otra sucursal.',
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < top.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 28,
                              child: Text(
                                (i + 1).toString().padLeft(2, '0'),
                                style: AdminText.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AdminColors.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(top[i].key, style: AdminText.body.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            Text(
                              '${AdminFormat.qty(top[i].value)} uds · ${AdminFormat.money(totalByName[top[i].key] ?? 0)}',
                              style: AdminText.bodySmall.copyWith(color: AdminColors.text),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 28),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (top[i].value / maxQty).clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: AdminColors.track,
                              valueColor: const AlwaysStoppedAnimation(AdminColors.accent),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Resumen del periodo: métricas secundarias (ticket prom., descuentos, efectivo, tarjeta).
class _PeriodSummaryCard extends StatelessWidget {
  const _PeriodSummaryCard({required this.totals});

  final _DashboardTotals totals;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      title: 'Resumen del periodo',
      subtitle: 'Métricas secundarias',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdminStatRow(label: 'Ticket promedio', value: AdminFormat.money(totals.avgTicket), icon: Icons.receipt_long_outlined),
          const Divider(height: 1, color: AdminColors.border),
          AdminStatRow(label: 'Descuentos', value: AdminFormat.money(totals.discounts), icon: Icons.discount_outlined),
          const Divider(height: 1, color: AdminColors.border),
          AdminStatRow(label: 'Efectivo', value: AdminFormat.money(totals.cash), icon: Icons.payments_outlined),
          const Divider(height: 1, color: AdminColors.border),
          AdminStatRow(label: 'Tarjeta', value: AdminFormat.money(totals.card), icon: Icons.credit_card_outlined),
        ],
      ),
    );
  }
}

/// Resumen de sucursales (solo TODAS): ventas, tickets y estado de stock.
/// Reutiliza las ventas ya cargadas + el stock ya cargado: sin consultas nuevas.
class _StoresSummaryCard extends StatelessWidget {
  const _StoresSummaryCard({
    required this.sales,
    required this.stores,
    required this.storeName,
    required this.stocksFuture,
    required this.onRetry,
  });

  final List<Sale> sales;
  final List<Store> stores;
  final String Function(String) storeName;
  final Future<_StocksData> stocksFuture;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final salesByStore = <String, double>{};
    final ticketsByStore = <String, int>{};
    for (final s in sales) {
      if (s.isRefund || s.isCancelled) continue;
      salesByStore[s.storeId] = (salesByStore[s.storeId] ?? 0) + s.total;
      ticketsByStore[s.storeId] = (ticketsByStore[s.storeId] ?? 0) + 1;
    }
    final ordered = stores.toList()
      ..sort((a, b) => (salesByStore[b.id] ?? 0).compareTo(salesByStore[a.id] ?? 0));

    return AdminCard(
      title: 'Resumen de sucursales',
      subtitle: 'Consolidado del periodo',
      child: FutureBuilder<_StocksData>(
        future: stocksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AdminSkeleton(lines: 4);
          }
          if (snapshot.hasError) {
            return AdminErrorState(
              message: 'No fue posible cargar el stock.',
              details: '${snapshot.error}',
              onRetry: onRetry,
            );
          }
          final data = snapshot.data;
          if (data == null || ordered.isEmpty) {
            return const AdminEmptyState(
              icon: Icons.storefront_outlined,
              title: 'Sin sucursales para resumir',
              hint: 'Verifica que existan sucursales activas.',
            );
          }
          return AdminTable(
            columns: const ['Sucursal', 'Ventas', 'Tickets', 'Stock'],
            flex: const [3, 2, 2, 2],
            rows: [
              for (final store in ordered)
                [
                  Text(store.name.isEmpty ? '(Sin nombre)' : store.name,
                      style: AdminText.body.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(AdminFormat.money(salesByStore[store.id] ?? 0),
                      style: AdminText.body.copyWith(fontWeight: FontWeight.w700)),
                  Text('${ticketsByStore[store.id] ?? 0}', style: AdminText.body),
                  _storeStockBadge(data, store.id),
                ],
            ],
          );
        },
      ),
    );
  }

  /// Estado de la sucursal: Crítico si algún producto está en 0,
  /// Bajo si alguno está bajo su alerta, Normal en otro caso.
  Widget _storeStockBadge(_StocksData data, String storeId) {
    var hasZero = false;
    var hasLow = false;
    for (final p in data.products) {
      final qty = data.perStore[p.id]?[storeId] ?? 0;
      if (qty <= 0) {
        hasZero = true;
        break;
      }
      if (p.lowStockAlertQuantity > 0 && qty <= p.lowStockAlertQuantity) hasLow = true;
    }
    if (hasZero) {
      return const AdminStatusBadge.custom(label: 'Crítico', color: AdminColors.danger, bg: AdminColors.dangerBg);
    }
    if (hasLow) {
      return const AdminStatusBadge.custom(label: 'Bajo', color: AdminColors.warning, bg: AdminColors.warningBg);
    }
    return const AdminStatusBadge.custom(label: 'Normal', color: AdminColors.success, bg: AdminColors.successBg);
  }
}

/// Inventario por sucursal: tabla Producto × sucursales + Total + Estado.
/// Compacta (8) / expandida (60), en el mismo lugar, con scroll interno.
class _InventoryCard extends StatefulWidget {
  const _InventoryCard({
    required this.stores,
    required this.storeName,
    required this.stocksFuture,
    required this.onRetry,
  });

  final List<Store> stores;
  final String Function(String) storeName;
  final Future<_StocksData> stocksFuture;
  final VoidCallback onRetry;

  @override
  State<_InventoryCard> createState() => _InventoryCardState();
}

class _InventoryCardState extends State<_InventoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final visibleStores = widget.stores.take(6).toList();
    return AdminCard(
      title: 'Inventario por sucursal',
      subtitle: _expanded
          ? 'Vista expandida · desplázate dentro del panel'
          : 'Vista compacta · pulsa Expandir para ver más aquí mismo',
      action: FilledButton.tonalIcon(
        onPressed: () => setState(() => _expanded = !_expanded),
        icon: Icon(_expanded ? Icons.unfold_less_outlined : Icons.unfold_more_outlined, size: 18),
        label: Text(_expanded ? 'Compactar' : 'Expandir'),
      ),
      child: FutureBuilder<_StocksData>(
        // Clave distinta al alternar para no conservar scroll stale.
        key: ValueKey('stock-${_expanded ? 'full' : 'compact'}'),
        future: widget.stocksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AdminSkeleton(lines: 5);
          }
          if (snapshot.hasError) {
            return AdminErrorState(
              message: 'No fue posible cargar el inventario.',
              details: '${snapshot.error}',
              onRetry: widget.onRetry,
            );
          }
          final data = snapshot.data;
          final rows = (data?.products ?? const <Product>[]).toList()
            ..sort((a, b) => data!.totalOf(a.id).compareTo(data.totalOf(b.id)));
          if (rows.isEmpty) {
            return const AdminEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Sin productos con inventario',
              hint: 'Crea productos con control de stock para verlos aquí.',
            );
          }
          final visible = rows.take(_expanded ? 60 : 8).toList();
          final flex = [3, for (var i = 0; i < visibleStores.length; i++) 1, 1, 1];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Mostrando ${visible.length} de ${rows.length} productos', style: AdminText.bodySmall),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                height: _expanded ? 520 : 320,
                child: SingleChildScrollView(
                  child: AdminTable(
                    columns: [
                      'Producto',
                      for (final s in visibleStores) _short(s.name),
                      'Total',
                      'Estado',
                    ],
                    flex: flex,
                    rows: [
                      for (final p in visible)
                        [
                          Text(p.name, style: AdminText.body.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                          for (final s in visibleStores)
                            Text(
                              AdminFormat.qty(data!.perStore[p.id]?[s.id] ?? 0),
                              style: AdminText.body,
                            ),
                          Text(
                            AdminFormat.qty(data!.totalOf(p.id)),
                            style: AdminText.body.copyWith(fontWeight: FontWeight.w700),
                          ),
                          AdminStatusBadge.stock(total: data.totalOf(p.id), alert: p.lowStockAlertQuantity),
                        ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _short(String name) {
    if (name.isEmpty) return '?';
    return name.length <= 6 ? name : '${name.substring(0, 6)}…';
  }
}
