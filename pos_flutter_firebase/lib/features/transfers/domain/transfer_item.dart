class TransferItem {
  final String productId;
  final String productName;
  final double sentQuantity;
  final double? confirmedQuantity;
  final int? sentChickenCount;
  final int? confirmedChickenCount;

  const TransferItem({
    required this.productId,
    required this.productName,
    required this.sentQuantity,
    this.confirmedQuantity,
    this.sentChickenCount,
    this.confirmedChickenCount,
  });

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'productName': productName,
    'sentQuantity': sentQuantity,
    if (confirmedQuantity != null) 'confirmedQuantity': confirmedQuantity,
    if (sentChickenCount != null) 'sentChickenCount': sentChickenCount,
    if (confirmedChickenCount != null) 'confirmedChickenCount': confirmedChickenCount,
  };

  factory TransferItem.fromMap(Map<String, dynamic> map) => TransferItem(
    productId: map['productId'] as String? ?? '',
    productName: map['productName'] as String? ?? '',
    sentQuantity: (map['sentQuantity'] as num?)?.toDouble() ?? 0,
    confirmedQuantity: (map['confirmedQuantity'] as num?)?.toDouble(),
    sentChickenCount: (map['sentChickenCount'] as num?)?.toInt(),
    confirmedChickenCount: (map['confirmedChickenCount'] as num?)?.toInt(),
  );
}
