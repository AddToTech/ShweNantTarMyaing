import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/mock/mock_products.dart';
import '../../../../data/repositories/transfer_repository.dart';
import '../../inventory/view_models/inventory_notifier.dart';

enum TransferVoucherStatus {
  inTransit,
  received,
  cancelled,
}

extension TransferVoucherStatusX on TransferVoucherStatus {
  String get label => switch (this) {
        TransferVoucherStatus.inTransit => 'In-Transit',
        TransferVoucherStatus.received => 'Received',
        TransferVoucherStatus.cancelled => 'Cancelled',
      };

  String get burmeseLabel => switch (this) {
        TransferVoucherStatus.inTransit => 'လမ်းခရီးတွင်ရှိဆဲ',
        TransferVoucherStatus.received => 'လက်ခံရရှိပြီး',
        TransferVoucherStatus.cancelled => 'ပယ်ဖျက်ပြီး',
      };
}

class TransferItemRecord {
  const TransferItemRecord({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitCost,
    required this.category,
    this.originType,
  });

  final String productId;
  final String productName;
  final int quantity;
  final double unitCost;
  final ProductCategory category;
  final OriginType? originType;

  double get lineTotalCost => quantity * unitCost;
}

class TransferVoucher {
  const TransferVoucher({
    required this.id,
    required this.fromBranchId,
    required this.fromBranchName,
    required this.toBranchId,
    required this.toBranchName,
    required this.items,
    required this.status,
    this.notes,
    required this.createdAt,
    this.receivedAt,
  });

  final String id;
  final String fromBranchId;
  final String fromBranchName;
  final String toBranchId;
  final String toBranchName;
  final List<TransferItemRecord> items;
  final TransferVoucherStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? receivedAt;

  int get totalQuantity => items.fold(0, (sum, i) => sum + i.quantity);
  double get totalValue => items.fold(0.0, (sum, i) => sum + i.lineTotalCost);

  TransferVoucher copyWith({
    TransferVoucherStatus? status,
    DateTime? receivedAt,
  }) {
    return TransferVoucher(
      id: id,
      fromBranchId: fromBranchId,
      fromBranchName: fromBranchName,
      toBranchId: toBranchId,
      toBranchName: toBranchName,
      items: items,
      status: status ?? this.status,
      notes: notes,
      createdAt: createdAt,
      receivedAt: receivedAt ?? this.receivedAt,
    );
  }
}

class TransferState {
  const TransferState({
    this.vouchers = const [],
    this.selectedStatusFilter,
    this.selectedBranchFilter = 'all',
    this.isLoading = true,
  });

  final List<TransferVoucher> vouchers;
  final TransferVoucherStatus? selectedStatusFilter;
  final String selectedBranchFilter;
  final bool isLoading;

  List<TransferVoucher> get filteredVouchers {
    return vouchers.where((v) {
      if (selectedStatusFilter != null && v.status != selectedStatusFilter) {
        return false;
      }
      if (selectedBranchFilter != 'all') {
        final matches = v.fromBranchId == selectedBranchFilter ||
            v.toBranchId == selectedBranchFilter;
        if (!matches) return false;
      }
      return true;
    }).toList();
  }

  TransferState copyWith({
    List<TransferVoucher>? vouchers,
    TransferVoucherStatus? selectedStatusFilter,
    bool clearStatusFilter = false,
    String? selectedBranchFilter,
    bool? isLoading,
  }) {
    return TransferState(
      vouchers: vouchers ?? this.vouchers,
      selectedStatusFilter: clearStatusFilter
          ? null
          : (selectedStatusFilter ?? this.selectedStatusFilter),
      selectedBranchFilter: selectedBranchFilter ?? this.selectedBranchFilter,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class TransferNotifier extends Notifier<TransferState> {
  @override
  TransferState build() {
    _loadFromRemote();
    return const TransferState(vouchers: [], isLoading: true);
  }

  Future<void> loadTransfers() => _loadFromRemote();

  Future<void> _loadFromRemote() async {
    state = state.copyWith(isLoading: true);
    try {
      final remote = await ref.read(transferRepositoryProvider).getTransfers();
      state = state.copyWith(vouchers: remote, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setStatusFilter(TransferVoucherStatus? status) {
    state = state.copyWith(
      selectedStatusFilter: status,
      clearStatusFilter: status == null,
    );
  }

  void setBranchFilter(String branchId) {
    state = state.copyWith(selectedBranchFilter: branchId);
  }

  /// Create and dispatch a new inter-branch transfer.
  /// Automatically deducts inventory from source branch only if backend API succeeds.
  Future<bool> createTransfer({
    required String fromBranchId,
    required String toBranchId,
    required List<TransferItemRecord> items,
    String? notes,
  }) async {
    if (fromBranchId == toBranchId) return false;
    if (items.isEmpty) return false;

    final inv = ref.read(inventoryProvider.notifier);

    // 1. Validate source stock for all items first
    for (final item in items) {
      final currentStock = ref.read(inventoryProvider).getStock(fromBranchId, item.productId);
      if (item.quantity > currentStock) {
        return false; // Insufficient stock for this item
      }
    }

    try {
      final saved = await ref.read(transferRepositoryProvider).createTransfer(
        fromBranchId: fromBranchId,
        toBranchId: toBranchId,
        items: items,
        notes: notes,
      );

      // Deduct from source branch
      for (final item in items) {
        inv.deductStock(fromBranchId, item.productId, item.quantity);
      }

      state = state.copyWith(
        vouchers: [saved, ...state.vouchers],
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Receive an incoming transfer voucher at destination branch.
  /// Automatically increments stock at destination branch only if backend API succeeds.
  Future<bool> receiveTransfer(String voucherId) async {
    final idx = state.vouchers.indexWhere((v) => v.id == voucherId);
    if (idx < 0) return false;

    final voucher = state.vouchers[idx];
    if (voucher.status != TransferVoucherStatus.inTransit) {
      return false; // Only in-transit vouchers can be received
    }

    try {
      await ref.read(transferRepositoryProvider).receiveTransfer(voucherId);

      final inv = ref.read(inventoryProvider.notifier);
      for (final item in voucher.items) {
        inv.addStock(voucher.toBranchId, item.productId, item.quantity);
      }

      final updated = voucher.copyWith(
        status: TransferVoucherStatus.received,
        receivedAt: DateTime.now(),
      );

      final next = List<TransferVoucher>.from(state.vouchers);
      next[idx] = updated;
      state = state.copyWith(vouchers: next);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final transferProvider =
    NotifierProvider<TransferNotifier, TransferState>(TransferNotifier.new);
