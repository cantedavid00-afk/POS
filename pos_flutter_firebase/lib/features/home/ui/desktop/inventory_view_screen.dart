import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../shared/models/employee.dart';
import '../../../../shared/models/product.dart';
import '../../../../shared/models/product_stock.dart';
import '../../../../shared/models/store.dart';
import '../../../inventory/domain/inventory_repository.dart';
import '../../../products/domain/product_repository.dart';
import '../../../../shared/models/inventory_movement.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../shared/extensions/num_x.dart';
import '../../../../shared/extensions/string_x.dart';
import '../../../../shared/widgets/bottom_padding.dart';
import '../../../../shared/widgets/spring_sheet.dart';

class InventoryViewScreen extends StatefulWidget {
  final String businessId;
  final String selectedStoreId;
  final Employee currentEmployee;
  final List<Store> stores;

  const InventoryViewScreen({
    super.key,
    required this.businessId,
    required this.selectedStoreId,
    required this.currentEmployee,
    required this.stores,
  });

  @override
  State<InventoryViewScreen> createState() => _InventoryViewScreenState();
}

class _InventoryViewScreenState extends State<InventoryViewScreen> {
  String _searchQuery = '';
  bool _showLowStockOnly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
            tooltip: 'Buscar',
          ),
          IconButton(
            icon: Icon(Icons.tune),
            onPressed: () => setState(() => _showLowStockOnly = !_showLowStockOnly),
            tooltip: 'Solo alertas',
          ),
        ],
      ),
      body: StreamBuilder<List<Product>>(
        stream: FirebaseFirestore.instance
            .collection('businesses')
            .doc(widget.businessId)
            .collection('products')
            .snapshots()
            .map((s) => s.docs.map((d) => Product.fromDoc(d)).toList()),
        builder: (context, productsSnapshot) {
          if (productsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = productsSnapshot.data ?? const <Product>[];
          final filtered = products.where((p) {
            if (!p.trackStock) return false;
            if (_showLowStockOnly && p.stockQuantity > p.lowStockAlertQuantity) return false;
            if (_searchQuery.isNotEmpty && !p.name.toLowerCase().contains(_searchQuery.toLowerCase())) return false;
            return true;
          }).toList();

          final tracked = products.where((p) => p.trackStock).toList();
          final lowStock = tracked.where((p) => p.stockQuantity <= p.lowStockAlertQuantity).toList();

          return Column(
            children: [
              if (widget.selectedStoreId != null && lowStock.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: AppColors.danger.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: AppColors.danger),
                      const SizedBox(width: 8),
                      Text(
                        '${lowStock.length} productos con bajo stock',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.danger),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16).copyWith(
                    bottom: BottomPadding.of(context, minimum: 16),
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    return Card(
                      child: ListTile(
                        title: Text(product.name.orPlaceholder()),
                        subtitle: Text('${product.categoryName.orPlaceholder()} · Stock: ${product.stockQuantity.toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (product.stockQuantity <= product.lowStockAlertQuantity)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(4)),
                                child: const Text('BAJO', style: TextStyle(color: Colors.white, fontSize: 11)),
                              ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () => _showProductDetail(context, product),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAdjustDialog(context),
        icon: const Icon(Icons.edit),
        label: const Text('Ajustar'),
      ),
    );
  }

  void _showSearch(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buscar producto'),
        content: TextField(
          autofocus: true,
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: const InputDecoration(labelText: 'Nombre del producto', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  void _showProductDetail(BuildContext context, Product product) {
    showSpringBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.name.orPlaceholder(), style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              _detailRow('Categor\u00eda', product.categoryName ?? 'Sin categor\u00eda'),
              _detailRow('Precio', '\$${product.price.humanizedCount(decimalDigits: 2)}'),
              _detailRow('Costo', '\$${product.cost.humanizedCount(decimalDigits: 2)}'),
              _detailRow('Stock actual', product.stockQuantity.humanizedCount(decimalDigits: 2)),
              _detailRow('Alerta baja', product.lowStockAlertQuantity.humanizedCount(decimalDigits: 2)),
              _detailRow('Tipo', product.presentationType),
              _detailRow('Activo', product.active ? 'S\u00ed' : 'No'),
              if (product.chickenCount != null) _detailRow('Cantidad pollos', product.chickenCount!.toString()),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdjustDialog(BuildContext context) {
    final productController = TextEditingController();
    final storeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajustar stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: productController,
              decoration: const InputDecoration(labelText: 'Producto', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: storeController,
              decoration: const InputDecoration(labelText: 'Sucursal', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Guardar')),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontFeatures: [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}









