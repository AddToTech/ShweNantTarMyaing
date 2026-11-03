import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sitepyoe/data/models/app_user.dart';
import 'package:sitepyoe/ui/features/auth/view_models/auth_notifier.dart';

void main() {
  group('AuthNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state has default staff accounts and is not authenticated', () {
      final state = container.read(authProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.currentUser, isNull);
      expect(state.users.length, 4);

      final superAdmin = state.users.firstWhere((u) => u.role == UserRole.owner);
      expect(superAdmin.name, 'Daw Hla');
      expect(superAdmin.email, 'admin@sitepyoe.com');
    });

    test('Super Admin login with email and password succeeds', () {
      final notifier = container.read(authProvider.notifier);
      final success = notifier.login('admin@sitepyoe.com', 'admin123');

      expect(success, isTrue);
      final state = container.read(authProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.currentUser?.role, UserRole.owner);
      expect(state.currentUser?.name, 'Daw Hla');
      expect(state.isOwner, isTrue);
      expect(state.canManageUsers, isTrue);
      expect(state.canViewReports, isTrue);
    });

    test('Super Admin login with shorthand "admin" succeeds', () {
      final notifier = container.read(authProvider.notifier);
      final success = notifier.login('admin', 'admin123');

      expect(success, isTrue);
      final state = container.read(authProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.currentUser?.name, 'Daw Hla');
    });

    test('Login with incorrect password fails and sets error', () {
      final notifier = container.read(authProvider.notifier);
      final success = notifier.login('admin@sitepyoe.com', 'wrongpassword');

      expect(success, isFalse);
      final state = container.read(authProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.currentUser, isNull);
      expect(state.errorMessage, contains('Incorrect password'));
    });

    test('Login with unknown email fails', () {
      final notifier = container.read(authProvider.notifier);
      final success = notifier.login('nobody@sitepyoe.com', '123456');

      expect(success, isFalse);
      final state = container.read(authProvider);
      expect(state.errorMessage, contains('not found'));
    });

    test('Logout clears current user and sets isAuthenticated to false', () {
      final notifier = container.read(authProvider.notifier);
      notifier.login('admin@sitepyoe.com', 'admin123');
      expect(container.read(authProvider).isAuthenticated, isTrue);

      notifier.logout();
      final state = container.read(authProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.currentUser, isNull);
    });

    test('addUser adds a new staff account', () {
      final notifier = container.read(authProvider.notifier);
      final newUser = AppUser(
        id: 'usr_new_01',
        name: 'Ko Aung',
        email: 'aung@sitepyoe.com',
        password: 'pass',
        role: UserRole.cashier,
        branchId: 'branch_a',
        createdAt: DateTime.now(),
      );

      notifier.addUser(newUser);
      final state = container.read(authProvider);
      expect(state.users.length, 5);
      expect(state.users.any((u) => u.id == 'usr_new_01'), isTrue);

      // Verify the new user can log in
      final loginOk = notifier.login('aung@sitepyoe.com', 'pass');
      expect(loginOk, isTrue);
      expect(container.read(authProvider).currentUser?.name, 'Ko Aung');
    });

    test('updateUser updates user details properly', () {
      final notifier = container.read(authProvider.notifier);
      final cashier = container.read(authProvider).users.firstWhere((u) => u.id == 'usr_cashier_1');
      final updated = cashier.copyWith(name: 'Maung Maung Updated', phone: '09-11112222');

      notifier.updateUser(updated);
      final refreshed = container.read(authProvider).users.firstWhere((u) => u.id == 'usr_cashier_1');
      expect(refreshed.name, 'Maung Maung Updated');
      expect(refreshed.phone, '09-11112222');
    });

    test('toggleUserStatus prevents deactivating own active account and last super admin', () {
      final notifier = container.read(authProvider.notifier);
      notifier.login('admin@sitepyoe.com', 'admin123');

      // Attempt to deactivate self
      final selfErr = notifier.toggleUserStatus('usr_super_admin');
      expect(selfErr, contains('Cannot deactivate your own active account'));

      // Deactivate a cashier
      final cashierErr = notifier.toggleUserStatus('usr_cashier_1');
      expect(cashierErr, isNull);

      final cashier = container.read(authProvider).users.firstWhere((u) => u.id == 'usr_cashier_1');
      expect(cashier.isActive, isFalse);

      // Deactivated user cannot log in
      notifier.logout();
      final blockedLogin = notifier.login('cashier.a@sitepyoe.com', 'cashier123');
      expect(blockedLogin, isFalse);
      expect(container.read(authProvider).errorMessage, contains('deactivated'));
    });

    test('deleteUser deletes user and guards against deleting self or only admin', () {
      final notifier = container.read(authProvider.notifier);
      notifier.login('admin@sitepyoe.com', 'admin123');

      final deleteSelfErr = notifier.deleteUser('usr_super_admin');
      expect(deleteSelfErr, contains('Cannot delete currently signed-in user'));

      final ok = notifier.deleteUser('usr_cashier_2');
      expect(ok, isNull);
      expect(container.read(authProvider).users.any((u) => u.id == 'usr_cashier_2'), isFalse);
    });
  });
}
