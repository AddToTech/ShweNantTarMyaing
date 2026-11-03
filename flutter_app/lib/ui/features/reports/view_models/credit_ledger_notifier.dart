import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../orders/view_models/order_history_notifier.dart';

class CreditLedgerEntry {
  const CreditLedgerEntry({
    required this.id,
    required this.voucherRef,
    required this.customerName,
    required this.customerPhone,
    required this.dateIncurred,
    required this.totalDebt,
    this.paidAmount = 0.0,
    this.isCleared = false,
    this.clearedAt,
    this.notes,
  });

  final String id;
  final String voucherRef;
  final String customerName;
  final String customerPhone;
  final DateTime dateIncurred;
  final double totalDebt;
  final double paidAmount;
  final bool isCleared;
  final DateTime? clearedAt;
  final String? notes;

  double get balanceOutstanding =>
      (totalDebt - paidAmount).clamp(0.0, double.infinity);

  bool get isPaid => isCleared || balanceOutstanding <= 0.001;

  CreditLedgerEntry copyWith({
    String? id,
    String? voucherRef,
    String? customerName,
    String? customerPhone,
    DateTime? dateIncurred,
    double? totalDebt,
    double? paidAmount,
    bool? isCleared,
    DateTime? clearedAt,
    String? notes,
  }) {
    return CreditLedgerEntry(
      id: id ?? this.id,
      voucherRef: voucherRef ?? this.voucherRef,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      dateIncurred: dateIncurred ?? this.dateIncurred,
      totalDebt: totalDebt ?? this.totalDebt,
      paidAmount: paidAmount ?? this.paidAmount,
      isCleared: isCleared ?? this.isCleared,
      clearedAt: clearedAt ?? this.clearedAt,
      notes: notes ?? this.notes,
    );
  }
}

enum CreditLedgerFilterStatus { all, unpaid, cleared }

class CreditLedgerState {
  const CreditLedgerState({
    this.entries = const [],
    this.statusFilter = CreditLedgerFilterStatus.all,
    this.searchQuery = '',
  });

  final List<CreditLedgerEntry> entries;
  final CreditLedgerFilterStatus statusFilter;
  final String searchQuery;

  List<CreditLedgerEntry> get filteredEntries {
    return entries.where((e) {
      if (statusFilter == CreditLedgerFilterStatus.unpaid && e.isPaid) {
        return false;
      }
      if (statusFilter == CreditLedgerFilterStatus.cleared && !e.isPaid) {
        return false;
      }
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matchName = e.customerName.toLowerCase().contains(q);
        final matchPhone = e.customerPhone.toLowerCase().contains(q);
        final matchVoucher = e.voucherRef.toLowerCase().contains(q);
        if (!matchName && !matchPhone && !matchVoucher) return false;
      }
      return true;
    }).toList();
  }

  double get totalDebtIncurred =>
      entries.fold(0.0, (acc, e) => acc + e.totalDebt);

  double get totalPaidReceived =>
      entries.fold(0.0, (acc, e) => acc + e.paidAmount);

  double get totalOutstandingDebt =>
      entries.where((e) => !e.isPaid).fold(0.0, (acc, e) => acc + e.balanceOutstanding);

  int get unpaidCount => entries.where((e) => !e.isPaid).length;
  int get clearedCount => entries.where((e) => e.isPaid).length;

  CreditLedgerState copyWith({
    List<CreditLedgerEntry>? entries,
    CreditLedgerFilterStatus? statusFilter,
    String? searchQuery,
  }) {
    return CreditLedgerState(
      entries: entries ?? this.entries,
      statusFilter: statusFilter ?? this.statusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class CreditLedgerNotifier extends Notifier<CreditLedgerState> {
  final Map<String, double> _paidOverrides = {};
  final Set<String> _clearedOverrides = {};

  @override
  CreditLedgerState build() {
    final allSales = ref.watch(allTransactionsProvider);
    final creditSales = allSales.where((s) => s.isCredit).toList();

    final entries = creditSales.map((sale) {
      final id = sale.receiptNo;
      final paid = _paidOverrides[id] ?? sale.tenderedAmount;
      final cleared = _clearedOverrides.contains(id) || paid >= sale.totalAmount;
      return CreditLedgerEntry(
        id: id,
        voucherRef: sale.receiptNo,
        customerName: (sale.customerName != null && sale.customerName!.trim().isNotEmpty)
            ? sale.customerName!
            : 'Customer (အကြွေးဝယ်သူ)',
        customerPhone: sale.customerPhone ?? '-',
        dateIncurred: sale.createdAt,
        totalDebt: sale.totalAmount,
        paidAmount: paid,
        isCleared: cleared,
        clearedAt: cleared ? sale.createdAt : null,
        notes: sale.notes ?? sale.items.map((i) => '${i.productName} (${i.quantity})').join(', '),
      );
    }).toList();

    return CreditLedgerState(entries: entries);
  }

  void setSearchQuery(String q) {
    state = state.copyWith(searchQuery: q);
  }

  void setStatusFilter(CreditLedgerFilterStatus filter) {
    state = state.copyWith(statusFilter: filter);
  }

  Future<bool> markAsPaid(String id) async {
    try {
      final client = ref.read(apiClientProvider);
      await client.patch('/sales/$id/pay', body: {
        'markAsPaid': true,
      });
      _clearedOverrides.add(id);
      final updated = state.entries.map((entry) {
        if (entry.id == id) {
          _paidOverrides[id] = entry.totalDebt;
          return entry.copyWith(
            paidAmount: entry.totalDebt,
            isCleared: true,
            clearedAt: DateTime.now(),
          );
        }
        return entry;
      }).toList();

      state = state.copyWith(entries: updated);
      final _ = ref.refresh(remoteSalesProvider);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> recordPayment(String id, double paymentAmount) async {
    try {
      final client = ref.read(apiClientProvider);
      await client.patch('/sales/$id/pay', body: {
        'paymentAmount': paymentAmount,
        'markAsPaid': false,
      });
      final updated = state.entries.map((entry) {
        if (entry.id == id) {
          final newPaid =
              (entry.paidAmount + paymentAmount).clamp(0.0, entry.totalDebt);
          final isCleared = newPaid >= entry.totalDebt;
          _paidOverrides[id] = newPaid;
          if (isCleared) _clearedOverrides.add(id);
          return entry.copyWith(
            paidAmount: newPaid,
            isCleared: isCleared,
            clearedAt: isCleared ? DateTime.now() : entry.clearedAt,
          );
        }
        return entry;
      }).toList();

      state = state.copyWith(entries: updated);
      final _ = ref.refresh(remoteSalesProvider);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final creditLedgerProvider =
    NotifierProvider<CreditLedgerNotifier, CreditLedgerState>(
        CreditLedgerNotifier.new);
