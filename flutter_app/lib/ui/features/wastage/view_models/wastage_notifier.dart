import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/mock/mock_products.dart';
import '../../../../data/repositories/branch_repository.dart';
import '../../../../data/repositories/wastage_repository.dart';
import '../../inventory/view_models/inventory_notifier.dart';

/// User-selectable wastage/damage reasons
enum WastageReasonOption {
  deadWithered,
  pestInfestation,
  brokenCracked,
  other,
}

extension WastageReasonX on WastageReasonOption {
  String get label => switch (this) {
        WastageReasonOption.deadWithered => 'Dead / Withered',
        WastageReasonOption.pestInfestation => 'Pest Infestation',
        WastageReasonOption.brokenCracked => 'Broken / Cracked',
        WastageReasonOption.other => 'Other',
      };

  String get burmeseLabel => switch (this) {
        WastageReasonOption.deadWithered => 'အပင်သေဆုံးခြင်း',
        WastageReasonOption.pestInfestation => 'ပိုးမွှားကျရောက်ခြင်း',
        WastageReasonOption.brokenCracked => 'ကွဲအက်ပျက်စီးခြင်း',
        WastageReasonOption.other => 'အခြား',
      };

  String get emoji => switch (this) {
        WastageReasonOption.deadWithered => '🥀',
        WastageReasonOption.pestInfestation => '🐛',
        WastageReasonOption.brokenCracked => '🏺',
        WastageReasonOption.other => '⚠️',
      };
}

/// An immutable recorded wastage log entry
class WastageEntry {
  const WastageEntry({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.productId,
    required this.productName,
    required this.category,
    this.originType,
    required this.quantity,
    required this.unitCost,
    required this.totalCostLoss,
    required this.reason,
    this.notes,
    required this.recordedAt,
  });

  final String id;
  final String branchId;
  final String branchName;
  final String productId;
  final String productName;
  final ProductCategory category;
  final OriginType? originType;
  final int quantity;
  final double unitCost;
  final double totalCostLoss; // quantity * unitCost
  final WastageReasonOption reason;
  final String? notes;
  final DateTime recordedAt;
}

class WastageState {
  const WastageState({
    this.entries = const [],
    this.selectedBranchFilter = 'all',
    this.selectedReasonFilter,
    this.searchQuery = '',
    this.isLoading = true,
  });

  final List<WastageEntry> entries;
  final String selectedBranchFilter;
  final WastageReasonOption? selectedReasonFilter;
  final String searchQuery;
  final bool isLoading;

  /// Total financial loss across all entries matching filter
  double get totalLoss => filteredEntries.fold(0.0, (sum, e) => sum + e.totalCostLoss);

  /// Total count of damaged/wasted items
  int get totalQuantity => filteredEntries.fold(0, (sum, e) => sum + e.quantity);

  List<WastageEntry> get filteredEntries {
    return entries.where((e) {
      if (selectedBranchFilter != 'all' && e.branchId != selectedBranchFilter) {
        return false;
      }
      if (selectedReasonFilter != null && e.reason != selectedReasonFilter) {
        return false;
      }
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final match = e.productName.toLowerCase().contains(q) ||
            e.id.toLowerCase().contains(q) ||
            (e.notes != null && e.notes!.toLowerCase().contains(q));
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  WastageState copyWith({
    List<WastageEntry>? entries,
    String? selectedBranchFilter,
    WastageReasonOption? selectedReasonFilter,
    bool clearReasonFilter = false,
    String? searchQuery,
    bool? isLoading,
  }) {
    return WastageState(
      entries: entries ?? this.entries,
      selectedBranchFilter: selectedBranchFilter ?? this.selectedBranchFilter,
      selectedReasonFilter: clearReasonFilter
          ? null
          : (selectedReasonFilter ?? this.selectedReasonFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class WastageNotifier extends Notifier<WastageState> {
  @override
  WastageState build() {
    _loadFromRemote();
    final defaultBranch = ref.watch(defaultBranchProvider);
    return WastageState(
      entries: [],
      isLoading: true,
      selectedBranchFilter: defaultBranch,
    );
  }

  Future<void> loadWastage() => _loadFromRemote();

  Future<void> _loadFromRemote() async {
    state = state.copyWith(isLoading: true);
    try {
      final remote = await ref.read(wastageRepositoryProvider).getWastageLogs();
      state = state.copyWith(entries: remote, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setBranchFilter(String branchId) {
    state = state.copyWith(selectedBranchFilter: branchId);
  }

  void setReasonFilter(WastageReasonOption? reason) {
    state = state.copyWith(
      selectedReasonFilter: reason,
      clearReasonFilter: reason == null,
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Records a new wastage log and automatically deducts stock from inventory.
  /// Returns true only if the backend API request succeeds.
  Future<bool> recordWastage({
    required String branchId,
    required MockProduct product,
    required int quantity,
    required WastageReasonOption reason,
    String? notes,
  }) async {
    if (quantity <= 0) return false;

    final currentStock = ref.read(inventoryProvider).getStock(branchId, product.id);
    if (quantity > currentStock) {
      return false; // Insufficient stock
    }

    final branchName = kBranches[branchId] ?? 'SitePyoe Branch';

    try {
      final saved = await ref.read(wastageRepositoryProvider).recordWastage(
        branchId: branchId,
        branchName: branchName,
        productId: product.id,
        productName: product.name,
        quantity: quantity.toDouble(),
        unitCost: product.costPrice,
        reason: reason,
        notes: notes,
      );

      ref.read(inventoryProvider.notifier).deductStock(branchId, product.id, quantity);
      state = state.copyWith(
        entries: [saved, ...state.entries],
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

final wastageProvider =
    NotifierProvider<WastageNotifier, WastageState>(WastageNotifier.new);
