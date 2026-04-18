import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/prescription_order_model.dart';
import '../../data/models/inventory_item_model.dart';
import '../../data/repositories/pharmacy_repository.dart';

// ── Current pharmacy UID ──────────────────────────────────────────────────────

final _pharmacyUidProvider = Provider<String>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid ?? '';
});

// ── Orders ────────────────────────────────────────────────────────────────────

final allOrdersProvider =
    StreamProvider<List<PrescriptionOrderModel>>((ref) {
  final uid = ref.watch(_pharmacyUidProvider);
  if (uid.isEmpty) return const Stream.empty();
  return pharmacyRepository.ordersStream(uid);
});

final pendingOrdersProvider =
    StreamProvider<List<PrescriptionOrderModel>>((ref) {
  final uid = ref.watch(_pharmacyUidProvider);
  if (uid.isEmpty) return const Stream.empty();
  return pharmacyRepository.pendingOrdersStream(uid);
});

// ── Inventory ─────────────────────────────────────────────────────────────────

final inventoryProvider =
    StreamProvider<List<InventoryItemModel>>((ref) {
  final uid = ref.watch(_pharmacyUidProvider);
  if (uid.isEmpty) return const Stream.empty();
  return pharmacyRepository.inventoryStream(uid);
});

final lowStockProvider =
    StreamProvider<List<InventoryItemModel>>((ref) {
  final uid = ref.watch(_pharmacyUidProvider);
  if (uid.isEmpty) return const Stream.empty();
  return pharmacyRepository.lowStockStream(uid);
});

// ── Stats ─────────────────────────────────────────────────────────────────────

class PharmacyStats {
  final int pendingOrders;
  final int dispensedToday;
  final int lowStockItems;
  final int totalInventory;

  const PharmacyStats({
    required this.pendingOrders,
    required this.dispensedToday,
    required this.lowStockItems,
    required this.totalInventory,
  });
}

final pharmacyStatsProvider = Provider<PharmacyStats>((ref) {
  final orders    = ref.watch(allOrdersProvider).valueOrNull ?? [];
  final inventory = ref.watch(inventoryProvider).valueOrNull ?? [];
  final lowStock  = ref.watch(lowStockProvider).valueOrNull ?? [];

  final now   = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final dispensedToday = orders
      .where((o) =>
          o.status == OrderStatus.dispensed &&
          o.dispensedAt != null &&
          !o.dispensedAt!.isBefore(today))
      .length;

  final pending = orders
      .where((o) =>
          o.status == OrderStatus.pending ||
          o.status == OrderStatus.processing)
      .length;

  return PharmacyStats(
    pendingOrders:  pending,
    dispensedToday: dispensedToday,
    lowStockItems:  lowStock.length,
    totalInventory: inventory.length,
  );
});

// ── Actions ───────────────────────────────────────────────────────────────────

Future<void> updateOrderStatus(String id, OrderStatus status) async {
  await pharmacyRepository.updateOrderStatus(id, status);
}

Future<void> updateStock(String itemId, int qty) async {
  await pharmacyRepository.updateStock(itemId, qty);
}

Future<String> addInventoryItem(InventoryItemModel item) async {
  return pharmacyRepository.addInventoryItem(item);
}
