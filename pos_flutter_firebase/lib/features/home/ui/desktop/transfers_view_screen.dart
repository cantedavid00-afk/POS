import 'package:flutter/material.dart';
import '../../../../shared/models/employee.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../shared/extensions/string_x.dart';
import '../../../../shared/widgets/bottom_padding.dart';

class TransfersViewScreen extends StatelessWidget {
  const TransfersViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Traspasos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => _showSendTransfer(context),
            tooltip: 'Enviar traspaso',
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(20).copyWith(
          bottom: BottomPadding.of(context, minimum: 20),
        ),
        children: [
          _TransferSection(
            title: 'Traspaos enviados',
            icon: Icons.arrow_upward,
            color: AppColors.accent,
            items: const [
              _TransferItem(
                id: 'T1',
                fromStore: 'Principal',
                toStore: 'Sucursal Norte',
                products: 3,
                weight: '15.5 kg',
                date: '01/01/2025',
                status: 'Enviado',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _TransferSection(
            title: 'Traspasos recibidos',
            icon: Icons.arrow_downward,
            color: AppColors.success,
            items: const [
              _TransferItem(
                id: 'T2',
                fromStore: 'Sucursal Norte',
                toStore: 'Principal',
                products: 5,
                weight: '25.0 kg',
                date: '31/12/2024',
                status: 'Confirmado',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSendTransfer(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar traspaso'),
        content: const Text('Funcionalidad de envio de traspaso.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Enviar')),
        ],
      ),
    );
  }
}

class _TransferSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<_TransferItem> items;

  const _TransferSection({required this.title, required this.icon, required this.color, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Card(
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  title: Text('${item.fromStore.orPlaceholder()} \u2192 ${item.toStore.orPlaceholder()}'),
                  subtitle: Text('${item.products} productos \u00b7 ${item.weight.orPlaceholder()} \u00b7 ${item.date.orPlaceholder()}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.status == 'Confirmado' ? AppColors.success.withValues(alpha: 0.1) : AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.status,
                      style: TextStyle(
                        color: item.status == 'Confirmado' ? AppColors.success : AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferItem {
  final String id;
  final String fromStore;
  final String toStore;
  final int products;
  final String weight;
  final String date;
  final String status;

  const _TransferItem({required this.id, required this.fromStore, required this.toStore, required this.products, required this.weight, required this.date, required this.status});
}









