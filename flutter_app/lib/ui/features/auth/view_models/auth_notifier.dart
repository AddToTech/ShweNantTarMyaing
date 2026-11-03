import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../data/models/app_user.dart';
import '../../../../data/repositories/branch_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../branch_transfer/view_models/transfer_notifier.dart';
import '../../hr_payroll/view_models/employee_notifier.dart';
import '../../hr_payroll/view_models/payroll_notifier.dart';
import '../../inventory/view_models/inventory_notifier.dart';
import '../../orders/view_models/order_history_notifier.dart';
import '../../pos/view_models/transaction_notifier.dart';
import '../../purchases/view_models/purchase_notifier.dart';
import '../../purchases/view_models/vendor_notifier.dart';
import '../../settings/view_models/category_notifier.dart';
import '../../settings/view_models/permission_group_notifier.dart';
import '../../wastage/view_models/wastage_notifier.dart';

final kInitialUsers = <AppUser>[];

class AuthState {
  final AppUser? currentUser;
  final bool isAuthenticated;
  final List<AppUser> users;
  final String? errorMessage;
  final bool isLoading;

  const AuthState({
    this.currentUser,
    this.isAuthenticated = false,
    this.users = const [],
    this.errorMessage,
    this.isLoading = false,
  });

  bool get isOwner => currentUser?.role == UserRole.owner;
  bool get isManager => currentUser?.role == UserRole.manager || isOwner;
  bool get canManageUsers => isOwner;
  bool get canViewReports => isManager;

  AuthState copyWith({
    AppUser? currentUser,
    bool? isAuthenticated,
    List<AppUser>? users,
    String? errorMessage,
    bool clearError = false,
    bool? isLoading,
  }) {
    return AuthState(
      currentUser: currentUser ?? this.currentUser,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      users: users ?? this.users,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  final AuthService _authService;
  final UserRepository _userRepository;

  AuthNotifier({
    required Ref ref,
    required AuthService authService,
    required UserRepository userRepository,
  })  : _ref = ref,
        _authService = authService,
        _userRepository = userRepository,
        super(AuthState(
          users: kInitialUsers,
          currentUser: authService.currentUser,
          isAuthenticated: authService.isAuthenticated,
        )) {
    _initSession();
  }

  Future<void> _initSession() async {
    await _authService.init();
    loadRemoteUsers();
    try {
      _ref.read(branchesProvider.notifier).loadBranches();
      _ref.read(categoryNotifierProvider.notifier).loadCategories();
      _ref.read(permissionGroupProvider.notifier).loadGroups();
    } catch (_) {}

    if (_authService.currentUser != null) {
      await _authService.ensureValidToken();
      state = state.copyWith(
        currentUser: _authService.currentUser,
        isAuthenticated: true,
      );
      syncAllAppData();
    }
  }

  /// Syncs all modules across the application with the live PostgreSQL backend database
  void syncAllAppData() {
    try {
      _ref.read(branchesProvider.notifier).loadBranches();
      _ref.read(catalogProvider.notifier).loadProducts();
      _ref.read(inventoryProvider.notifier).loadAllBranchStocks();
      _ref.read(categoryNotifierProvider.notifier).loadCategories();
      _ref.read(permissionGroupProvider.notifier).loadGroups();
      _ref.read(vendorProvider.notifier).loadVendors();
      _ref.read(purchaseProvider.notifier).loadPurchases();
      _ref.read(employeeProvider.notifier).loadEmployees();
      _ref.read(payrollProvider.notifier).loadPayrolls();
      _ref.read(transferProvider.notifier).loadTransfers();
      _ref.read(wastageProvider.notifier).loadWastage();
      final _ = _ref.refresh(remoteSalesProvider);
      loadRemoteUsers();
    } catch (_) {}
  }

  /// Authenticate user via email/username and password
  Future<bool> login(String emailOrUsername, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final cleanInput = emailOrUsername.trim();
    final cleanPass = password.trim();

    if (cleanInput.isEmpty || cleanPass.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Email/Username and password are required',
      );
      return false;
    }

    // 1. Try real API authentication first
    try {
      final user = await _authService.login(
        identifier: cleanInput,
        password: cleanPass,
      );

      state = state.copyWith(
        currentUser: user,
        isAuthenticated: true,
        isLoading: false,
        clearError: true,
      );

      // Immediately synchronize all app data from remote database
      syncAllAppData();

      return true;
    } on UnauthorizedException catch (e) {
      // ⛔ 401 Unauthorized: Invalid credentials. Server explicitly rejected login.
      // Business logic: Reject immediately, show error message, NEVER bypass or fallback.
      debugPrint('[AuthNotifier] ⛔ 401 Login rejected by server: ${e.message}');
      state = state.copyWith(
        currentUser: null,
        isAuthenticated: false,
        isLoading: false,
        errorMessage: e.message.isNotEmpty
            ? e.message
            : 'အကောင့်အမည် သို့မဟုတ် စကားဝှက် မှားယွင်းနေပါသည် (Invalid credentials)',
      );
      return false;
    } on ForbiddenException catch (e) {
      // ⛔ 403 Forbidden: Account deactivated or banned.
      debugPrint('[AuthNotifier] ⛔ 403 Account deactivated: ${e.message}');
      state = state.copyWith(
        currentUser: null,
        isAuthenticated: false,
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } on ValidationException catch (e) {
      // ⚠️ 400 Bad Request
      debugPrint('[AuthNotifier] ⚠️ 400 Validation error: ${e.message}');
      state = state.copyWith(
        currentUser: null,
        isAuthenticated: false,
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } on ServerException catch (e) {
      // 💥 500 Internal Server Error
      debugPrint('[AuthNotifier] 💥 500 Server error: ${e.message}');
      state = state.copyWith(
        currentUser: null,
        isAuthenticated: false,
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      // 2. Only if truly offline (NetworkException / host unreachable)
      if (e is NetworkException) {
        debugPrint('[AuthNotifier] 📡 Server offline. Checking offline cache...');
        final matchedUser = state.users.cast<AppUser?>().firstWhere(
          (u) {
            if (u == null) return false;
            final uEmail = u.email.toLowerCase();
            final inputLower = cleanInput.toLowerCase();
            if (uEmail == inputLower) return true;
            if (inputLower == 'admin' && u.role == UserRole.owner) return true;
            if (u.name.toLowerCase() == inputLower) return true;
            return false;
          },
          orElse: () => null,
        );

        if (matchedUser != null && matchedUser.password == cleanPass && matchedUser.isActive) {
          final updatedUser = matchedUser.copyWith(lastLoginAt: DateTime.now());
          final updatedList = state.users.map((u) => u.id == updatedUser.id ? updatedUser : u).toList();
          await _authService.cacheOfflineSession(
            updatedUser,
            identifier: cleanInput,
            password: cleanPass,
          );

          state = state.copyWith(
            currentUser: updatedUser,
            isAuthenticated: true,
            users: updatedList,
            isLoading: false,
            clearError: true,
          );
          return true;
        } else {
          state = state.copyWith(
            currentUser: null,
            isAuthenticated: false,
            isLoading: false,
            errorMessage: 'ဆာဗာချိတ်ဆက်၍ မရပါ (Offline Mode)။ အကောင့်အမည် သို့မဟုတ် စကားဝှက် မှားယွင်းနေပါသည်။',
          );
          return false;
        }
      }

      state = state.copyWith(
        currentUser: null,
        isAuthenticated: false,
        isLoading: false,
        errorMessage: e.toString().replaceFirst('ApiException: ', ''),
      );
      return false;
    }
  }

  Future<void> loadRemoteUsers() async {
    try {
      final remoteUsers = await _userRepository.getUsers();
      if (remoteUsers.isNotEmpty) {
        state = state.copyWith(users: remoteUsers);
      }
    } catch (_) {}
  }

  /// Sign out current active user
  Future<void> logout() async {
    await _authService.logout();
    try {
      _ref.read(transactionProvider.notifier).clearLocalTransactions();
    } catch (_) {}
    state = AuthState(
      users: state.users,
      currentUser: null,
      isAuthenticated: false,
      errorMessage: null,
      isLoading: false,
    );
  }

  /// Add a new staff user to access system
  Future<bool> addUser(AppUser newUser) async {
    try {
      await _userRepository.createUser({
        'name': newUser.name,
        'email': newUser.email,
        'phone': newUser.phone,
        'password': newUser.password.isNotEmpty ? newUser.password : 'sitepyoe123',
        'role': newUser.role.code,
        'permissionGroupId': newUser.permissionGroupId,
        'customPermissions': newUser.customPermissions?.map((p) => p.code).toList(),
        'branchId': newUser.branchId,
        'isActive': newUser.isActive,
      });
      await loadRemoteUsers();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Update existing staff details
  Future<bool> updateUser(AppUser updatedUser) async {
    try {
      await _userRepository.updateUser(updatedUser.id, {
        'name': updatedUser.name,
        'email': updatedUser.email,
        'phone': updatedUser.phone,
        if (updatedUser.password.trim().isNotEmpty)
          'password': updatedUser.password.trim(),
        'role': updatedUser.role.code,
        'permissionGroupId': updatedUser.permissionGroupId,
        'customPermissions':
            updatedUser.customPermissions?.map((p) => p.code).toList(),
        'branchId': updatedUser.branchId,
        'isActive': updatedUser.isActive,
      });
      await loadRemoteUsers();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Toggle user active status
  Future<String?> toggleUserStatus(String userId) async {
    if (state.currentUser?.id == userId) {
      return 'Cannot deactivate your own active account.';
    }

    final target = state.users.firstWhere((u) => u.id == userId);
    if (target.role == UserRole.owner && target.isActive) {
      final activeOwners = state.users.where((u) => u.role == UserRole.owner && u.isActive).length;
      if (activeOwners <= 1) {
        return 'Cannot deactivate the only active Super Admin.';
      }
    }

    try {
      await _userRepository.toggleUser(userId);
      final updated = target.copyWith(isActive: !target.isActive);
      final updatedList = state.users.map((u) => u.id == updated.id ? updated : u).toList();
      state = state.copyWith(users: updatedList);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('ApiException: ', '');
    }
  }

  /// Delete a staff account
  Future<String?> deleteUser(String userId) async {
    if (state.currentUser?.id == userId) {
      return 'Cannot delete currently signed-in user.';
    }

    final target = state.users.firstWhere((u) => u.id == userId);
    if (target.role == UserRole.owner) {
      final totalOwners = state.users.where((u) => u.role == UserRole.owner).length;
      if (totalOwners <= 1) {
        return 'System must have at least one Super Admin.';
      }
    }

    try {
      await _userRepository.deleteUser(userId);
      state = state.copyWith(
        users: state.users.where((u) => u.id != userId).toList(),
        clearError: true,
      );
      return null;
    } catch (e) {
      return e.toString().replaceFirst('ApiException: ', '');
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  return AuthNotifier(
    ref: ref,
    authService: authService,
    userRepository: userRepository,
  );
});
