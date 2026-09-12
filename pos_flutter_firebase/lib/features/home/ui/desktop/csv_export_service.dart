import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../../shared/models/sale.dart';

class CSVExportService {
  Future<String> exportSalesCSV({required String businessId, required List<Sale> sales}) async {
    final rows = <List<String>>[
      ['folio', 'tipo', 'estado', 'sucursal', 'empleado', 'fecha', 'metodo_pago', 'subtotal', 'descuento', 'total'],
    ];

    for (final sale in sales) {
      rows.add([
        sale.folio,
        sale.type ?? 'sale',
        sale.status ?? 'completed',
        sale.storeId,
        sale.employeeId,
        '${sale.clientCreatedAt?.toIso8601String() ?? sale.createdAt?.toIso8601String() ?? ""}',
        sale.paymentMethod ?? 'cash',
        (sale.subtotal).toStringAsFixed(2),
        (sale.discountTotal).toStringAsFixed(2),
        (sale.total).toStringAsFixed(2),
      ]);
    }

    final downloads = await getDownloadsDirectory();
    final dir = downloads ?? Directory('C:\\Users\\Alonso-Manuel\\Downloads');
    if (!await dir.exists()) await dir.create(recursive: true);

    final fileName = 'ventas_${businessId}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(rows.map(_csvRow).join('\n'));
    return file.path;
  }

  Future<String> exportInventoryCSV({required String businessId, required List<Map<String, dynamic>> products, required List<Map<String, dynamic>> stock}) async {
    final rows = <List<String>>[
      ['producto', 'categoria', 'stock', 'bajo_stock', 'precio', 'chickens'],
    ];

    for (final product in products) {
      final productId = product['id'] as String? ?? '';
      final stockEntry = stock.firstWhere((s) => s['productId'] == productId, orElse: () => {});
      rows.add([
        product['name'] as String? ?? '',
        product['categoryName'] as String? ?? '',
        (stockEntry['stockQuantity'] as num?)?.toStringAsFixed(2) ?? '0',
        (stockEntry['lowStockAlertQuantity'] as num?)?.toStringAsFixed(2) ?? '0',
        (product['price'] as num?)?.toStringAsFixed(2) ?? '0',
        (stockEntry['chickenCount'] as int?)?.toString() ?? '0',
      ]);
    }

    final downloads = await getDownloadsDirectory();
    final dir = downloads ?? Directory('C:\\Users\\Alonso-Manuel\\Downloads');
    if (!await dir.exists()) await dir.create(recursive: true);

    final fileName = 'inventario_${businessId}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(rows.map(_csvRow).join('\n'));
    return file.path;
  }

  String _csvRow(List<String> values) {
    return values.map((v) {
      final escaped = v.replaceAll('"', '""');
      return '"$escaped"';
    }).join(',');
  }
}





