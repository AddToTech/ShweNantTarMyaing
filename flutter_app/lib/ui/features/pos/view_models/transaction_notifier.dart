import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/receipt_printer_service.dart';
import '../../../../data/mock/mock_products.dart';
import '../../../../data/repositories/sale_repository.dart';
import '../../../../domain/models/sale_transaction.dart';
import '../../auth/view_models/auth_notifier.dart';
import '../../inventory/view_models/inventory_notifier.dart';
import '../../orders/view_models/order_history_notifier.dart';
import 'cart_notifier.dart';

/// State for transactions and hardware printer settings
class TransactionState {
  const TransactionState({
    this.transactions = const [],
    this.latestTransaction,
    this.printerSettings = const PrinterSettings(),
    this.isPrinting = false,
    this.lastPrintResult,
  });

  final List<SaleTransaction> transactions;
  final SaleTransaction? latestTransaction;
  final PrinterSettings printerSettings;
  final bool isPrinting;
  final PrintResult? lastPrintResult;

  TransactionState copyWith({
    List<SaleTransaction>? transactions,
    SaleTransaction? latestTransaction,
    PrinterSettings? printerSettings,
    bool? isPrinting,
    PrintResult? lastPrintResult,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      latestTransaction: latestTransaction ?? this.latestTransaction,
      printerSettings: printerSettings ?? this.printerSettings,
      isPrinting: isPrinting ?? this.isPrinting,
      lastPrintResult: lastPrintResult ?? this.lastPrintResult,
    );
  }
}

class TransactionNotifier extends Notifier<TransactionState> {
  final _printerService = const ReceiptPrinterService();

  @override
  TransactionState build() => const TransactionState();

  void updatePrinterSettings(PrinterSettings settings) {
    state = state.copyWith(printerSettings: settings);
  }

  void clearLocalTransactions() {
    state = state.copyWith(transactions: const []);
  }

  /// Complete a checkout: sends sale to backend API, deducts stock, and records sale.
  /// Returns null if the backend API request fails.
  Future<SaleTransaction?> completeSale({
    required CartState cart,
    required String branchId,
    required PaymentMethodType paymentMethod,
    double tenderedAmount = 0.0,
    double changeAmount = 0.0,
    String? referenceId,
    String? customerName,
    String? customerPhone,
    String? notes,
  }) async {
    final branchName = kBranches[branchId] ?? 'SitePyoe Main Branch';
    final currentUser = ref.read(authProvider).currentUser;
    final cashierName = currentUser?.name ?? 'Cashier #1';
    final cashierId = currentUser?.id;

    final saleItems = cart.items.map((cartItem) {
      return SaleTransactionItem(
        productId: cartItem.product.id,
        productName: cartItem.product.name,
        quantity: cartItem.quantity,
        unitPrice: cartItem.unitPrice,
        unitCost: cartItem.product.costPrice,
        discountPercent: cartItem.discountPct,
        lineTotal: cartItem.lineTotal,
        originType: cartItem.product.originType,
        category: cartItem.product.category,
      );
    }).toList();

    try {
      final serverSale = await ref.read(saleRepositoryProvider).createSale(
        branchId: branchId,
        branchName: branchName,
        cashierId: cashierId,
        cashierName: cashierName,
        customerName: customerName,
        customerPhone: customerPhone,
        items: saleItems,
        subtotal: cart.subtotal,
        discountAmount: cart.orderDiscountAmount,
        paymentMethod: paymentMethod,
        tenderedAmount: tenderedAmount,
        changeAmount: changeAmount,
        notes: notes,
      );

      // Deduct sold items from branch inventory
      for (final item in cart.items) {
        ref.read(inventoryProvider.notifier).deductStock(branchId, item.product.id, item.quantity);
      }

      state = state.copyWith(
        transactions: [serverSale, ...state.transactions],
        latestTransaction: serverSale,
      );
      ref.invalidate(remoteSalesProvider);
      return serverSale;
    } catch (_) {
      return null;
    }
  }

  /// Print receipt over network ESC/POS thermal printer
  Future<PrintResult> printReceipt({
    required SaleTransaction transaction,
    PrinterSettings? overrideSettings,
  }) async {
    final settings = overrideSettings ?? state.printerSettings;
    state = state.copyWith(isPrinting: true);

    try {
      final bytes = await _printerService.generateReceiptBytes(
        transaction: transaction,
        settings: settings,
      );

      final result = await _printerService.printOverNetwork(
        bytes: bytes,
        host: settings.networkIp,
        port: settings.networkPort,
      );

      state = state.copyWith(isPrinting: false, lastPrintResult: result);
      return result;
    } catch (e) {
      final errorResult = PrintResult(
        success: false,
        message: 'Printing error: $e',
      );
      state = state.copyWith(isPrinting: false, lastPrintResult: errorResult);
      return errorResult;
    }
  }

  /// Void/delete a sale order: calls backend DELETE /sales/:id, restores inventory stock,
  /// and updates local state & refreshes remote sales provider.
  Future<bool> deleteTransaction(String receiptNo) async {
    try {
      final repo = ref.read(saleRepositoryProvider);
      await repo.deleteSale(receiptNo);

      // Remove from local transactions if present
      final updatedList = state.transactions.where((t) => t.receiptNo != receiptNo).toList();
      state = state.copyWith(
        transactions: updatedList,
        latestTransaction: state.latestTransaction?.receiptNo == receiptNo ? null : state.latestTransaction,
      );

      // Refresh remote sales provider
      ref.invalidate(remoteSalesProvider);
      // Refresh inventory provider so updated stock is reflected
      ref.read(inventoryProvider.notifier).loadAllBranchStocks();

      return true;
    } catch (e) {
      rethrow;
    }
  }
}

final transactionProvider =
    NotifierProvider<TransactionNotifier, TransactionState>(
        TransactionNotifier.new);
