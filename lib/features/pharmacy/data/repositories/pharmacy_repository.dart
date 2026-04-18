import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/prescription_order_model.dart';
import '../models/inventory_item_model.dart';

class PharmacyRepository {
  final _db = FirebaseFirestore.instance;

  // ── Orders ─────────────────────────────────────────────────────────────────

  Stream<List<PrescriptionOrderModel>> ordersStream(String pharmacyId) {
    return _db
        .collection('pharmacy_orders')
        .where('pharmacyId', isEqualTo: pharmacyId)
        .orderBy('receivedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(PrescriptionOrderModel.fromFirestore).toList());
  }

  Stream<List<PrescriptionOrderModel>> pendingOrdersStream(String pharmacyId) {
    return _db
        .collection('pharmacy_orders')
        .where('pharmacyId', isEqualTo: pharmacyId)
        .where('status', whereIn: ['pending', 'processing'])
        .orderBy('receivedAt')
        .snapshots()
        .map((s) => s.docs.map(PrescriptionOrderModel.fromFirestore).toList());
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final data = <String, dynamic>{'status': status.value};
    if (status == OrderStatus.dispensed) {
      data['dispensedAt'] = FieldValue.serverTimestamp();
    }
    await _db.collection('pharmacy_orders').doc(orderId).update(data);
  }

  Future<String> createOrder(PrescriptionOrderModel order) async {
    final ref = await _db.collection('pharmacy_orders').add(order.toFirestore());
    return ref.id;
  }

  // ── Inventory ───────────────────────────────────────────────────────────────

  Stream<List<InventoryItemModel>> inventoryStream(String pharmacyId) {
    return _db
        .collection('pharmacy_inventory')
        .where('pharmacyId', isEqualTo: pharmacyId)
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map(InventoryItemModel.fromFirestore).toList());
  }

  Stream<List<InventoryItemModel>> lowStockStream(String pharmacyId) {
    return inventoryStream(pharmacyId)
        .map((items) => items
            .where((i) => i.stockStatus != StockStatus.inStock)
            .toList());
  }

  Future<String> addInventoryItem(InventoryItemModel item) async {
    final ref =
        await _db.collection('pharmacy_inventory').add(item.toFirestore());
    return ref.id;
  }

  Future<void> updateStock(String itemId, int newQuantity) async {
    await _db.collection('pharmacy_inventory').doc(itemId).update({
      'quantity': newQuantity,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteInventoryItem(String itemId) async {
    await _db.collection('pharmacy_inventory').doc(itemId).delete();
  }
}

final _repo = PharmacyRepository();
PharmacyRepository get pharmacyRepository => _repo;
