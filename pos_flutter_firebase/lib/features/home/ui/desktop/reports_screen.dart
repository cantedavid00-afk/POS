import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../shared/models/employee.dart';
import '../../../../shared/models/store.dart';
import '../../../../shared/models/sale.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../shared/extensions/num_x.dart';
import '../../../../shared/extensions/string_x.dart';
import '../../../../shared/widgets/bottom_padding.dart';

class SalesReportScreen extends StatelessWidget {
  final String businessId;
  final String businessName;
  final Store store;
  final Employee employee;

  const SalesReportScreen({
    super.key,
    required this.businessId,
    required this.businessName,
    required this.store,
    required this.employee,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ventas - ${store.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportExcel(context),
            tooltip: 'Exportar Excel',
          ),
        ],
      ),
      body: StreamBuilder<List<Sale>>(
        stream: FirebaseFirestore.instance
            .collection('businesses')
            .doc(businessId)
            .collection('sales')
            .orderBy('createdAt', descending: true)
            .snapshots()
            .map((s) => s.docs.map((d) => Sale.fromDoc(d)).toList()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final sales = snapshot.data ?? const <Sale>[];
          final filtered = sales.where((s) {
            final d = s.clientCreatedAt ?? s.createdAt;
            return d != null && d.isAfter(DateTime.now().subtract(const Duration(days: 30)));
          }).toList();

          return ListView(
            padding: EdgeInsets.all(20).copyWith(
              bottom: BottomPadding.of(context, minimum: 20),
            ),
            children: [
              _MetricRow(
                label: 'Ventas totales',
                value: '\$${filtered.where((s) => !s.isRefund).fold<double>(0.0, (total, s) => total + s.total).humanizedCount(decimalDigits: 2)}',
                icon: Icons.trending_up,
                color: AppColors.success,
              ),
              const SizedBox(height: 12),
              _MetricRow(
                label: 'Devoluciones',
                value: '\$${filtered.where((s) => s.isRefund).fold<double>(0.0, (total, s) => total + s.total).humanizedCount(decimalDigits: 2)}',
                icon: Icons.undo,
                color: AppColors.danger,
              ),
              const SizedBox(height: 12),
              _MetricRow(
                label: 'Ticket promedio',
                value: '\$${(filtered.where((s) => !s.isRefund).isEmpty ? 0.0 : filtered.where((s) => !s.isRefund).fold<double>(0.0, (total, s) => total + s.total) / filtered.where((s) => !s.isRefund).length).humanizedCount(decimalDigits: 2)}',
                icon: Icons.receipt,
                color: AppColors.accent,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ventas por categor\u00eda', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      SizedBox(height: 200, child: _buildCategoryChart(filtered)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Productos m\u00e1s vendidos', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      ..._getTopProducts(filtered).take(10).map(
                        (product) => ListTile(
                          title: Text(product.key.orPlaceholder()),
                          trailing: Text('\$${product.value.humanizedCount(decimalDigits: 2)}', style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Recibos recientes', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...filtered.take(20).map(
                (sale) => Card(
                  child: ListTile(
                    title: Text(sale.folio.orPlaceholder()),
                    subtitle: Text('${sale.items.length} art\u00edculos · ${sale.paymentMethod == 'cash' ? 'Efectivo' : 'Tarjeta'}'),
                    trailing: Text('\$${sale.total.humanizedCount(decimalDigits: 2)}', style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  List<MapEntry<String, double>> _getTopProducts(List<Sale> sales) {
    final products = <String, double>{};
    for (final sale in sales) {
      if (sale.isRefund) continue;
      for (final item in sale.items) {
        final name = item['name'] as String? ?? 'Producto';
        final subtotal = (item['subtotal'] as num?)?.toDouble() ?? 0;
        products[name] = (products[name] ?? 0) + subtotal;
      }
    }
    return products.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  Widget _buildCategoryChart(List<Sale> sales) {
    final categories = <String, double>{};
    for (final sale in sales) {
      if (sale.isRefund) continue;
      for (final item in sale.items) {
        final cat = item['categoryName'] as String? ?? 'Sin categor\u00eda';
        final subtotal = (item['subtotal'] as num?)?.toDouble() ?? 0;
        categories[cat] = (categories[cat] ?? 0) + subtotal;
      }
    }
    final entries = categories.entries.toList();
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: entries.asMap().entries.map((entry) {
          final colors = <Color>[AppColors.accent, AppColors.success, AppColors.warning, AppColors.danger, const Color(0xFF7C4DFF), const Color(0xFF00BFA5)];
          return PieChartSectionData(
            value: entry.value.value,
            color: colors[entry.key % colors.length],
            title: '${entry.value.key}\n${entry.value.value.humanizedCount(decimalDigits: 0)}',
          );
        }).toList(),
      ),
    );
  }

  void _exportExcel(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exportando Excel...')),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricRow({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontFeatures: [FontFeature.tabularFigures()])),
        subtitle: Text(label),
      ),
    );
  }
}









