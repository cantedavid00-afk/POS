import '../../../shared/models/product_stock.dart';

abstract class StockRepository {
  Stream<Map<String, ProductStock>> watchStockByStore({
    required String businessId,
    required String storeId,
  });

  Map<String, ProductStock>? getCachedStock(String businessId);

  /// Lee una sola vez el stock/precio de un producto en una sucursal.
  Future<ProductStock?> getStoreProductStock({
    required String businessId,
    required String storeId,
    required String productId,
  });

  Future<void> applyLocalStockDelta({
    required String businessId,
    required String productId,
    required double delta,
  });

  /// Define el precio específico de un producto en una sucursal. Con [price]
  /// null se elimina la sobrescritura y vuelve a usarse el precio global.
  Future<void> setStorePrice({
    required String businessId,
    required String storeId,
    required String productId,
    required double? price,
  });
}
