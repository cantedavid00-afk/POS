import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/offline/sync_queue.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../features/inventory/data/stock_service.dart';
import '../domain/transfer_repository.dart';
import '../domain/transfer.dart';
import '../domain/transfer_item.dart';

class TransferService implements TransferRepository {
  TransferService({
    FirebaseFirestore? firestore,
    ConnectivityService? connectivityService,
    StockService? stockService,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _connectivityService = connectivityService ?? ConnectivityService(),
        _stockService = stockService;

  final FirebaseFirestore _db;
  final ConnectivityService _connectivityService;
  final StockService? _stockService;

  @override
  Future<void> sendTransfer(String businessId, Transfer transfer) async {
    if (!await _connectivityService.hasConnection()) {
      await SyncQueue.enqueue(type: 'sendTransfer', data: {
        'businessId': businessId,
        ...transfer.toMap(),
      });
      return;
    }

    final ref = _db
        .collection('businesses')
        .doc(businessId)
        .collection('transfers')
        .doc();

    await ref.set({
      ...transfer.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> confirmTransfer(
    String businessId,
    String transferId,
    List<TransferItem> updatedItems,
    String toEmployeeId,
  ) async {
    if (!await _connectivityService.hasConnection()) {
      await SyncQueue.enqueue(type: 'confirmTransfer', data: {
        'businessId': businessId,
        'transferId': transferId,
        'updatedItems': updatedItems.map((e) => e.toMap()).toList(),
        'toEmployeeId': toEmployeeId,
      });
      // Delta local en la sucursal que recibe.
      for (final item in updatedItems) {
        final qty = item.confirmedQuantity;
        if (qty == null || qty <= 0) continue;
        await _stockService?.applyLocalStockDelta(
          businessId: businessId,
          productId: item.productId,
          delta: qty,
          chickenDelta: item.confirmedChickenCount,
        );
      }
      return;
    }

    final transferRef = _db
        .collection('businesses')
        .doc(businessId)
        .collection('transfers')
        .doc(transferId);

    final filteredItems = updatedItems
        .where((i) => i.confirmedQuantity != null && i.confirmedQuantity! > 0)
        .toList();

    if (filteredItems.isEmpty) {
      await transferRef.update({'status': 'cancelled'});
      return;
    }

    final movementsRef = _db
        .collection('businesses')
        .doc(businessId)
        .collection('inventoryMovements');

    await _db.runTransaction((transaction) async {
      final transferSnap = await transaction.get(transferRef);
      if (!transferSnap.exists) return;
      final transferData = transferSnap.data() as Map<String, dynamic>;

      final fromStoreId = transferData['fromStoreId'] as String;
      final toStoreId = transferData['toStoreId'] as String;
      final fromStoreName = transferData['fromStoreName'] as String? ?? '';
      final toStoreName = transferData['toStoreName'] as String? ?? '';
      final fromEmployeeId = transferData['fromEmployeeId'] as String? ?? '';

      final stockSnapshots = <String, double>{};
      final chickenSnapshots = <String, int>{};
      for (final item in filteredItems) {
        final fromStockRef = _db
            .collection('businesses')
            .doc(businessId)
            .collection('products')
            .doc(item.productId)
            .collection('stockByStore')
            .doc(fromStoreId);
        final fromDoc = await transaction.get(fromStockRef);
        final fromData = fromDoc.data() as Map<String, dynamic>?;
        stockSnapshots['from_${item.productId}'] =
            (fromData?['stockQuantity'] as num?)?.toDouble() ?? 0;
        chickenSnapshots['from_${item.productId}'] =
            (fromData?['chickenCount'] as num?)?.toInt() ?? 0;

        final toStockRef = _db
            .collection('businesses')
            .doc(businessId)
            .collection('products')
            .doc(item.productId)
            .collection('stockByStore')
            .doc(toStoreId);
        final toDoc = await transaction.get(toStockRef);
        final toData = toDoc.data() as Map<String, dynamic>?;
        stockSnapshots['to_${item.productId}'] =
            (toData?['stockQuantity'] as num?)?.toDouble() ?? 0;
        chickenSnapshots['to_${item.productId}'] =
            (toData?['chickenCount'] as num?)?.toInt() ?? 0;
      }

      for (final item in filteredItems) {
        final qty = item.confirmedQuantity!;
        final sentChickens = item.sentChickenCount ?? 0;
        final confirmedChickens = item.confirmedChickenCount;

        final fromStockRef = _db
            .collection('businesses')
            .doc(businessId)
            .collection('products')
            .doc(item.productId)
            .collection('stockByStore')
            .doc(fromStoreId);

        final fromQty = stockSnapshots['from_${item.productId}'] ?? 0;
        final newFromQty = (fromQty - qty).clamp(0.0, double.infinity);
        final fromChickenCount = chickenSnapshots['from_${item.productId}'] ?? 0;
        final newFromChickenCount = (fromChickenCount - sentChickens).clamp(0, 999999);
        final fromUpdate = <String, dynamic>{
          'stockQuantity': newFromQty,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (sentChickens > 0) {
          fromUpdate['chickenCount'] = newFromChickenCount;
        }
        transaction.set(fromStockRef, fromUpdate, SetOptions(merge: true));

        final toStockRef = _db
            .collection('businesses')
            .doc(businessId)
            .collection('products')
            .doc(item.productId)
            .collection('stockByStore')
            .doc(toStoreId);

        final toQty = stockSnapshots['to_${item.productId}'] ?? 0;
        final newToQty = toQty + qty;
        final toChickenCount = chickenSnapshots['to_${item.productId}'] ?? 0;
        final newToChickenCount = confirmedChickens != null
            ? toChickenCount + confirmedChickens
            : toChickenCount;
        final toUpdate = <String, dynamic>{
          'businessId': businessId,
          'storeId': toStoreId,
          'productId': item.productId,
          'stockQuantity': newToQty,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (confirmedChickens != null) {
          toUpdate['chickenCount'] = newToChickenCount;
        }
        transaction.set(toStockRef, toUpdate, SetOptions(merge: true));

        transaction.set(movementsRef.doc(), {
          'businessId': businessId,
          'storeId': fromStoreId,
          'fromStoreId': fromStoreId,
          'toStoreId': toStoreId,
          'fromStoreName': fromStoreName,
          'toStoreName': toStoreName,
          'productId': item.productId,
          'productName': item.productName,
          'type': 'transfer',
          'previousQuantity': fromQty,
          'newQuantity': newFromQty,
          'difference': newFromQty - fromQty,
          'reason': 'Traspaso enviado',
          'employeeId': fromEmployeeId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        transaction.set(movementsRef.doc(), {
          'businessId': businessId,
          'storeId': toStoreId,
          'fromStoreId': fromStoreId,
          'toStoreId': toStoreId,
          'fromStoreName': fromStoreName,
          'toStoreName': toStoreName,
          'productId': item.productId,
          'productName': item.productName,
          'type': 'transfer',
          'previousQuantity': toQty,
          'newQuantity': newToQty,
          'difference': qty,
          'reason': 'Traspaso recibido',
          'employeeId': toEmployeeId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      transaction.update(transferRef, {
        'status': 'confirmed',
        'toEmployeeId': toEmployeeId,
        'confirmedAt': FieldValue.serverTimestamp(),
        'items': updatedItems.map((e) => e.toMap()).toList(),
      });
    });
  }

  @override
  Future<void> cancelTransfer(String businessId, String transferId) async {
    if (!await _connectivityService.hasConnection()) {
      await SyncQueue.enqueue(type: 'cancelTransfer', data: {
        'businessId': businessId,
        'transferId': transferId,
      });
      return;
    }

    await _db
        .collection('businesses')
        .doc(businessId)
        .collection('transfers')
        .doc(transferId)
        .update({'status': 'cancelled'});
  }

  @override
  Stream<List<Transfer>> watchSentTransfers(
    String businessId,
    String storeId,
  ) {
    return _db
        .collection('businesses')
        .doc(businessId)
        .collection('transfers')
        .where('fromStoreId', isEqualTo: storeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Transfer.fromMap(doc.id, doc.data())).toList());
  }

  @override
  Stream<List<Transfer>> watchReceivedTransfers(
    String businessId,
    String storeId,
  ) {
    return _db
        .collection('businesses')
        .doc(businessId)
        .collection('transfers')
        .where('toStoreId', isEqualTo: storeId)
        .where('status', whereIn: ['sent', 'confirmed'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Transfer.fromMap(doc.id, doc.data())).toList());
  }
}
