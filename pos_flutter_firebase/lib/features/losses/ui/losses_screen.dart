import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/employee.dart';
import '../../../shared/models/inventory_movement.dart';
import '../../../shared/models/product.dart';
import '../../../shared/models/product_stock.dart';
import '../../../shared/models/store.dart';
import '../../../features/inventory/domain/inventory_repository.dart';
import '../../../features/inventory/domain/stock_repository.dart';
import '../../../features/products/domain/product_repository.dart';
import '../domain/loss_repository.dart';

class LossesScreen extends StatefulWidget {
  final String businessId;
  final Store store;
  final Employee employee;

  const LossesScreen({
    super.key,
    required this.businessId,
    required this.store,
    required this.employee,
  });

  @override
  State<LossesScreen> createState() => _LossesScreenState();
}

class _LossesScreenState extends State<LossesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedProductIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lossService = context.read<LossRepository>();
    final productRepo = context.read<ProductRepository>();
    final stockRepo = context.read<StockRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pérdidas de mercancía'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Registrar pérdida'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRegisterTab(productRepo, stockRepo, lossService),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildRegisterTab(ProductRepository productRepo, StockRepository stockRepo, LossRepository lossService) {
    return StreamBuilder<List<Product>>(
      stream: productRepo.watchProducts(businessId: widget.businessId),
      builder: (context, productsSnapshot) {
        if (productsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final products = productsSnapshot.data ?? const <Product>[];
        final allProducts = products.where((p) => p.active).toList();

        return StreamBuilder<Map<String, ProductStock>>(
          stream: stockRepo.watchStockByStore(businessId: widget.businessId, storeId: widget.store.id),
          builder: (context, stockSnapshot) {
            final stockMap = stockSnapshot.data ?? const <String, ProductStock>{};
            return Column(
              children: [
                if (allProducts.isEmpty)
                  const Expanded(child: Center(child: Text('No hay productos activos'))),
                if (allProducts.isNotEmpty) ...[
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: allProducts.length,
                      itemBuilder: (context, index) {
                        final product = allProducts[index];
                        final isSelected = _selectedProductIndex == index;
                        final stockQty = stockMap[product.id]?.stockQuantity ?? 0.0;
                        final isWeight = product.sellBy == 'weight';
                        return Card(
                          color: isSelected ? Colors.blue.withValues(alpha: 0.1) : null,
                          child: ListTile(
                            title: Text(product.name),
                            subtitle: Text(
                                '${product.categoryName ?? 'Sin categoría'} · ${isWeight ? '${stockQty.toStringAsFixed(2)} kg' : '${stockQty.toStringAsFixed(0)} Pz'}'),
                            trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : const Icon(Icons.radio_button_unchecked),
                            onTap: () {
                              setState(() {
                                _selectedProductIndex = index;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  if (_selectedProductIndex >= 0 && _selectedProductIndex < allProducts.length)
                    _LossFormCard(
                      key: ValueKey(allProducts[_selectedProductIndex].id),
                      product: allProducts[_selectedProductIndex],
                      currentStock: stockMap[allProducts[_selectedProductIndex].id]?.stockQuantity ?? 0.0,
                      businessId: widget.businessId,
                      storeId: widget.store.id,
                      employeeId: widget.employee.id,
                      lossService: lossService,
                      onRegistered: () {
                        setState(() {
                          _selectedProductIndex = -1;
                        });
                      },
                    ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    final inventoryRepo = context.read<InventoryRepository>();
    final productRepo = context.read<ProductRepository>();
    return StreamBuilder<List<InventoryMovement>>(
      stream: inventoryRepo.watchMovements(businessId: widget.businessId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final movements = snapshot.data ?? const <InventoryMovement>[];
        final losses = movements
            .where((m) => m.type == 'loss' && m.storeId == widget.store.id)
            .toList();

        if (losses.isEmpty) {
          return const Center(child: Text('No hay pérdidas registradas.'));
        }

        return StreamBuilder<List<Product>>(
          stream: productRepo.watchProducts(businessId: widget.businessId),
          builder: (context, prodSnapshot) {
            final sellByMap = {for (final p in prodSnapshot.data ?? const <Product>[]) p.id: p.sellBy};
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: losses.length,
              itemBuilder: (context, index) {
                final movement = losses[index];
                final isWeight = sellByMap[movement.productId] == 'weight';
                final unit = isWeight ? 'kg' : 'Pz';
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.orange),
                    title: Text(movement.productName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Cantidad: ${movement.previousQuantity.toStringAsFixed(isWeight ? 2 : 0)} → ${movement.newQuantity.toStringAsFixed(isWeight ? 2 : 0)} $unit'),
                        Text('Motivo: ${movement.reason}'),
                        Text(_formatDate(movement.createdAt)),
                      ],
                    ),
                    trailing: Text('-${movement.difference.abs().toStringAsFixed(isWeight ? 2 : 0)} $unit'),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Fecha pendiente';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _LossFormCard extends StatefulWidget {
  const _LossFormCard({
    super.key,
    required this.product,
    required this.currentStock,
    required this.businessId,
    required this.storeId,
    required this.employeeId,
    required this.lossService,
    required this.onRegistered,
  });

  final Product product;
  final double currentStock;
  final String businessId;
  final String storeId;
  final String employeeId;
  final LossRepository lossService;
  final VoidCallback onRegistered;

  @override
  State<_LossFormCard> createState() => _LossFormCardState();
}

class _LossFormCardState extends State<_LossFormCard> {
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isRegistering = false;
  String? _errorMessage;

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  bool get _isWeight => widget.product.sellBy == 'weight';

  Future<void> _registerLoss() async {
    final input = double.tryParse(_quantityController.text.trim().replaceAll(',', '.'));
    if (input == null || input <= 0) {
      setState(() => _errorMessage = 'Ingresa una cantidad válida');
      return;
    }
    if (!_isWeight && input % 1 != 0) {
      setState(() => _errorMessage = 'Las piezas deben ser números enteros');
      return;
    }
    if (input > widget.currentStock) {
      setState(() => _errorMessage =
          'No hay suficiente stock. Disponible: ${widget.currentStock.toStringAsFixed(_isWeight ? 2 : 0)} ${_isWeight ? 'kg' : 'Pz'}');
      return;
    }
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _errorMessage = 'Ingresa un motivo');
      return;
    }
    setState(() {
      _isRegistering = true;
      _errorMessage = null;
    });
    try {
      await widget.lossService.registerLoss(
        businessId: widget.businessId,
        storeId: widget.storeId,
        product: widget.product,
        quantity: input,
        reason: reason,
        employeeId: widget.employeeId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Pérdida registrada: ${input.toStringAsFixed(_isWeight ? 2 : 0)} ${_isWeight ? 'kg' : 'Pz'} de ${widget.product.name}')),
      );
      widget.onRegistered();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRegistering = false;
        _errorMessage = e.toString();
      });
      return;
    }
    if (mounted) {
      setState(() => _isRegistering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 0,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.product.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Stock actual: ${widget.currentStock.toStringAsFixed(_isWeight ? 2 : 0)} ${_isWeight ? 'kg' : 'Pz'}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.numberWithOptions(decimal: _isWeight),
                decoration: InputDecoration(
                  labelText: _isWeight ? 'Kilos perdidos' : 'Piezas perdidas',
                  hintText: _isWeight ? 'Ej: 2.500' : 'Ej: 10',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Motivo',
                  hintText: 'Vencido, dañado, excedente, etc.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              if (_errorMessage != null) Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isRegistering ? null : _registerLoss,
                  icon: _isRegistering
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.delete_forever),
                  label: Text(_isRegistering ? 'Registrando...' : 'Registrar pérdida'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
