import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/overview_tab_view.dart';
import '../widgets/sales_transactions_tab_view.dart';
import '../widgets/purchases_tab_view.dart';
import '../widgets/product_sales_tab_view.dart';
import '../widgets/stock_valuation_tab_view.dart';
import '../widgets/credit_ledger_tab_view.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // ── Top Header & Tab Navigation ────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.query_stats_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'လုပ်ငန်းသုံး အစီရင်ခံစာများ (Reports)',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'အရောင်း၊ အဝယ်၊ ကုန်ပစ္စည်းစွမ်းဆောင်ရည်၊ အရင်းတန်ဖိုးနှင့် အကြွေးစာရင်း အစီရင်ခံစာများ',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── Tab Bar ──────────────────────────────────────────
                  TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.dashboard_customize_outlined, size: 18),
                        text: 'Overview (ခြုံငုံသုံးသပ်ချက်)',
                      ),
                      Tab(
                        icon: Icon(Icons.receipt_long_outlined, size: 18),
                        text: 'Sales (အရောင်းမှတ်တမ်း)',
                      ),
                      Tab(
                        icon: Icon(Icons.shopping_bag_outlined, size: 18),
                        text: 'Purchases (အဝယ်စာရင်း)',
                      ),
                      Tab(
                        icon: Icon(Icons.inventory_2_outlined, size: 18),
                        text: 'Product-wise (ပစ္စည်းအလိုက်)',
                      ),
                      Tab(
                        icon: Icon(Icons.account_balance_wallet_outlined, size: 18),
                        text: 'Valuation (ကုန်ပစ္စည်းတန်ဖိုး)',
                      ),
                      Tab(
                        icon: Icon(Icons.credit_card_outlined, size: 18),
                        text: 'Credit Ledger (အကြွေးစာရင်း)',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Tab Views Body ────────────────────────────────────
            const Expanded(
              child: TabBarView(
                physics: NeverScrollableScrollPhysics(), // Tablet desktop-like tabs
                children: [
                  OverviewTabView(),
                  SalesTransactionsTabView(),
                  PurchasesTabView(),
                  ProductSalesTabView(),
                  StockValuationTabView(),
                  CreditLedgerTabView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
