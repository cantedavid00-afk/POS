import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/employee.dart';
import '../../../shared/models/inventory_movement.dart';
import '../../../shared/models/product.dart';
import '../../../shared/models/product_stock.dart';
import '../../../shared/models/store.dart';
import '../../../shared/providers/app_session_notifier.dart';
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
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isRegistering = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quantityController.dispose();
    _reasonController.dispose();
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
                    return Card(
                      color: isSelected ? Colors.blue.withValues(alpha: 0.1) : null,
                      child: ListTile(
                        title: Text(product.name),
                        subtitle: Text('${product.categoryName ?? 'Sin categoría'} · ${product.sellBy == 'weight' ? '${product.stockQuantity.toStringAsFixed(2)} kg' : '${product.stockQuantity.toStringAsFixed(0)} u'}'),
                        trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : const Icon(Icons.radio_button_unchecked),
                        onTap: () {
                          setState(() {
                            _selectedProductIndex = index;
                            _errorMessage = null;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              if (_selectedProductIndex >= 0 && _selectedProductIndex < allProducts.length)
                _buildQuantityAndReasonSection(allProducts[_selectedProductIndex], lossService),
            ],
          ],
        );
      },
    );
  }

  Widget _buildQuantityAndReasonSection(Product product, LossRepository lossService) {
    final stock = context.read<StockRepository>();
    return StreamBuilder<ProductStock?>(
      stream: stock.watchStockByStore(businessId: widget.businessId, storeId: widget.store.id)
          .map((stockMap) => stockMap[product.id]),
      builder: (context, stockSnapshot) {
        final currentStock = stockSnapshot.data?.stockQuantity ?? 0.0;
        final isWeightProduct = product.sellBy == 'weight';

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stock actual: ${currentStock.toStringAsFixed(isWeightProduct ? 2 : 0)} ${isWeightProduct ? 'kg' : 'unidades'}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.numberWithOptions(decimal: isWeightProduct),
                    decoration: InputDecoration(
                      labelText: isWeightProduct ? 'Kilos perdidos' : 'Piezas perdidas',
                      hintText: isWeightProduct ? 'Ej: 2.500' : 'Ej: 10',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _errorMessage = null;
                      });
                    },
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
                  if (_errorMessage != null)
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isRegistering
                          ? null
                          : () => _registerLoss(product, currentStock, isWeightProduct, lossService),
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
      },
    );
  }

  Future<void> _registerLoss(Product product, double currentStock, bool isWeightProduct, LossRepository lossService) async {
    final input = double.tryParse(_quantityController.text.trim().replaceAll(',', '.'));
    if (input == null || input <= 0) {
      setState(() => _errorMessage = 'Ingresa una cantidad válida');
      return;
    }

    if (isWeightProduct && input != input.floor() && input % 1 != 0) {
      // Decimal kg is fine
    } else if (!isWeightProduct && input % 1 != 0) {
      setState(() => _errorMessage = 'Las piezas deben ser números enteros');
      return;
    }

    if (input > currentStock) {
      setState(() => _errorMessage = 'No hay suficiente stock. Disponible: $currentStock ${isWeightProduct ? 'kg' : 'unidades'}');
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
      await lossService.registerLoss(
        businessId: widget.businessId,
        storeId: widget.store.id,
        product: product,
        quantity: input,
        reason: reason,
        employeeId: widget.employee.id,
      );

      if (!mounted) return;
      _quantityController.clear();
      _reasonController.clear();
      setState(() {
        _selectedProductIndex = -1;
        _isRegistering = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pérdida registrada: ${input.toStringAsFixed(isWeightProduct ? 2 : 0)} ${isWeightProduct ? 'kg' : 'unidades'} de ${product.name}')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRegistering = false;
        _errorMessage = e.toString();
      });
    }
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<List<InventoryMovement>>(
      stream: FirebaseFirestore.instance
          .collection('businesses')
          .doc(widget.businessId)
          .collection('inventoryMovements')
          .where('storeId', isEqualTo: widget.store.id)
          .where('type', isEqualTo: 'loss')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((d) => InventoryMovement.fromMap(d.data(), d.id)).toList()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final movements = snapshot.data ?? const <InventoryMovement>[];
        final losses = movements.where((m) => m.type == 'loss').toList();

        if (losses.isEmpty) {
          return const Center(child: Text('No hay pérdidas registradas.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: losses.length,
          itemBuilder: (context, index) {
            final movement = losses[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.orange),
                title: Text(movement.productName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cantidad: ${movement.previousQuantity.toStringAsFixed(2)} → ${movement.newQuantity.toStringAsFixed(2)}'),
                    Text('Motivo: ${movement.reason}'),
                    Text('${_formatDate(movement.createdAt)}'),
                  ],
                ),
                trailing: Text('-\${(movement.difference.abs()).toStringAsFixed(2)}'),
              ),
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
