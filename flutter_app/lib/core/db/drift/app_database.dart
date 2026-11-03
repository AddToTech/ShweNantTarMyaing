// ============================================================
// SitePyoe — Offline-first local DB configuration
// Uses Drift (SQLite) for structured relational local cache
// ============================================================

// pubspec.yaml additions:
//
// dependencies:
//   drift: ^2.18.0
//   sqlite3_flutter_libs: ^0.5.0   # bundles SQLite for Android/iOS/Desktop
//   path_provider: ^2.1.0
//   path: ^1.9.0
//
// dev_dependencies:
//   drift_dev: ^2.18.0
//   build_runner: ^2.4.0

// Run code-gen after editing table definitions:
//   dart run build_runner build --delete-conflicting-outputs

// ──────────────────────────────────────────────────────────
// FILE: lib/core/db/drift/app_database.dart
// ──────────────────────────────────────────────────────────
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';  // generated

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// ── Table: Branches (local cache) ─────────────────────────
class BranchesCache extends Table {
  TextColumn get id          => text()();
  TextColumn get name        => text()();
  TextColumn get address     => text().nullable()();
  BoolColumn get isActive    => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime()();

  @override Set<Column> get primaryKey => {id};
}

// ── Table: Categories (local cache) ───────────────────────
class CategoriesCache extends Table {
  TextColumn get id         => text()();
  TextColumn get name       => text()();
  IntColumn  get sortOrder  => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override Set<Column> get primaryKey => {id};
}

// ── Table: Subcategories (local cache) ────────────────────
class SubcategoriesCache extends Table {
  TextColumn get id          => text()();
  TextColumn get categoryId  => text()();
  TextColumn get name        => text()();
  IntColumn  get sortOrder   => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override Set<Column> get primaryKey => {id};
}

// ── Table: Products (local cache) ─────────────────────────
class ProductsCache extends Table {
  TextColumn get id              => text()();
  TextColumn get categoryId      => text()();
  TextColumn get subcategoryId   => text().nullable()();
  TextColumn get name            => text()();
  TextColumn get sku             => text().nullable()();
  TextColumn get barcode         => text().nullable()();
  RealColumn get costPrice       => real().withDefault(const Constant(0.0))();
  RealColumn get salePrice       => real().withDefault(const Constant(0.0))();
  TextColumn get originType      => text().nullable()(); // thai_import|china_import|local
  TextColumn get sizeLabel       => text().nullable()();
  TextColumn get unitOfMeasure   => text().withDefault(const Constant('piece'))();
  TextColumn get attributesJson  => text().withDefault(const Constant('{}'))(); // JSONB as string
  BoolColumn get isActive        => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt   => dateTime()();

  @override Set<Column> get primaryKey => {id};
}

// ── Table: Branch Inventories (local cache) ───────────────
class BranchInventoriesCache extends Table {
  TextColumn get id                 => text()();
  TextColumn get branchId           => text()();
  TextColumn get productId          => text()();
  RealColumn get stockQuantity      => real().withDefault(const Constant(0.0))();
  RealColumn get minAlertThreshold  => real().withDefault(const Constant(0.0))();
  DateTimeColumn get updatedAt      => dateTime()();

  @override Set<Column> get primaryKey => {id};
}

// ── Table: Pending Sales (offline queue) ──────────────────
// Sales created offline that have NOT yet synced to the server.
class PendingSales extends Table {
  IntColumn  get localId       => integer().autoIncrement()();
  TextColumn get saleUuid      => text()();           // client-generated UUID
  TextColumn get branchId      => text()();
  TextColumn get cashierId     => text()();
  TextColumn get payloadJson   => text()();           // full sale JSON payload
  BoolColumn get isSynced      => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}

// ── Table: Vendors (local cache) ─────────────────────────
class VendorsCache extends Table {
  TextColumn get id        => text()();
  TextColumn get name      => text()();
  TextColumn get phone     => text().nullable()();
  TextColumn get address   => text().nullable()();
  TextColumn get notes     => text().nullable()();
  BoolColumn get isActive  => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override Set<Column> get primaryKey => {id};
}

// ── Table: Purchases (local cache) ────────────────────────
class PurchasesCache extends Table {
  TextColumn get id             => text()();
  TextColumn get purchaseNo     => text()();
  TextColumn get branchId       => text()();
  TextColumn get vendorId       => text().nullable()();
  TextColumn get vendorName     => text().nullable()(); // snapshot
  DateTimeColumn get purchaseDate => dateTime()();
  RealColumn get subtotal       => real().withDefault(const Constant(0.0))();
  RealColumn get discount       => real().withDefault(const Constant(0.0))();
  RealColumn get totalAmount    => real().withDefault(const Constant(0.0))();
  RealColumn get paidAmount     => real().withDefault(const Constant(0.0))();
  /// 'paid' | 'unpaid' | 'partial'
  TextColumn get paymentStatus  => text().withDefault(const Constant('unpaid'))();
  TextColumn get notes          => text().nullable()();
  TextColumn get createdBy      => text().nullable()();
  DateTimeColumn get createdAt  => dateTime()();

  @override Set<Column> get primaryKey => {id};
}

// ── Table: Purchase Items (local cache) ───────────────────
class PurchaseItemsCache extends Table {
  TextColumn get id                   => text()();
  TextColumn get purchaseId           => text()();
  TextColumn get productId            => text()();
  TextColumn get productNameSnapshot  => text()();
  RealColumn get quantity             => real()();
  RealColumn get unitCost             => real()();

  @override Set<Column> get primaryKey => {id};
}

// ── Table: Employees (local cache) ────────────────────────
class EmployeesCache extends Table {
  TextColumn get id           => text()();
  TextColumn get branchId     => text()();
  TextColumn get name         => text()();
  TextColumn get role         => text()();
  TextColumn get phone        => text().nullable()();
  TextColumn get address      => text().nullable()();
  RealColumn get basicSalary  => real().withDefault(const Constant(0.0))();
  DateTimeColumn get joinDate => dateTime()();
  BoolColumn get isActive     => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override Set<Column> get primaryKey => {id};
}

// ── Table: Payrolls (local cache) ─────────────────────────
class PayrollsCache extends Table {
  TextColumn get id                    => text()();
  TextColumn get employeeId           => text()();
  TextColumn get branchId             => text()();
  TextColumn get payrollPeriod        => text()(); // e.g. "2026-10"
  RealColumn get basicSalary          => real()();
  RealColumn get bonusAmount          => real().withDefault(const Constant(0.0))();
  TextColumn get bonusDescription     => text().nullable()();
  RealColumn get deductionAmount      => real().withDefault(const Constant(0.0))();
  TextColumn get deductionDescription => text().nullable()();
  RealColumn get netSalary            => real()();
  TextColumn get paymentMethod        => text().withDefault(const Constant('cash'))();
  DateTimeColumn get paymentDate      => dateTime()();
  TextColumn get paidBy               => text().nullable()();
  TextColumn get notes                => text().nullable()();
  DateTimeColumn get createdAt        => dateTime()();

  @override Set<Column> get primaryKey => {id};
}

// ── Table: Pending Wastage Logs (offline queue) ───────────
class PendingWastageLogs extends Table {
  IntColumn  get localId       => integer().autoIncrement()();
  TextColumn get logUuid       => text()();
  TextColumn get branchId      => text()();
  TextColumn get payloadJson   => text()();
  BoolColumn get isSynced      => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}

// ── Database class ─────────────────────────────────────────
@DriftDatabase(tables: [
  BranchesCache,
  CategoriesCache,
  SubcategoriesCache,
  ProductsCache,
  BranchInventoriesCache,
  PendingSales,
  PendingWastageLogs,
  VendorsCache,
  PurchasesCache,
  PurchaseItemsCache,
  EmployeesCache,
  PayrollsCache,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override int get schemaVersion => 3;

  @override MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(vendorsCache);
        await m.createTable(purchasesCache);
        await m.createTable(purchaseItemsCache);
      }
      if (from < 3) {
        await m.createTable(employeesCache);
        await m.createTable(payrollsCache);
      }
    },
  );

  // ── Catalog sync helpers ───────────────────────────────

  /// Replace all products for a branch from server response.
  Future<void> syncProducts(List<ProductsCacheCompanion> rows) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(productsCache, rows);
    });
  }

  Future<void> syncCategories(List<CategoriesCacheCompanion> rows) async {
    await batch((b) { b.insertAllOnConflictUpdate(categoriesCache, rows); });
  }

  Future<void> syncInventories(List<BranchInventoriesCacheCompanion> rows) async {
    await batch((b) { b.insertAllOnConflictUpdate(branchInventoriesCache, rows); });
  }

  // ── Product catalog queries ────────────────────────────

  Future<List<ProductsCacheData>> getProductsByCategory(String categoryId) =>
      (select(productsCache)
        ..where((p) => p.categoryId.equals(categoryId) & p.isActive.equals(true)))
          .get();

  Future<ProductsCacheData?> getProductByBarcode(String barcode) =>
      (select(productsCache)..where((p) => p.barcode.equals(barcode))).getSingleOrNull();

  // ── Low-stock alerts ───────────────────────────────────
  Future<List<BranchInventoriesCacheData>> getLowStockItems(String branchId) =>
      (select(branchInventoriesCache)
        ..where((i) =>
            i.branchId.equals(branchId) &
            i.stockQuantity.isSmallerOrEqual(i.minAlertThreshold)))
          .get();

  // ── Offline queue helpers ──────────────────────────────

  Future<List<PendingSale>> getUnsyncedSales() =>
      (select(pendingSales)..where((s) => s.isSynced.equals(false))).get();

  Future<void> markSaleSynced(int localId) =>
      (update(pendingSales)..where((s) => s.localId.equals(localId)))
          .write(const PendingSalesCompanion(isSynced: Value(true)));

  Future<List<PendingWastageLog>> getUnsyncedWastageLogs() =>
      (select(pendingWastageLogs)..where((w) => w.isSynced.equals(false))).get();

  Future<void> markWastagelLogSynced(int localId) =>
      (update(pendingWastageLogs)..where((w) => w.localId.equals(localId)))
          .write(const PendingWastageLogsCompanion(isSynced: Value(true)));
}

// ── Connection factory ─────────────────────────────────────
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file     = File(p.join(dbFolder.path, 'sitepyoe_local.db'));
    return NativeDatabase.createInBackground(file);
  });
}
