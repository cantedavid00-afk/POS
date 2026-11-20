import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/models/employee.dart';
import '../../../../../shared/models/sale.dart';
import '../../../../../shared/models/store.dart';
import '../../../../../shared/widgets/bottom_padding.dart';
import 'admin_filters.dart';
import 'admin_sale_detail_screen.dart';
import 'admin_theme_tokens.dart';
import 'widgets/admin_card.dart';
import 'widgets/admin_data_table.dart';
import 'widgets/admin_search_bar.dart';
import 'widgets/admin_section_header.dart';
import 'widgets/admin_states.dart';
import 'widgets/admin_status_badge.dart';

/// Recibos administrador: tabla real con columnas fijas
/// Folio(130) · Sucursal(flex) · Fecha(120) · Pago(140) · Estado(130) ·
/// Total(130) · ›(48). Agrupada por día, con resumen y buscador compacto.
/// Filtros globales (TopBar) + buscador local por folio o importe.
class AdminReceiptsScreen extends StatefulWidget {
  const AdminReceiptsScreen({
    super.key,
    required this.businessId,
    required this.businessName,
    required this.stores,
    required this.employee,
  });

  final String businessId;
  final String businessName;
  final List<Store> stores;
  final Employee employee;

  @override
  State<AdminReceiptsScreen> createState() => _AdminReceiptsScreenState();
}

class _AdminReceiptsScreenState extends State<AdminReceiptsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _storeName(String id) {
    for (final s in widget.stores) {
      if (s.id == id) return s.name.isEmpty ? '(Sin nombre)' : s.name;
    }
    return id.isEmpty ? '—' : id.substring(0, id.length.clamp(0, 6));
  }

  Store? _storeFor(String id) {
    for (final s in widget.stores) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scope = context.watch<AdminScope>();
    final now = DateTime.now();
    final range = scope.range.resolve(now);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('businesses')
          .doc(widget.businessId)
          .collection('sales')
          .orderBy('clientCreatedAt', descending: true)
          .limit(300)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: const [
              AdminSectionHeader(title: 'Recibos', subtitle: 'Historial de ventas'),
              SizedBox(height: 16),
              AdminCard(child: AdminSkeleton(lines: 8)),
            ],
          );
        }
        if (snapshot.hasError) {
          return AdminErrorState(
            message: 'No se pudieron cargar los recibos. Verifica la conexión e inténtalo nuevamente.',
            details: '${snapshot.error}',
            onRetry: () => context.read<AdminScope>().touch(),
          );
        }
        final sales = <Sale>[];
        for (final d in snapshot.data?.docs ?? const []) {
          try {
            sales.add(Sale.fromDoc(d));
          } catch (_) {}
        }
        final q = _query.trim().toLowerCase();
        final filtered = sales.where((s) {
          if (!scope.isAllStores && s.storeId != scope.selectedStoreId) return false;
          final date = s.clientCreatedAt ?? s.createdAt;
          if (date == null || date.isBefore(range.start) || date.isAfter(range.end)) return false;
          if (q.isNotEmpty) {
            final folioHit = s.folio.toLowerCase().contains(q);
            final totalHit = s.total.toStringAsFixed(2).contains(q) ||
                s.total.toStringAsFixed(0).contains(q);
            if (!folioHit && !totalHit) return false;
          }
          return true;
        }).toList();

        var gross = 0.0;
        var refunds = 0.0;
        for (final s in filtered) {
          if (s.isRefund) {
            refunds += s.total;
          } else if (!s.isCancelled) {
            gross += s.total;
          }
        }

        return ListView(
          padding: EdgeInsets.all(24).copyWith(bottom: BottomPadding.of(context, minimum: 24)),
          children: [
            const AdminSectionHeader(title: 'Recibos', subtitle: 'Historial de ventas'),
            const SizedBox(height: 12),
            AdminScopeBanner(
              isAllStores: scope.isAllStores,
              storeName: _storeName(scope.selectedStoreId ?? ''),
              rangeLabel: scope.range.label,
              activeStoreCount: widget.stores.where((s) => s.active).length,
            ),
            const SizedBox(height: 16),
            AdminSearchBar(
              controller: _searchCtrl,
              hint: 'Buscar por folio o importe...',
              hasQuery: q.isNotEmpty,
              onChanged: (v) => setState(() => _query = v),
              onClear: () {
                _searchCtrl.clear();
                setState(() => _query = '');
              },
            ),
            const SizedBox(height: 12),
            _SummaryStrip(count: filtered.length, total: gross - refunds),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              AdminCard(
                child: AdminEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No hay recibos',
                  hint: 'No existen ventas en el periodo seleccionado.',
                ),
              ),
            if (filtered.isEmpty && q.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Limpiar búsqueda'),
                  ),
                ),
              ),
            if (filtered.isNotEmpty)
              for (final group in _groupByDay(filtered)) ...[
                _DayHeader(label: group.label, count: group.sales.length),
                AdminCard(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: AdminDataTable(
                    rowMinHeight: 68,
                    columns: const [
                      AdminColumn(label: 'Folio', width: 130),
                      AdminColumn(label: 'Sucursal', flex: 2),
                      AdminColumn(label: 'Fecha', width: 140),
                      AdminColumn(label: 'Pago', width: 150),
                      AdminColumn(label: 'Estado', width: 140),
                      AdminColumn(
                        label: 'Total',
                        width: 140,
                        align: Alignment.centerRight,
                        headerAlign: Alignment.centerRight,
                      ),
                      AdminColumn(label: 'Ver', width: 56, align: Alignment.center),
                    ],
                    rows: [
                      for (final sale in group.sales)
                        [
                          Text(sale.folio,
                              style: AdminText.body.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text(_storeName(sale.storeId),
                              style: AdminText.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(_dateTimeLabel(sale), style: AdminText.body),
                          _paymentCell(sale),
                          AdminStatusBadge.saleStatus(sale.status, isRefund: sale.isRefund),
                          Text(
                            AdminFormat.money(sale.total),
                            style: AdminText.body.copyWith(fontWeight: FontWeight.w700),
                          ),
                          IconButton(
                            tooltip: 'Ver detalle',
                            icon: const Icon(Icons.chevron_right, color: AdminColors.textSecondary),
                            onPressed: () => _openDetail(context, sale),
                          ),
                        ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
          ],
        );
      },
    );
  }

  void _openDetail(BuildContext context, Sale sale) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminSaleDetailScreen(
          businessName: widget.businessName,
          storeName: _storeName(sale.storeId),
          store: _storeFor(sale.storeId),
          sale: sale,
        ),
      ),
    );
  }

  List<_DayGroup> _groupByDay(List<Sale> sales) {
    final groups = <String, List<Sale>>{};
    final order = <String>[];
    for (final s in sales) {
      final d = s.clientCreatedAt ?? s.createdAt;
      final key = d == null ? 'Fecha pendiente' : _dayKey(d);
      if (!groups.containsKey(key)) {
        groups[key] = [];
        order.add(key);
      }
      groups[key]!.add(s);
    }
    return [for (final k in order) _DayGroup(label: k, sales: groups[k]!)];
  }

  static const _months = [
    'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN', 'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'
  ];

  String _dayKey(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';

  Widget _paymentCell(Sale sale) {
    if (sale.paymentMethod == 'split') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AdminStatusBadge.payment('split'),
          const SizedBox(height: 2),
          Text(
            'ef. ${AdminFormat.money(sale.cashAmount ?? 0)} · tj. ${AdminFormat.money(sale.cardAmount ?? 0)}',
            style: AdminText.bodySmall.copyWith(fontSize: 11),
          ),
        ],
      );
    }
    return AdminStatusBadge.payment(sale.paymentMethod);
  }

  String _dateTimeLabel(Sale sale) {
    final d = sale.clientCreatedAt ?? sale.createdAt;
    if (d == null) return '—';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm · $hh:$min';
  }
}

class _DayGroup {
  const _DayGroup({required this.label, required this.sales});

  final String label;
  final List<Sale> sales;
}

/// Franja compacta de resumen: conteo + importe neto del conjunto visible.
class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.count, required this.total});

  final int count;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(AdminRadii.button),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        children: [
          Text('$count recibos', style: AdminText.body.copyWith(fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(
            AdminFormat.money(total),
            style: AdminText.body.copyWith(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(label, style: AdminText.body.copyWith(fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('$count recibos', style: AdminText.bodySmall),
        ],
      ),
    );
  }
}
