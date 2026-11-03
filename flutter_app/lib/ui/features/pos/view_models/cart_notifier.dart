import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/mock/mock_products.dart';

// ============================================================
// Cart Domain Models
// ============================================================

class CartItem {
  const CartItem({
    required this.product,
    required this.quantity,
    this.discountPct = 0.0,
  });

  final MockProduct product;
  final int quantity;
  final double discountPct; // 0–100

  double get unitPrice => product.salePrice;
  double get lineTotal  => unitPrice * quantity * (1 - discountPct / 100);

  CartItem copyWith({int? quantity, double? discountPct}) => CartItem(
        product:     product,
        quantity:    quantity    ?? this.quantity,
        discountPct: discountPct ?? this.discountPct,
      );
}

// ============================================================
// Held Order Model
// ============================================================

class HeldOrder {
  const HeldOrder({
    required this.id,
    required this.ticketNumber,
    required this.items,
    this.orderDiscountAmount = 0.0,
    required this.heldAt,
    this.customerName,
    this.note,
  });

  final String id;
  final String ticketNumber;
  final List<CartItem> items;
  final double orderDiscountAmount;
  final DateTime heldAt;
  final String? customerName;
  final String? note;

  double get subtotal => items.fold(0.0, (s, i) => s + i.lineTotal);
  double get totalAmount =>
      (subtotal - orderDiscountAmount).clamp(0.0, double.infinity);
  int get itemCount => items.fold(0, (s, i) => s + i.quantity);

  HeldOrder copyWith({
    String? id,
    String? ticketNumber,
    List<CartItem>? items,
    double? orderDiscountAmount,
    DateTime? heldAt,
    String? customerName,
    String? note,
  }) {
    return HeldOrder(
      id: id ?? this.id,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      items: items ?? this.items,
      orderDiscountAmount: orderDiscountAmount ?? this.orderDiscountAmount,
      heldAt: heldAt ?? this.heldAt,
      customerName: customerName ?? this.customerName,
      note: note ?? this.note,
    );
  }
}

// ============================================================
// Cart State
// ============================================================

class CartState {
  const CartState({
    this.items                = const [],
    this.orderDiscountAmount  = 0.0,
    this.ticketNumber         = 'SP-001',
    this.heldOrders           = const [],
  });

  final List<CartItem> items;
  final double orderDiscountAmount;
  final String ticketNumber;
  final List<HeldOrder> heldOrders;

  double get subtotal    => items.fold(0.0, (s, i) => s + i.lineTotal);
  double get taxAmount   => 0.0; // Reserved — configure per business rules
  double get totalAmount =>
      (subtotal - orderDiscountAmount + taxAmount).clamp(0.0, double.infinity);

  int  get itemCount => items.fold(0, (s, i) => s + i.quantity);
  bool get isEmpty   => items.isEmpty;

  CartState copyWith({
    List<CartItem>? items,
    double?  orderDiscountAmount,
    String?  ticketNumber,
    List<HeldOrder>? heldOrders,
  }) =>
      CartState(
        items:               items               ?? this.items,
        orderDiscountAmount: orderDiscountAmount ?? this.orderDiscountAmount,
        ticketNumber:        ticketNumber        ?? this.ticketNumber,
        heldOrders:          heldOrders          ?? this.heldOrders,
      );
}

// ============================================================
// Cart Notifier (Riverpod 2.x)
// ============================================================

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  // ── Mutations ─────────────────────────────────────────────

  void addItem(MockProduct product) {
    final idx = _indexOf(product.id);
    if (idx >= 0) {
      _updateItem(idx, (item) => item.copyWith(quantity: item.quantity + 1));
    } else {
      state = state.copyWith(
        items: [...state.items, CartItem(product: product, quantity: 1)],
      );
    }
  }

  void increment(String productId) {
    final idx = _indexOf(productId);
    if (idx < 0) return;
    _updateItem(idx, (item) => item.copyWith(quantity: item.quantity + 1));
  }

  void decrement(String productId) {
    final idx = _indexOf(productId);
    if (idx < 0) return;
    if (state.items[idx].quantity <= 1) {
      remove(productId);
    } else {
      _updateItem(idx, (item) => item.copyWith(quantity: item.quantity - 1));
    }
  }

  void remove(String productId) {
    state = state.copyWith(
      items: state.items.where((i) => i.product.id != productId).toList(),
    );
  }

  void setItemDiscount(String productId, double pct) {
    final idx = _indexOf(productId);
    if (idx < 0) return;
    _updateItem(
        idx, (item) => item.copyWith(discountPct: pct.clamp(0.0, 100.0)));
  }

  void setOrderDiscount(double amount) {
    state = state.copyWith(
      orderDiscountAmount: amount.clamp(0.0, state.subtotal),
    );
  }

  /// Clears current cart items and discounts, preserving held orders queue
  void clear() => state = state.copyWith(
        items: const [],
        orderDiscountAmount: 0.0,
      );

  /// Holds the current active cart and pushes it into the heldOrders list
  HeldOrder? holdCurrentCart({String? customerName, String? note}) {
    if (state.items.isEmpty) return null;

    final heldOrder = HeldOrder(
      id: 'HOLD-${DateTime.now().millisecondsSinceEpoch}',
      ticketNumber: state.ticketNumber,
      items: List<CartItem>.from(state.items),
      orderDiscountAmount: state.orderDiscountAmount,
      heldAt: DateTime.now(),
      customerName: customerName,
      note: note,
    );

    final nextTicket = _generateNextTicketNumber();

    state = CartState(
      items: const [],
      orderDiscountAmount: 0.0,
      ticketNumber: nextTicket,
      heldOrders: [heldOrder, ...state.heldOrders],
    );

    return heldOrder;
  }

  /// Backward compatible holdOrder method
  void holdOrder() => holdCurrentCart();

  /// Restores a previously held order into active cart
  void resumeHeldOrder(String heldOrderId) {
    final idx = state.heldOrders.indexWhere((h) => h.id == heldOrderId);
    if (idx < 0) return;

    final targetHeld = state.heldOrders[idx];
    final remainingHeld = List<HeldOrder>.from(state.heldOrders)..removeAt(idx);

    // If active cart has unheld items, park it into held orders first
    List<HeldOrder> updatedHeld = remainingHeld;
    if (state.items.isNotEmpty) {
      final currentHeld = HeldOrder(
        id: 'HOLD-${DateTime.now().millisecondsSinceEpoch}',
        ticketNumber: state.ticketNumber,
        items: List<CartItem>.from(state.items),
        orderDiscountAmount: state.orderDiscountAmount,
        heldAt: DateTime.now(),
      );
      updatedHeld = [currentHeld, ...updatedHeld];
    }

    state = CartState(
      items: targetHeld.items,
      orderDiscountAmount: targetHeld.orderDiscountAmount,
      ticketNumber: targetHeld.ticketNumber,
      heldOrders: updatedHeld,
    );
  }

  /// Removes/discards a held order from the queue
  void discardHeldOrder(String heldOrderId) {
    state = state.copyWith(
      heldOrders: state.heldOrders.where((h) => h.id != heldOrderId).toList(),
    );
  }

  /// Call after checkout to advance ticket number and clear active items
  void advanceTicket() {
    state = CartState(
      items: const [],
      orderDiscountAmount: 0.0,
      ticketNumber: _generateNextTicketNumber(),
      heldOrders: state.heldOrders,
    );
  }

  // ── Helpers ───────────────────────────────────────────────

  String _generateNextTicketNumber() {
    final match = RegExp(r'SP-(\d+)').firstMatch(state.ticketNumber);
    if (match != null) {
      final num = int.tryParse(match.group(1) ?? '1') ?? 1;
      return 'SP-${(num + 1).toString().padLeft(3, '0')}';
    }
    return 'SP-${(state.heldOrders.length + 2).toString().padLeft(3, '0')}';
  }

  int _indexOf(String productId) =>
      state.items.indexWhere((i) => i.product.id == productId);

  void _updateItem(int idx, CartItem Function(CartItem) transform) {
    final updated = List<CartItem>.from(state.items);
    updated[idx] = transform(updated[idx]);
    state = state.copyWith(items: updated);
  }
}

final cartProvider =
    NotifierProvider<CartNotifier, CartState>(CartNotifier.new);
