import '../../../shared/models/product.dart';

abstract class LossRepository {
  Future<void> registerLoss({
    required String businessId,
    required String storeId,
    required Product product,
    required double quantity,
    required String reason,
    required String employeeId,
  });
}
