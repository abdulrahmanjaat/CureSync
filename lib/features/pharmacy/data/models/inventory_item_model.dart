import 'package:cloud_firestore/cloud_firestore.dart';

enum StockStatus { inStock, lowStock, outOfStock }

extension StockStatusX on StockStatus {
  String get label => switch (this) {
        StockStatus.inStock    => 'In Stock',
        StockStatus.lowStock   => 'Low Stock',
        StockStatus.outOfStock => 'Out of Stock',
      };
  String get value => switch (this) {
        StockStatus.inStock    => 'in_stock',
        StockStatus.lowStock   => 'low_stock',
        StockStatus.outOfStock => 'out_of_stock',
      };
  static StockStatus fromQuantity(int qty, int threshold) {
    if (qty <= 0) return StockStatus.outOfStock;
    if (qty <= threshold) return StockStatus.lowStock;
    return StockStatus.inStock;
  }
}

class InventoryItemModel {
  final String? id;
  final String pharmacyId;
  final String name;
  final String category;
  final String unit;       // e.g. 'tablets', 'ml', 'units'
  final String dosageForm; // e.g. 'Tablet', 'Capsule', 'Syrup'
  final double price;
  final int quantity;
  final int lowStockThreshold;
  final String? manufacturer;
  final DateTime? expiryDate;
  final DateTime updatedAt;

  const InventoryItemModel({
    this.id,
    required this.pharmacyId,
    required this.name,
    required this.category,
    required this.unit,
    required this.dosageForm,
    required this.price,
    required this.quantity,
    required this.lowStockThreshold,
    this.manufacturer,
    this.expiryDate,
    required this.updatedAt,
  });

  StockStatus get stockStatus =>
      StockStatusX.fromQuantity(quantity, lowStockThreshold);

  factory InventoryItemModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return InventoryItemModel(
      id:                 doc.id,
      pharmacyId:         d['pharmacyId']         as String? ?? '',
      name:               d['name']               as String? ?? '',
      category:           d['category']           as String? ?? 'General',
      unit:               d['unit']               as String? ?? 'units',
      dosageForm:         d['dosageForm']         as String? ?? 'Tablet',
      price:              (d['price']             as num?)?.toDouble() ?? 0,
      quantity:           (d['quantity']          as num?)?.toInt() ?? 0,
      lowStockThreshold:  (d['lowStockThreshold'] as num?)?.toInt() ?? 10,
      manufacturer:       d['manufacturer']       as String?,
      expiryDate:         (d['expiryDate']        as Timestamp?)?.toDate(),
      updatedAt:          (d['updatedAt']         as Timestamp?)?.toDate() ??
                          DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'pharmacyId':        pharmacyId,
        'name':              name,
        'category':          category,
        'unit':              unit,
        'dosageForm':        dosageForm,
        'price':             price,
        'quantity':          quantity,
        'lowStockThreshold': lowStockThreshold,
        if (manufacturer != null) 'manufacturer': manufacturer,
        if (expiryDate != null)
          'expiryDate': Timestamp.fromDate(expiryDate!),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
