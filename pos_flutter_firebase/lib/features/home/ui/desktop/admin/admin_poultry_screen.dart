import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/models/employee.dart';
import '../../../../../shared/models/store.dart';
import '../../../../../shared/widgets/bottom_padding.dart';
import '../../../../poultry/domain/chicken_receiving.dart';
import '../../../../poultry/domain/poultry_repository.dart';
import 'admin_filters.dart';
import 'admin_theme_tokens.dart';
import 'widgets/admin_card.dart';
import 'widgets/admin_section_header.dart';
import 'widgets/admin_states.dart';
import 'widgets/admin_status_badge.dart';

/// Recibir pollo: captura primero, historial después.
/// En modo TODAS se exige elegir sucursal destino explícitamente:
/// nunca se selecciona la primera en silencio.
class AdminPoultryScreen extends StatefulWidget {
  const AdminPoultryScreen({
    super.key,
    required this.businessId,
    required this.stores,
    required this.employee,
  });

  final String businessId;
  final List<Store> stores;
  final Employee employee;

  @override
  State<AdminPoultryScreen> createState() => _AdminPoultryScreenState();
}

class _AdminPoultryScreenState extends State<AdminPoultryScreen> {
  final _countCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  String? _formStoreId;
  bool _saving = false;

  @override
  void dispose() {
    _countCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  double get _weight => double.tryParse(_weightCtrl.text.trim().replaceAll(',', '.')) ?? 0;
  int get _count => int.tryParse(_countCtrl.text.trim()) ?? 0;

  Future<void> _save(String storeId) async {
    if (_count <= 0 || _weight <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa cantidad y peso válidos (> 0)')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final receiving = ChickenReceiving(
        businessId: widget.businessId,
        storeId: storeId,
        employeeId: widget.employee.id,
        employeeName: widget.employee.name,
        createdAt: DateTime.now(),
        totalChickens: _count,
        totalWeightKg: _weight,
        avgWeightKg: _weight / _count,
      );
      await context.read<PoultryRepository>().saveReceiving(widget.businessId, receiving);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recepción guardada correctamente')),
      );
      _countCtrl.clear();
      _weightCtrl.clear();
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = context.watch<AdminScope>();
    // Destino explícito: sucursal del scope, o selección manual si es TODAS.
    final effectiveStoreId = scope.selectedStoreId ?? _formStoreId;

    return ListView(
      padding: EdgeInsets.all(24).copyWith(bottom: BottomPadding.of(context, minimum: 24)),
      children: [
        const AdminSectionHeader(title: 'Recibir pollo', subtitle: 'Registrar entrada de pollo'),
        const SizedBox(height: 12),
        AdminScopeBanner(
          isAllStores: scope.isAllStores,
          storeName: _name(scope.selectedStoreId ?? ''),
          rangeLabel: scope.range.label,
          activeStoreCount: widget.stores.where((s) => s.active).length,
        ),
        const SizedBox(height: 16),
        AdminCard(
          title: 'Nueva recepción',
          subtitle: effectiveStoreId == null
              ? 'Elige la sucursal destino'
              : 'Se guardará en ${_name(effectiveStoreId)}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (scope.isAllStores) ...[
                DropdownButtonFormField<String>(
                  initialValue: _formStoreId,
                  decoration: InputDecoration(
                    labelText: 'Sucursal destino',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminRadii.input)),
                  ),
                  items: [
                    for (final s in widget.stores)
                      DropdownMenuItem(value: s.id, child: Text(s.name.isEmpty ? '(Sin nombre)' : s.name)),
                  ],
                  onChanged: (v) => setState(() => _formStoreId = v),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Para registrar una recepción debes seleccionar una sucursal.',
                  style: AdminText.bodySmall,
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _countCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Cantidad de pollos',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminRadii.input)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _weightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) {
                        if (effectiveStoreId != null && !_saving) _save(effectiveStoreId);
                      },
                      decoration: InputDecoration(
                        labelText: 'Peso total (kg)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminRadii.input)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AdminColors.track,
                  borderRadius: BorderRadius.circular(AdminRadii.button),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.scale_outlined, size: 18, color: AdminColors.textSecondary),
                    const SizedBox(width: 8),
                    const Text('Peso promedio', style: AdminText.bodySmall),
                    const Spacer(),
                    Text(
                      _count > 0 ? '${(_weight / _count).toStringAsFixed(2)} kg' : '—',
                      style: AdminText.body.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: (effectiveStoreId == null || _saving) ? null : () => _save(effectiveStoreId),
                  icon: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Guardando...' : 'Registrar recepción'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AdminCard(
          title: 'Recepciones recientes',
          subtitle: scope.range.label,
          child: _PoultryHistory(
            businessId: widget.businessId,
            selectedStoreId: scope.selectedStoreId,
            range: scope.range,
            storeName: _name,
          ),
        ),
      ],
    );
  }

  String _name(String id) {
    for (final s in widget.stores) {
      if (s.id == id) return s.name.isEmpty ? '(Sin nombre)' : s.name;
    }
    return '';
  }
}

class _PoultryHistory extends StatelessWidget {
  const _PoultryHistory({
    required this.businessId,
    required this.selectedStoreId,
    required this.range,
    required this.storeName,
  });

  final String businessId;
  final String? selectedStoreId;
  final AdminDateRange range;
  final String Function(String) storeName;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId)
          .collection('poultryReceivings')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AdminSkeleton(lines: 4);
        }
        if (snapshot.hasError) {
          return AdminErrorState(
            message: 'No se pudo cargar el historial.',
            details: '${snapshot.error}',
            onRetry: () => context.read<AdminScope>().touch(),
          );
        }
        final now = DateTime.now();
        final resolved = range.resolve(now);
        final rows = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        for (final d in snapshot.data?.docs ?? const []) {
          final data = d.data();
          final ts = data['createdAt'];
          DateTime? date;
          if (ts is Timestamp) date = ts.toDate();
          if (date == null || date.isBefore(resolved.start) || date.isAfter(resolved.end)) continue;
          if (selectedStoreId != null && (data['storeId'] as String? ?? '') != selectedStoreId) continue;
          rows.add(d);
        }
        if (rows.isEmpty) {
          return const AdminEmptyState(
            icon: Icons.egg_alt_outlined,
            title: 'Sin recepciones en este periodo',
            hint: 'Prueba otro rango de fechas o selecciona otra sucursal.',
          );
        }
        return AdminTable(
          columns: const ['Recepción', 'Sucursal', 'Fecha'],
          flex: const [3, 2, 2],
          rows: [
            for (final d in rows)
              [
                Text(
                  '${((d.data()['chickenCount'] as num?) ?? (d.data()['totalChickens'] as num?) ?? 0).toInt()} pollos · ${((d.data()['totalWeightKg'] as num?) ?? 0).toStringAsFixed(2)} kg',
                  style: AdminText.body.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(storeName(d.data()['storeId'] as String? ?? ''), style: AdminText.body),
                Text(_fmt((d.data()['createdAt'] as Timestamp?)?.toDate()), style: AdminText.body),
              ],
          ],
        );
      },
    );
  }

  String _fmt(DateTime? date) {
    if (date == null) return '—';
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final hh = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$dd/$mm $hh:$min';
  }
}
