import '../../data/mock/mock_products.dart';

enum PaymentMethodType {
  cash,
  kpay,
  wavePay,
  mobileBanking,
  credit,
}

class SaleTransactionItem {
  const SaleTransactionItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.unitCost = 0.0,
    this.discountPercent = 0.0,
    required this.lineTotal,
    this.originType,
    this.category = ProductCategory.others,
  });

  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double unitCost;
  final double discountPercent;
  final double lineTotal;
  final OriginType? originType;
  final ProductCategory category;
}

class SaleTransaction {
  const SaleTransaction({
    required this.receiptNo,
    required this.branchId,
    required this.branchName,
    this.cashierName = 'Cashier #1',
    this.customerName,
    this.customerPhone,
    required this.items,
    required this.subtotal,
    this.discountAmount = 0.0,
    required this.totalAmount,
    required this.paymentMethod,
    this.tenderedAmount = 0.0,
    this.changeAmount = 0.0,
    this.referenceId,
    this.notes,
    required this.createdAt,
  });

  final String receiptNo;
  final String branchId;
  final String branchName;
  final String cashierName;
  final String? customerName;
  final String? customerPhone;
  final List<SaleTransactionItem> items;
  final double subtotal;
  final double discountAmount;
  final double totalAmount;
  final PaymentMethodType paymentMethod;
  final double tenderedAmount;
  final double changeAmount;
  final String? referenceId;
  final String? notes;
  final DateTime createdAt;

  bool get isCash => paymentMethod == PaymentMethodType.cash;
  bool get isCredit => paymentMethod == PaymentMethodType.credit;
  bool get isDigital =>
      paymentMethod == PaymentMethodType.kpay ||
      paymentMethod == PaymentMethodType.wavePay ||
      paymentMethod == PaymentMethodType.mobileBanking;

  String get paymentMethodLabel => switch (paymentMethod) {
        PaymentMethodType.cash => 'Cash',
        PaymentMethodType.kpay => 'KPay',
        PaymentMethodType.wavePay => 'WavePay',
        PaymentMethodType.mobileBanking => 'Mobile Banking',
        PaymentMethodType.credit => 'Credit',
      };

  String get paymentMethodDisplay => switch (paymentMethod) {
        PaymentMethodType.cash => 'Cash (ငွေသား)',
        PaymentMethodType.kpay => 'KPay',
        PaymentMethodType.wavePay => 'WavePay',
        PaymentMethodType.mobileBanking => 'Mobile Banking',
        PaymentMethodType.credit => 'Credit (အကြွေး)',
      };
}
