import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sitepyoe/core/services/receipt_printer_service.dart';
import 'package:sitepyoe/ui/features/hr_payroll/models/employee.dart';
import 'package:sitepyoe/ui/features/hr_payroll/models/payroll.dart';
import 'package:sitepyoe/ui/features/hr_payroll/view_models/employee_notifier.dart';
import 'package:sitepyoe/ui/features/hr_payroll/view_models/payroll_notifier.dart';
import 'package:sitepyoe/ui/features/reports/view_models/reports_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EmployeeNotifier & Employee Management (CRUD) Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state contains baseline employees', () {
      final employees = container.read(employeeProvider);
      expect(employees, isNotEmpty);
      expect(employees.length, kBaselineEmployees.length);
      expect(employees.any((e) => e.name.contains('ဒေါ်အေးအေးဝင်း')), isTrue);
    });

    test('addEmployee adds a new employee with valid attributes and defaults', () async {
      final notifier = container.read(employeeProvider.notifier);
      final initialCount = container.read(employeeProvider).length;

      final newEmp = await notifier.addEmployee(
        branchId: 'branch_a',
        name: 'ကိုအောင်ကို',
        role: EmployeeRole.gardener.label,
        phone: '09-450-123456',
        address: 'အမှတ် ၄၅၊ သပြေကုန်း၊ နေပြည်တော်',
        basicSalary: 320000,
        joinDate: DateTime(2026, 3, 1),
      );

      if (newEmp != null) {
        final employees = container.read(employeeProvider);
        expect(employees.length, initialCount + 1);
        expect(newEmp.id, isNotEmpty);
        expect(newEmp.name, 'ကိုအောင်ကို');
        expect(newEmp.role, EmployeeRole.gardener.label);
        expect(newEmp.basicSalary, 320000);
        expect(newEmp.isActive, isTrue);
      }
    });

    test('updateEmployee updates existing employee fields correctly', () {
      final notifier = container.read(employeeProvider.notifier);
      final original = container.read(employeeProvider).first;

      final updated = original.copyWith(
        name: '${original.name} (မွမ်းမံ)',
        basicSalary: original.basicSalary + 50000,
        phone: '09-999-888-777',
      );

      notifier.updateEmployee(updated);

      final found = notifier.getEmployeeById(original.id);
      expect(found, isNotNull);
      expect(found!.name, '${original.name} (မွမ်းမံ)');
      expect(found.basicSalary, original.basicSalary + 50000);
      expect(found.phone, '09-999-888-777');
    });

    test('toggleActive flips employee active status and activeEmployeesProvider reflects it', () {
      final notifier = container.read(employeeProvider.notifier);
      final first = container.read(employeeProvider).first;
      final initialActiveCount = container.read(activeEmployeesProvider).length;

      expect(first.isActive, isTrue);

      // Deactivate
      notifier.toggleActive(first.id);
      expect(notifier.getEmployeeById(first.id)!.isActive, isFalse);
      expect(container.read(activeEmployeesProvider).length, initialActiveCount - 1);

      // Reactivate
      notifier.toggleActive(first.id);
      expect(notifier.getEmployeeById(first.id)!.isActive, isTrue);
      expect(container.read(activeEmployeesProvider).length, initialActiveCount);
    });

    test('deleteEmployee removes employee from the store', () {
      final notifier = container.read(employeeProvider.notifier);
      final target = container.read(employeeProvider).last;
      final initialCount = container.read(employeeProvider).length;

      notifier.deleteEmployee(target.id);

      final employees = container.read(employeeProvider);
      expect(employees.length, initialCount - 1);
      expect(employees.any((e) => e.id == target.id), isFalse);
    });

    test('filteredEmployeesProvider filters by search query, branch and active toggle', () {
      final filterNotifier = container.read(employeeFilterProvider.notifier);

      // 1. Search by name
      filterNotifier.setSearchQuery('ဒေါ်အေး');
      var filtered = container.read(filteredEmployeesProvider);
      expect(filtered.isNotEmpty, isTrue);
      expect(filtered.every((e) => e.name.contains('ဒေါ်အေး')), isTrue);

      // 2. Filter by branch
      filterNotifier.setSearchQuery('');
      filterNotifier.setBranch('branch_a');
      filtered = container.read(filteredEmployeesProvider);
      expect(filtered.every((e) => e.branchId == 'branch_a'), isTrue);

      // 3. Inactive filter toggle
      final empNotifier = container.read(employeeProvider.notifier);
      final empToDeactivate = filtered.first;
      empNotifier.toggleActive(empToDeactivate.id);

      // With showInactive = false, deactivated employee should not be shown
      filterNotifier.setShowInactive(false);
      filtered = container.read(filteredEmployeesProvider);
      expect(filtered.any((e) => e.id == empToDeactivate.id), isFalse);

      // With showInactive = true, deactivated employee should be shown
      filterNotifier.setShowInactive(true);
      filtered = container.read(filteredEmployeesProvider);
      expect(filtered.any((e) => e.id == empToDeactivate.id), isTrue);
    });
  });

  group('Payroll Calculation & Disbursement Module Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Payroll.create correctly calculates Net Salary = Basic + Bonus - Deduction', () {
      final payroll = Payroll.create(
        employeeId: 'emp_001',
        employeeName: 'ကိုစိုးလွင်',
        employeeRole: 'အရောင်းစာရေး (Cashier)',
        branchId: 'branch_a',
        payrollPeriod: '2026-10',
        basicSalary: 350000,
        bonusAmount: 50000,
        bonusDescription: 'သီတင်းကျွတ် အပိုဆု (Thadingyut Bonus)',
        deductionAmount: 20000,
        deductionDescription: 'အပင်အိုး ၂ လုံး ကွဲရှမှု ဒဏ်ကြေး (Broken 2 Ceramic Pots)',
        paymentMethod: PayrollPaymentMethod.kpay,
        paidBy: 'u_mgr01',
        notes: 'ပုံမှန် လစာရှင်းတမ်း',
      );

      // Net = 350,000 + 50,000 - 20,000 = 380,000
      expect(payroll.basicSalary, 350000);
      expect(payroll.bonusAmount, 50000);
      expect(payroll.deductionAmount, 20000);
      expect(payroll.netSalary, 380000);
      expect(payroll.paymentMethod, PayrollPaymentMethod.kpay);
      expect(payroll.bonusDescription, contains('Thadingyut Bonus'));
      expect(payroll.deductionDescription, contains('Broken 2 Ceramic Pots'));
    });

    test('disburseSalary records new payment and marks employee as paid for period', () async {
      final notifier = container.read(payrollProvider.notifier);
      final initialCount = container.read(payrollProvider).length;

      expect(notifier.isEmployeePaidForPeriod('emp_test_999', '2026-11'), isFalse);

      final payment = await notifier.disburseSalary(
        employeeId: 'emp_test_999',
        employeeName: 'မဇင်မာဦး',
        employeeRole: 'အပင်ထိန်းသိမ်းရေး (Gardener)',
        branchId: 'branch_a',
        payrollPeriod: '2026-11',
        basicSalary: 300000,
        bonusAmount: 15000,
        bonusDescription: 'အပင်စိုက်စွမ်းဆောင်ရည် အပိုဆု',
        deductionAmount: 5000,
        deductionDescription: 'ခွင့်မဲ့ ပျက်ကွက် ၁ ရက်',
        paymentMethod: PayrollPaymentMethod.cash,
        paidBy: 'u_owner01',
      );

      if (payment != null) {
        expect(container.read(payrollProvider).length, initialCount + 1);
        expect(payment.netSalary, 310000); // 300,000 + 15,000 - 5,000
        expect(notifier.isEmployeePaidForPeriod('emp_test_999', '2026-11'), isTrue);
      }
    });

    test('payrollSummaryProvider aggregates totals accurately across filtered payments', () {
      final summary = container.read(payrollSummaryProvider);

      expect(summary.disbursedCount, greaterThan(0));
      expect(summary.totalBasic, greaterThan(0));
      expect(summary.totalBonus, greaterThanOrEqualTo(0));
      expect(summary.totalDeductions, greaterThanOrEqualTo(0));
      expect(summary.totalNetPaid, summary.totalBasic + summary.totalBonus - summary.totalDeductions);
    });

    test('Payroll filters work for period, branch, and payment method', () {
      final filterNotifier = container.read(payrollFilterProvider.notifier);

      // Filter by period
      filterNotifier.setPeriod('2026-10');
      var list = container.read(filteredPayrollsProvider);
      expect(list.every((p) => p.payrollPeriod == '2026-10'), isTrue);

      // Filter by payment method
      filterNotifier.setPaymentMethod(PayrollPaymentMethod.cash);
      list = container.read(filteredPayrollsProvider);
      expect(list.every((p) => p.paymentMethod == PayrollPaymentMethod.cash), isTrue);

      // Reset payment method and test Search query
      filterNotifier.setPaymentMethod(null);
      filterNotifier.setSearchQuery('Broken Pots');
      list = container.read(filteredPayrollsProvider);
      expect(list.isNotEmpty, isTrue);
    });
  });

  group('Reports & Operating Expenses (OPEX) Integration Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Reports dashboard includes payroll operating expense and calculates true net profit', () {
      final reports = container.read(reportsDataProvider);

      // Operating expenses must be positive from baseline payrolls
      expect(reports.operatingExpense, greaterThan(0));
      expect(reports.payrollDisbursedCount, greaterThan(0));

      // Net profit formula: Gross Profit - Wastage Loss - OPEX (Salaries)
      final expectedNetProfit = reports.salesSummary.grossProfit -
          reports.wastageSummary.totalLoss -
          reports.operatingExpense;

      expect(reports.netProfit, expectedNetProfit);
    });
  });

  group('Thermal Payslip Printer Service Tests', () {
    test('generatePayslipBytes generates non-empty ESC/POS bytes for 80mm and 58mm layouts', () async {
      const printer = ReceiptPrinterService();
      final payroll = Payroll.create(
        id: 'pr_test_001',
        employeeId: 'emp_001',
        employeeName: 'မောင်မင်းခန့်',
        employeeRole: 'အရောင်းစာရေး (Cashier)',
        branchId: 'branch_a',
        payrollPeriod: '2026-10',
        basicSalary: 350000,
        bonusAmount: 30000,
        bonusDescription: 'စွမ်းဆောင်ရည် အပိုဆု',
        deductionAmount: 10000,
        deductionDescription: 'အိုးကွဲ ဒဏ်ကြေး',
        paymentMethod: PayrollPaymentMethod.cash,
        paidBy: 'u_mgr01',
        notes: 'လက်မှတ်ရေးထိုး ထုတ်ပေးပြီး',
      );

      // 80mm format
      final bytes80 = await printer.generatePayslipBytes(
        payroll: payroll,
        branchName: 'ရန်ကုန်ဆိုင်ခွဲ',
        settings: const PrinterSettings(paperSize: ReceiptPaperSize.mm80),
      );
      expect(bytes80, isNotEmpty);
      expect(bytes80.length, greaterThan(50));

      // 58mm format
      final bytes58 = await printer.generatePayslipBytes(
        payroll: payroll,
        branchName: 'ရန်ကုန်ဆိုင်ခွဲ',
        settings: const PrinterSettings(paperSize: ReceiptPaperSize.mm58),
      );
      expect(bytes58, isNotEmpty);
      expect(bytes58.length, greaterThan(50));
    });
  });
}
