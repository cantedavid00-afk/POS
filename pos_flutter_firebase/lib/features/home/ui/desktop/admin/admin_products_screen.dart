import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/models/product.dart';
import '../../../../../shared/models/sale.dart';
import '../../../../../shared/models/store.dart';
import '../../../../../shared/widgets/bottom_padding.dart';
import 'admin_filters.dart';
import 'admin_theme_tokens.dart';
import 'widgets/admin_card.dart';
import 'widgets/admin_data_table.dart';
import 'widgets/admin_search_bar.dart';
import 'widgets/admin_section_header.dart';
import 'widgets/admin_states.dart';
import 'widgets/admin_status_badge.dart';

/// Productos administrador: catálogo + inventario.
///
/// - Ancho >= 1100: tabla real. En TODAS con columna por sucursal;
///   en sucursal única con columnas simplificadas.
/// - Ancho < 1100: tarjetas compactas de dos niveles.
/// - Buscador compacto + pills Todos/Bajo stock en la misma fila.
/// - Tap → `/home/products/edit`; [+ Producto] → `/home/products/add`.
class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key, required this.businessId, required this.stores});

  final String businessId;
  final List<Store> stores;

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _onlyLowStock = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _storeName(String id) {
    for (final s in widget.stores) {
      if (s.id == id) return s.name.isEmpty ? '(Sin nombre)' : s.name;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final scope = context.watch<AdminScope>();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('businesses')
          .doc(widget.businessId)
          .collection('products')
          .where('active', isEqualTo: true)
          .limit(200)
          .snapshots(),
      builder: (context, prodSnap) {
        if (prodSnap.connectionState == ConnectionState.waiting) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: const [
              AdminSectionHeader(title: 'Productos', subtitle: 'Catálogo e inventario'),
              SizedBox(height: 16),
              AdminCard(child: AdminSkeleton(lines: 8)),
            ],
          );
        }
        if (prodSnap.hasError) {
          return AdminErrorState(
            message: 'No se pudieron cargar los productos. Verifica la conexión e inténtalo nuevamente.',
            details: '${prodSnap.error}',
            onRetry: () => context.read<AdminScope>().touch(),
          );
        }
        final products = <Product>[];
        for (final d in prodSnap.data?.docs ?? const []) {
          try {
            products.add(Product.fromDoc(d));
          } catch (_) {}
        }
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('businesses')
              .doc(widget.businessId)
              .collection('sales')
              .orderBy('clientCreatedAt', descending: true)
              .limit(300)
              .snapshots(),
          builder: (context, salesSnap) {
            final now = DateTime.now();
            final resolved = scope.range.resolve(now);
            final soldByProduct = <String, double>{};
            if (salesSnap.hasData) {
              for (final d in salesSnap.data!.docs) {
                Sale sale;
                try {
                  sale = Sale.fromDoc(d);
                } catch (_) {
                  continue;
                }
                if (sale.isRefund || sale.isCancelled) continue;
                if (!scope.isAllStores && sale.storeId != scope.selectedStoreId) continue;
                final date = sale.clientCreatedAt ?? sale.createdAt;
                if (date == null || date.isBefore(resolved.start) || date.isAfter(resolved.end)) {
                  continue;
                }
                for (final item in sale.items) {
                  final pid = (item['productId'] as String?) ?? '';
                  if (pid.isEmpty) continue;
                  soldByProduct[pid] =
                      (soldByProduct[pid] ?? 0) + ((item['quantity'] as num? ?? 0).toDouble());
                }
              }
            }
            return _CatalogBody(
              businessId: widget.businessId,
              stores: widget.stores,
              products: products,
              soldByProduct: soldByProduct,
              query: _query,
              onlyLowStock: _onlyLowStock,
              searchCtrl: _searchCtrl,
              storeName: _storeName,
              rangeLabel: scope.range.label,
              isAllStores: scope.isAllStores,
              selectedStoreId: scope.selectedStoreId,
              onQuery: (v) => setState(() => _query = v),
              onClearQuery: () {
                _searchCtrl.clear();
                setState(() => _query = '');
              },
              onToggleLow: (v) => setState(() => _onlyLowStock = v),
            );
          },
        );
      },
    );
  }
}

class _CatalogBody extends StatelessWidget {
  const _CatalogBody({
    required this.businessId,
    required this.stores,
    required this.products,
    required this.soldByProduct,
    required this.query,
    required this.onlyLowStock,
    required this.searchCtrl,
    required this.storeName,
    required this.rangeLabel,
    required this.isAllStores,
    required this.selectedStoreId,
    required this.onQuery,
    required this.onClearQuery,
    required this.onToggleLow,
  });

  final String businessId;
  final List<Store> stores;
  final List<Product> products;
  final Map<String, double> soldByProduct;
  final String query;
  final bool onlyLowStock;
  final TextEditingController searchCtrl;
  final String Function(String) storeName;
  final String rangeLabel;
  final bool isAllStores;
  final String? selectedStoreId;
  final ValueChanged<String> onQuery;
  final VoidCallback onClearQuery;
  final ValueChanged<bool> onToggleLow;

  Future<Map<String, Map<String, double>>> _loadStocks() async {
    final db = FirebaseFirestore.instance;
    final scopeStores = stores.take(6).toList();
    final result = <String, Map<String, double>>{};
    for (final p in products.take(120)) {
      final perStore = <String, double>{};
      for (final s in scopeStores) {
        try {
          final doc = await db
              .collection('businesses')
              .doc(businessId)
              .collection('products')
              .doc(p.id)
              .collection('stockByStore')
              .doc(s.id)
              .get();
          if (doc.exists) {
            final data = doc.data() ?? {};
            perStore[s.id] = ((data['stockQuantity'] as num?) ?? 0).toDouble();
          } else {
            perStore[s.id] = 0;
          }
        } catch (_) {
          perStore[s.id] = 0;
        }
      }
      result[p.id] = perStore;
    }
    return result;
  }

  double _totalOf(Map<String, double>? perStore) {
    var total = 0.0;
    for (final v in (perStore ?? const <String, double>{}).values) {
      total += v;
    }
    return total;
  }

  bool _isLow(Product p, double total) {
    if (!p.trackStock) return false;
    if (p.lowStockAlertQuantity <= 0) return total <= 0;
    return total <= p.lowStockAlertQuantity;
  }

  void _openEdit(BuildContext context, Product p) {
    final storeId = selectedStoreId ?? (stores.isNotEmpty ? stores.first.id : '');
    context.push(
      '/home/products/edit',
      extra: {'businessId': businessId, 'storeId': storeId, 'product': p},
    );
  }

  void _openAdd(BuildContext context) {
    final storeId = selectedStoreId ?? (stores.isNotEmpty ? stores.first.id : '');
    context.push('/home/products/add', extra: {'businessId': businessId, 'storeId': storeId});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, Map<String, double>>>(
      future: _loadStocks(),
      builder: (context, snapshot) {
        final stocks = snapshot.data ?? const <String, Map<String, double>>{};
        final q = query.trim().toLowerCase();
        final rows = <Product>[];
        for (final p in products) {
          if (q.isNotEmpty &&
              !p.name.toLowerCase().contains(q) &&
              !p.ref.toLowerCase().contains(q)) {
            continue;
          }
          if (onlyLowStock && !_isLow(p, _totalOf(stocks[p.id]))) continue;
          rows.add(p);
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1100;
            return ListView(
              padding: EdgeInsets.all(24).copyWith(
                bottom: BottomPadding.of(context, minimum: 90),
              ),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: AdminSectionHeader(
                        title: 'Productos',
                        subtitle: 'Catálogo e inventario',
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () => _openAdd(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Producto'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AdminScopeBanner(
                  isAllStores: isAllStores,
                  storeName: storeName(selectedStoreId ?? ''),
                  rangeLabel: rangeLabel,
                  activeStoreCount: stores.where((s) => s.active).length,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AdminSearchBar(
                        controller: searchCtrl,
                        hint: 'Buscar producto o referencia...',
                        hasQuery: q.isNotEmpty,
                        onChanged: onQuery,
                        onClear: onClearQuery,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('Todos'),
                      selected: !onlyLowStock,
                      onSelected: (_) => onToggleLow(false),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Bajo stock'),
                      selected: onlyLowStock,
                      onSelected: (_) => onToggleLow(true),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const AdminCard(child: AdminSkeleton(lines: 8))
                else if (rows.isEmpty)
                  AdminCard(
                    child: AdminEmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'Sin productos para este filtro',
                      hint: 'Prueba otra búsqueda o desactiva el filtro de bajo stock.',
                    ),
                  )
                else if (wide)
                  _WideTable(
                    rows: rows,
                    stocks: stocks,
                    stores: stores,
                    isAllStores: isAllStores,
                    selectedStoreId: selectedStoreId,
                    soldByProduct: soldByProduct,
                    isLow: _isLow,
                    totalOf: _totalOf,
                    onTap: (p) => _openEdit(context, p),
                  )
                else
                  for (final p in rows) ...[
                    _CompactCard(
                      product: p,
                      perStore: stocks[p.id] ?? const {},
                      stores: stores,
                      total: _totalOf(stocks[p.id]),
                      sold: soldByProduct[p.id] ?? 0,
                      low: _isLow(p, _totalOf(stocks[p.id])),
                      isAllStores: isAllStores,
                      onTap: () => _openEdit(context, p),
                    ),
                    const SizedBox(height: 10),
                  ],
                if (rows.isNotEmpty && (q.isNotEmpty || onlyLowStock))
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Center(
                      child: FilledButton.tonalIcon(
                        onPressed: () {
                          onClearQuery();
                          onToggleLow(false);
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Limpiar filtros'),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Tabla ancha: en TODAS una columna por sucursal; en sucursal única,
/// columnas simplificadas (producto, precio, stock, vendidos, estado).
class _WideTable extends StatelessWidget {
  const _WideTable({
    required this.rows,
    required this.stocks,
    required this.stores,
    required this.isAllStores,
    required this.selectedStoreId,
    required this.soldByProduct,
    required this.isLow,
    required this.totalOf,
    required this.onTap,
  });

  final List<Product> rows;
  final Map<String, Map<String, double>> stocks;
  final List<Store> stores;
  final bool isAllStores;
  final String? selectedStoreId;
  final Map<String, double> soldByProduct;
  final bool Function(Product, double) isLow;
  final double Function(Map<String, double>?) totalOf;
  final ValueChanged<Product> onTap;

  @override
  Widget build(BuildContext context) {
    final perStoreCols = isAllStores ? stores.take(6).toList() : const <Store>[];

    List<AdminColumn> columns() {
      if (isAllStores) {
        return [
          const AdminColumn(label: 'Producto', flex: 3),
          const AdminColumn(label: 'Precio', width: 110, align: Alignment.centerRight, headerAlign: Alignment.centerRight),
          for (final s in perStoreCols)
            AdminColumn(label: _short(s.name), width: 96, align: Alignment.center),
          const AdminColumn(label: 'Vendidos', width: 90, align: Alignment.centerRight, headerAlign: Alignment.centerRight),
          const AdminColumn(label: 'Estado', width: 120),
          const AdminColumn(label: 'Ver', width: 56, align: Alignment.center),
        ];
      }
      return const [
        AdminColumn(label: 'Producto', flex: 3),
        AdminColumn(label: 'Precio', width: 110, align: Alignment.centerRight, headerAlign: Alignment.centerRight),
        AdminColumn(label: 'Stock', width: 110, align: Alignment.centerRight, headerAlign: Alignment.centerRight),
        AdminColumn(label: 'Vendidos', width: 90, align: Alignment.centerRight, headerAlign: Alignment.centerRight),
        AdminColumn(label: 'Estado', width: 120),
        AdminColumn(label: 'Ver', width: 56, align: Alignment.center),
      ];
    }

    return AdminCard(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: AdminDataTable(
        rowMinHeight: 80,
        columns: columns(),
        rows: [for (final p in rows) _cells(context, p, perStoreCols)],
      ),
    );
  }

  List<Widget> _cells(BuildContext context, Product p, List<Store> perStoreCols) {
    final perStore = stocks[p.id] ?? const <String, double>{};
    final total = totalOf(perStore);
    final sold = soldByProduct[p.id] ?? 0;
    final low = isLow(p, total);

    final productCell = Row(
      children: [
        _SafeThumb(product: p),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(p.name,
                  style: AdminText.body.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('REF ${p.ref.isEmpty ? '—' : p.ref}', style: AdminText.bodySmall),
            ],
          ),
        ),
      ],
    );
    final priceCell = Text(AdminFormat.money(p.price),
        style: AdminText.body.copyWith(fontWeight: FontWeight.w700));
    final soldCell = Text(AdminFormat.qty(sold), style: AdminText.body);
    final badge = low
        ? AdminStatusBadge.stock(total: total, alert: p.lowStockAlertQuantity)
        : const AdminStatusBadge.custom(
            label: 'Normal', color: AdminColors.success, bg: AdminColors.successBg);
    final action = IconButton(
      tooltip: 'Editar producto',
      icon: const Icon(Icons.chevron_right, color: AdminColors.textSecondary),
      onPressed: () => onTap(p),
    );

    if (isAllStores) {
      return [
        productCell,
        priceCell,
        for (final s in perStoreCols) _stockCell(perStore[s.id] ?? 0, p.lowStockAlertQuantity),
        soldCell,
        badge,
        action,
      ];
    }
    final singleQty = selectedStoreId == null ? total : (perStore[selectedStoreId] ?? total);
    return [
      productCell,
      priceCell,
      Text(
        p.trackStock ? AdminFormat.qty(singleQty) : '—',
        style: AdminText.body.copyWith(fontWeight: FontWeight.w600),
      ),
      soldCell,
      badge,
      action,
    ];
  }

  /// Celda de stock por sucursal: cantidad + ⚠ si está baja/crítica.
  Widget _stockCell(double qty, double alert) {
    final critical = qty <= 0;
    final low = !critical && alert > 0 && qty <= alert;
    final color = critical
        ? AdminColors.danger
        : (low ? AdminColors.warning : AdminColors.text);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (critical || low)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(Icons.warning_amber_rounded, size: 15, color: color),
          ),
        Text(
          AdminFormat.qty(qty),
          style: AdminText.body.copyWith(fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }

  String _short(String name) {
    if (name.isEmpty) return '—';
    return name.length <= 8 ? name : '${name.substring(0, 8)}…';
  }
}

/// Tarjeta compacta de dos niveles para ventanas angostas (< 1100).
class _CompactCard extends StatelessWidget {
  const _CompactCard({
    required this.product,
    required this.perStore,
    required this.stores,
    required this.total,
    required this.sold,
    required this.low,
    required this.isAllStores,
    required this.onTap,
  });

  final Product product;
  final Map<String, double> perStore;
  final List<Store> stores;
  final double total;
  final double sold;
  final bool low;
  final bool isAllStores;
  final VoidCallback onTap;

  String _nameOf(String id) {
    for (final s in stores) {
      if (s.id == id) {
        final n = s.name;
        return n.isEmpty ? '—' : (n.length <= 5 ? n : '${n.substring(0, 5)}…');
      }
    }
    return id.substring(0, id.length.clamp(0, 4));
  }

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SafeThumb(product: product),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name,
                          style: AdminText.body.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text('REF ${product.ref.isEmpty ? '—' : product.ref}',
                          style: AdminText.bodySmall),
                    ],
                  ),
                ),
                Text(AdminFormat.money(product.price),
                    style: AdminText.body.copyWith(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: AdminColors.textSecondary),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: AdminColors.border),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'Stock total',
                    value: product.trackStock ? AdminFormat.qty(total) : '—',
                    alert: low,
                  ),
                ),
                Expanded(
                  child: _MiniStat(label: 'Vendidos', value: AdminFormat.qty(sold), alert: false),
                ),
                AdminStatusBadge.stock(total: product.trackStock ? total : 1, alert: product.lowStockAlertQuantity),
              ],
            ),
            if (isAllStores && product.trackStock && perStore.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                perStore.entries
                    .map((e) => '${_nameOf(e.key)} ${AdminFormat.qty(e.value)}')
                    .join(' · '),
                style: AdminText.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.alert});

  final String label;
  final String value;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AdminText.badge.copyWith(color: AdminColors.textSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: AdminText.body.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: alert ? AdminColors.danger : AdminColors.text,
          ),
        ),
      ],
    );
  }
}

/// Miniatura a prueba de desktop: verifica el archivo antes de Image.file.
class _SafeThumb extends StatelessWidget {
  const _SafeThumb({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final path = product.localImagePath;
    if (product.presentationType == 'image' && path != null && path.isNotEmpty) {
      try {
        if (File(path).existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(path),
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _Fallback(product: product),
            ),
          );
        }
      } catch (_) {}
    }
    return _Fallback(product: product);
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final raw = product.presentationColor == 0 ? 0xFF9E9E9E : product.presentationColor;
    final color = Color(raw);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        product.name.isEmpty ? '?' : product.name.characters.first.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }
}
