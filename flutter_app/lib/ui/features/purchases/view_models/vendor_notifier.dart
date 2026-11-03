// ============================================================
// Vendor domain model & Riverpod notifier
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/vendor_repository.dart';

// ── Vendor model ─────────────────────────────────────────────
class Vendor {
  const Vendor({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.notes,
    this.isActive = true,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? phone;
  final String? address;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;

  Vendor copyWith({
    String? name,
    String? phone,
    bool clearPhone = false,
    String? address,
    bool clearAddress = false,
    String? notes,
    bool clearNotes = false,
    bool? isActive,
  }) {
    return Vendor(
      id: id,
      name: name ?? this.name,
      phone: clearPhone ? null : (phone ?? this.phone),
      address: clearAddress ? null : (address ?? this.address),
      notes: clearNotes ? null : (notes ?? this.notes),
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'address': address,
    'notes': notes,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
  };
}

// ── Vendors (empty — loaded dynamically from GET /api/v1/vendors) ────────────
const List<Vendor> kDemoVendors = [];

final vendorLoadingProvider = StateProvider<bool>((ref) => true);

// ── VendorNotifier ─────────────────────────────────────────────
class VendorNotifier extends Notifier<List<Vendor>> {
  @override
  List<Vendor> build() {
    _loadFromRemote();
    return const [];
  }

  Future<void> loadVendors() => _loadFromRemote();

  Future<void> _loadFromRemote() async {
    ref.read(vendorLoadingProvider.notifier).state = true;
    try {
      final remote = await ref.read(vendorRepositoryProvider).getVendors();
      state = remote;
    } catch (_) {
    } finally {
      ref.read(vendorLoadingProvider.notifier).state = false;
    }
  }

  Future<Vendor?> addVendor({
    required String name,
    String? phone,
    String? address,
    String? notes,
  }) async {
    try {
      final created = await ref.read(vendorRepositoryProvider).createVendor(
        name: name,
        phone: phone?.isNotEmpty == true ? phone : null,
        address: address?.isNotEmpty == true ? address : null,
        notes: notes?.isNotEmpty == true ? notes : null,
      );
      state = [...state, created];
      return created;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateVendor(Vendor updated) async {
    try {
      await ref.read(vendorRepositoryProvider).updateVendor(updated.id, {
        'name': updated.name,
        'phone': updated.phone,
        'address': updated.address,
        'notes': updated.notes,
        'isActive': updated.isActive,
      });
      state = [
        for (final v in state)
          if (v.id == updated.id) updated else v,
      ];
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleActive(String vendorId) async {
    try {
      await ref.read(vendorRepositoryProvider).toggleVendor(vendorId);
      state = [
        for (final v in state)
          if (v.id == vendorId) v.copyWith(isActive: !v.isActive) else v,
      ];
      return true;
    } catch (_) {
      return false;
    }
  }

  void deleteVendor(String vendorId) {
    state = state.where((v) => v.id != vendorId).toList();
  }
}

final vendorProvider =
    NotifierProvider<VendorNotifier, List<Vendor>>(VendorNotifier.new);

/// Computed: only active vendors, sorted alphabetically
final activeVendorsProvider = Provider<List<Vendor>>((ref) {
  final all = ref.watch(vendorProvider);
  return all.where((v) => v.isActive).toList()
    ..sort((a, b) => a.name.compareTo(b.name));
});
