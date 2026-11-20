import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../shared/models/employee.dart';
import '../../../../shared/models/store.dart';
import '../../../../shared/models/sale.dart';
import '../../../../shared/providers/app_session_notifier.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../shared/extensions/num_x.dart';
import '../../../../shared/widgets/bottom_padding.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedStoreId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSessionNotifier>(
      builder: (context, sessionNotifier, _) {
        final session = sessionNotifier.session;
        final employee = sessionNotifier.resolvedEmployee;
        final stores = session?.stores ?? [];
        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
            actions: [
              DropdownButton<String?>(
                value: _selectedStoreId,
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Todas las sucursales')),
                  ...stores.map((s) => DropdownMenuItem<String?>(value: s.id, child: Text(s.name))),
                ],
                onChanged: (v) => setState(() => _selectedStoreId = v),
              ),
              const Padding(padding: EdgeInsets.only(right: 16)),
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(
                businessId: session?.business.id ?? '',
                selectedStoreId: _selectedStoreId,
                stores: stores,
              ),
              _MetricsTab(
                businessId: session?.business.id ?? '',
                selectedStoreId: _selectedStoreId,
                stores: stores,
              ),
              _QuickActionsTab(employee: employee),
            ],
          ),
        );
      },
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.businessId, required this.selectedStoreId, required this.stores});

  final String businessId;
  final String? selectedStoreId;
  final List<Store> stores;

  String _storeName(String? id) {
    return stores.firstWhere((s) => s.id == id, orElse: () => const Store(id: '', name: '', address: '', phone: '', active: false)).name;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(20).copyWith(
        bottom: BottomPadding.of(context, minimum: 20),
      ),
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.accent),
            const SizedBox(width: 8),
            Text(
              'Hoy',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _MetricCard(title: 'Ventas del d\u00eda', icon: Icons.point_of_sale, color: AppColors.accent),
        const SizedBox(height: 12),
        _MetricCard(title: 'Tickets promedio', icon: Icons.receipt, color: AppColors.success),
        const SizedBox(height: 12),
        _MetricCard(title: 'Productos vendidos', icon: Icons.shopping_bag, color: AppColors.warning),
        const SizedBox(height: 12),
        _MetricCard(title: 'Clientes nuevos', icon: Icons.person_add, color: AppColors.danger),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ventas por d\u00eda (\u00faltimos 7 d\u00edas)', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                SizedBox(height: 200, child: _buildBarChart()),
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
                Text('Categor\u00edas m\u00e1s vendidas', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                SizedBox(height: 200, child: _buildPieChart()),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (selectedStoreId != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.store, color: AppColors.accent),
              title: Text('Sucursal: ${_storeName(selectedStoreId)}'),
              subtitle: const Text('Últimos movimientos'),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
      ],
    );
  }

  Widget _buildBarChart() {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: i)));
    days.sort((a, b) => a.compareTo(b));
    final values = days.map((_) => (100 + (DateTime.now().millisecond % 500) / 10).toDouble()).toList();

    return BarChart(
      BarChartData(
        barGroups: days.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [BarChartRodData(toY: values[entry.key], color: AppColors.accent, width: 16)],
          );
        }).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < days.length) {
                  final day = days[value.toInt()];
                  return Text('${day.day} ${DateFormat('MMM', 'es').format(day)}', style: const TextStyle(fontSize: 10));
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildPieChart() {
    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(value: 35, color: AppColors.accent, title: 'Comida'),
          PieChartSectionData(value: 25, color: AppColors.success, title: 'Bebidas'),
          PieChartSectionData(value: 20, color: AppColors.warning, title: 'Productos'),
          PieChartSectionData(value: 20, color: AppColors.danger, title: 'Varios'),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _MetricCard({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.lightBorder)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text('\$${(100 + DateTime.now().second % 900).humanizedCount(decimalDigits: 2)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontFeatures: [FontFeature.tabularFigures()])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsTab extends StatelessWidget {
  const _MetricsTab({required this.businessId, required this.selectedStoreId, required this.stores});

  final String businessId;
  final String? selectedStoreId;
  final List<Store> stores;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Sale>>(
      stream: FirebaseFirestore.instance.collection('businesses').doc(businessId).collection('sales').snapshots().map((s) => s.docs.map((d) => Sale.fromDoc(d)).toList()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final sales = snapshot.data ?? const <Sale>[];
        final filtered = sales.where((s) {
          if (selectedStoreId != null && s.storeId != selectedStoreId) return false;
          final d = s.clientCreatedAt ?? s.createdAt;
          return d != null && d.isAfter(DateTime.now().subtract(const Duration(days: 30)));
        }).toList();

        return ListView(
          padding: EdgeInsets.all(20).copyWith(
            bottom: BottomPadding.of(context, minimum: 20),
          ),
          children: [
            Text('Estad\u00edsticas (30 d\u00edas)', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _StatGrid(
              sales: filtered,
              refunds: sales.where((s) => s.isRefund).toList(),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('M\u00e9todo de pago', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    _PaymentChart(sales: filtered),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatGrid extends StatelessWidget {
  final List<Sale> sales;
  final List<Sale> refunds;

  const _StatGrid({required this.sales, required this.refunds});

  double get _gross => sales.where((s) => !s.isRefund).fold<double>(0.0, (total, s) => total + s.total);
  double get _refund => refunds.fold<double>(0.0, (total, s) => total + s.total);
  double get _net => _gross - _refund;
  int get _cashCount => sales.where((s) => s.paymentMethod == 'cash' && !s.isRefund).length;
  int get _cardCount => sales.where((s) => s.paymentMethod == 'card' && !s.isRefund).length;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      ('Ventas brutas', _gross, Icons.trending_up, AppColors.success),
      ('Devoluciones', _refund, Icons.undo, AppColors.danger),
      ('Neto', _net, Icons.account_balance, AppColors.accent),
      ('En efectivo', _cashCount.toDouble(), Icons.account_balance_wallet, AppColors.success),
      ('Con tarjeta', _cardCount.toDouble(), Icons.credit_card, AppColors.warning),
      ('Ticket promedio', sales.isEmpty ? 0 : _gross / sales.where((s) => !s.isRefund).length, Icons.receipt, AppColors.warning),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 200, mainAxisExtent: 100, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final m = metrics[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(m.$3, color: m.$4, size: 20),
                const SizedBox(height: 8),
                Text('\$${m.$2.humanizedCount(decimalDigits: 2)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontFeatures: [FontFeature.tabularFigures()])),
                const SizedBox(height: 4),
                Text(m.$1, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PaymentChart extends StatelessWidget {
  final List<Sale> sales;

  const _PaymentChart({required this.sales});

  @override
  Widget build(BuildContext context) {
    final cash = sales.where((s) => s.paymentMethod == 'cash' && !s.isRefund).fold<double>(0.0, (total, s) => total + s.total);
    final card = sales.where((s) => s.paymentMethod == 'card' && !s.isRefund).fold<double>(0.0, (total, s) => total + s.total);
    final total = cash + card;
    final cashPct = total > 0 ? (cash / total * 100) : 0;
    final cardPct = total > 0 ? (card / total * 100) : 0;

    return Row(
      children: [
        Expanded(
          child: Column(children: [
            Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.accent, AppColors.accentDark]))),
            const SizedBox(height: 8),
            Text('Efectivo ${cashPct.humanizedCount(decimalDigits: 0)}%', style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
          ]),
        ),
        Expanded(
          child: Column(children: [
            Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.warning, const Color(0xFFFFA726)]))),
            const SizedBox(height: 8),
            Text('Tarjeta ${cardPct.humanizedCount(decimalDigits: 0)}%', style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
          ]),
        ),
      ],
    );
  }
}

class _QuickActionsTab extends StatelessWidget {
  const _QuickActionsTab({required this.employee});
  final Employee employee;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(20).copyWith(
        bottom: BottomPadding.of(context, minimum: 20),
      ),
      children: [
        Text('Acciones r\u00e1pidas', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _QuickActionCard(icon: Icons.point_of_sale, label: 'Nueva venta', color: AppColors.accent),
            _QuickActionCard(icon: Icons.receipt_long, label: 'Nuevo recibo', color: AppColors.success),
            _QuickActionCard(icon: Icons.inventory_2, label: 'Agregar producto', color: AppColors.warning),
            _QuickActionCard(icon: Icons.person_add, label: 'Nuevo empleado', color: AppColors.danger),
            _QuickActionCard(icon: Icons.warehouse, label: 'Ajustar stock', color: const Color(0xFF7C4DFF)),
            _QuickActionCard(icon: Icons.swap_horiz, label: 'Traspaso', color: const Color(0xFF00BFA5)),
            _QuickActionCard(icon: Icons.account_balance_wallet, label: 'Nuevo turno', color: const Color(0xFFFF6D00)),
            _QuickActionCard(icon: Icons.picture_as_pdf, label: 'Exportar Excel', color: const Color(0xFFD50032)),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Actividad reciente', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                _ActivityItem(icon: Icons.shopping_cart, text: 'Venta T-000001', time: 'Hace 5 min', color: AppColors.success),
                const Divider(height: 1),
                _ActivityItem(icon: Icons.person_add, text: 'Nuevo empleado: Juan', time: 'Hace 15 min', color: AppColors.accent),
                const Divider(height: 1),
                _ActivityItem(icon: Icons.inventory_2, text: 'Stock ajustado: Arroz', time: 'Hace 1 hora', color: AppColors.warning),
                const Divider(height: 1),
                _ActivityItem(icon: Icons.swap_horiz, text: 'Traspaso enviado', time: 'Hace 2 horas', color: const Color(0xFF00BFA5)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _QuickActionCard({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 100,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Container(
            decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.2))),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 8),
                Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final String time;
  final Color color;

  const _ActivityItem({required this.icon, required this.text, required this.time, required this.color});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(text),
      trailing: Text(time, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}










