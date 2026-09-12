import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../shared/models/employee.dart';
import '../../../../shared/models/shift.dart';
import '../../../../shared/models/store.dart';
import '../../../../core/theme/glass_theme.dart';

class ShiftsViewScreen extends StatefulWidget {
  final String businessId;
  final Store store;
  final Employee employee;

  const ShiftsViewScreen({
    super.key,
    required this.businessId,
    required this.store,
    required this.employee,
  });

  @override
  State<ShiftsViewScreen> createState() => _ShiftsViewScreenState();
}

class _ShiftsViewScreenState extends State<ShiftsViewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Turnos - ${widget.store.name}'),
      ),
      body: Column(
        children: [
          _SummaryCards(
            store: widget.store,
            shifts: const <Shift>[],
          ),
          Expanded(
            child: StreamBuilder<List<Shift>>(
              stream: FirebaseFirestore.instance
                  .collection('businesses')
                  .doc(widget.businessId)
                  .collection('shifts')
                  .orderBy('openedAt', descending: true)
                  .snapshots()
                  .map((s) => s.docs.map((d) => Shift.fromDoc(d)).toList()),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final shifts = snapshot.data ?? const <Shift>[];
                if (shifts.isEmpty) {
                  return const Center(child: Text('No hay turnos registrados.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: shifts.length,
                  itemBuilder: (context, index) {
                    final shift = shifts[index];
                    return _ShiftCard(shift: shift);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final Store store;
  final List<Shift> shifts;

  const _SummaryCards({required this.store, required this.shifts});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _SummaryCard(label: 'Turnos abiertos', value: shifts.where((s) => s.isOpen).length.toString(), icon: Icons.access_time, color: AppColors.warning)),
          const SizedBox(width: 12),
          Expanded(child: _SummaryCard(label: 'Cierres hoy', value: '${shifts.length}', icon: Icons.check_circle, color: AppColors.success)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ShiftCard extends StatelessWidget {
  final Shift shift;

  const _ShiftCard({required this.shift});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: shift.isOpen ? AppColors.warning : AppColors.success,
          child: Text(shift.isOpen ? 'ABI' : 'CIE', style: const TextStyle(color: Colors.white, fontSize: 11)),
        ),
        title: Text(shift.isOpen ? 'Turno abierto' : 'Turno cerrado'),
        subtitle: Text(
          '${shift.openedAt != null ? _formatDate(shift.openedAt) : ''}${shift.isOpen ? '' : ' - ${_formatDate(shift.closedAt)}'}',
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('\$${shift.totalSales.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Efectivo: \$${shift.cashSales.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        onTap: () => _showShiftDetail(context, shift),
      ),
    );
  }

  void _showShiftDetail(BuildContext context, Shift shift) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Detalle del turno', style: Theme.of(context).textTheme.titleLarge),
              const Divider(),
              _detailRow('Fondo inicial', '\$${(shift.openingCash).toStringAsFixed(2)}'),
              _detailRow('Ventas totales', '\$${(shift.totalSales).toStringAsFixed(2)}'),
              _detailRow('Ventas en efectivo', '\$${(shift.cashSales).toStringAsFixed(2)}'),
              _detailRow('Ventas con tarjeta', '\$${(shift.cardSales).toStringAsFixed(2)}'),
              _detailRow('Reembolsos', '-\$${(shift.cashRefunds).toStringAsFixed(2)}'),
              _detailRow('Depositos', '\$${(shift.depositsTotal).toStringAsFixed(2)}'),
              _detailRow('Pagos', '-\$${(shift.payoutsTotal).toStringAsFixed(2)}'),
              const Divider(),
              _detailRow('Efectivo esperado', '\$${(shift.expectedCash).toStringAsFixed(2)}'),
              _detailRow('Efectivo contado', '\$${(shift.closingCash ?? 0).toStringAsFixed(2)}'),
              _detailRow(
                'Diferencia',
                '\$${(shift.cashDifference).toStringAsFixed(2)}',
                valueStyle: TextStyle(
                  color: shift.cashDifference >= 0 ? AppColors.success : AppColors.danger,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (shift.chickensReceived > 0 || shift.chickensButchered > 0) ...[
                const Divider(),
                Text('Inventario', style: Theme.of(context).textTheme.titleMedium),
                if (shift.chickensReceived > 0) _detailRow('Pollos recibidos', '${shift.chickensReceived} (${shift.kgReceived.toStringAsFixed(2)} kg)'),
                if (shift.chickensButchered > 0) _detailRow('Pollos destazados', '${shift.chickensButchered} (${shift.kgButchered.toStringAsFixed(2)} kg)'),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Pendiente';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _detailRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}









