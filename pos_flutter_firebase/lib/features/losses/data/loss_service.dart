import '../../../shared/models/product.dart';
import '../../../shared/models/product_stock.dart';
import '../../inventory/domain/inventory_repository.dart';
import '../../inventory/domain/stock_repository.dart';
import '../domain/loss_repository.dart';

class LossService implements LossRepository {
  LossService({
    required InventoryRepository inventoryRepository,
    required StockRepository stockRepository,
  })  : _inventoryRepository = inventoryRepository,
        _stockRepository = stockRepository;

  final InventoryRepository _inventoryRepository;
  final StockRepository _stockRepository;

  @override
  Future<void> registerLoss({
    required String businessId,
    required String storeId,
    required Product product,
    required double quantity,
    required String reason,
    required String employeeId,
  }) async {
    if (quantity <= 0) {
      throw StateError('La cantidad debe ser mayor a cero');
    }

    final stock = await _stockRepository.getStoreProductStock(
      businessId: businessId,
      storeId: storeId,
      productId: product.id,
    );
    final currentStock = stock?.stockQuantity ?? 0.0;

    if (quantity > currentStock) {
      throw StateError(
        'No hay suficiente stock de ${product.name}: disponible $currentStock, requerido $quantity',
      );
    }

    final newQuantity = currentStock - quantity;

    await _inventoryRepository.adjustStock(
      businessId: businessId,
      storeId: storeId,
      product: product,
      newQuantity: newQuantity,
      reason: reason,
      employeeId: employeeId,
      type: 'loss',
    );
  }
}
