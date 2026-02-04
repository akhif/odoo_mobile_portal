import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/session_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

// Repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Auth state
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  serverSetupRequired,
  error,
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final ServerConfig? serverConfig;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.serverConfig,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    ServerConfig? serverConfig,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      serverConfig: serverConfig ?? this.serverConfig,
      errorMessage: errorMessage,
    );
  }

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get needsServerSetup => status == AuthStatus.serverSetupRequired;
  bool get hasError => status == AuthStatus.error;
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState());

  // Check initial auth state
  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      // Check if server is configured
      final hasConfig = await _repository.hasServerConfig();
      if (!hasConfig) {
        state = state.copyWith(status: AuthStatus.serverSetupRequired);
        return;
      }

      // Get stored server config
      final serverConfig = await _repository.getStoredServerConfig();

      // Check if logged in (has stored session)
      final isLoggedIn = await _repository.isLoggedIn();
      if (!isLoggedIn) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          serverConfig: serverConfig,
        );
        return;
      }

      // Try to restore session by re-authenticating with stored credentials
      // This ensures we have a valid session with the server
      try {
        final user = await _repository.restoreSession();
        if (user != null) {
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            serverConfig: serverConfig,
          );
          return;
        }
      } catch (e) {
        // Re-auth failed, try using cached data with restored credentials
        final user = await _repository.getCurrentUser();
        if (user != null) {
          await _repository.restoreCredentialsFromStorage();
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            serverConfig: serverConfig,
          );
          return;
        }
      }

      // No valid session
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        serverConfig: serverConfig,
      );
    } catch (e) {
      // On error, still try to use cached data
      try {
        final serverConfig = await _repository.getStoredServerConfig();
        final user = await _repository.getCurrentUser();
        if (user != null && serverConfig != null) {
          await _repository.restoreCredentialsFromStorage();
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            serverConfig: serverConfig,
          );
          return;
        }
      } catch (_) {}

      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // Test connection
  Future<ServerConfig> testConnection(String serverUrl) async {
    return await _repository.testConnection(serverUrl);
  }

  // Get available databases
  Future<List<String>> getDatabases(String serverUrl) async {
    return await _repository.getDatabases(serverUrl);
  }

  // Save server config
  Future<void> saveServerConfig({
    required String serverUrl,
    required String database,
  }) async {
    await _repository.updateServerConfig(
      serverUrl: serverUrl,
      database: database,
    );

    final config = ServerConfig(
      serverUrl: serverUrl,
      database: database,
      isConnected: true,
    );

    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      serverConfig: config,
    );
  }

  // Login
  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final serverConfig = state.serverConfig;
      if (serverConfig == null) {
        state = state.copyWith(
          status: AuthStatus.serverSetupRequired,
          errorMessage: 'Server not configured',
        );
        return;
      }

      final user = await _repository.login(
        serverUrl: serverConfig.serverUrl,
        database: serverConfig.database,
        username: username,
        password: password,
      );

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    await _repository.logout();
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      user: null,
    );
  }

  // Clear all data and reset to server setup
  Future<void> resetApp() async {
    await _repository.clearAllData();
    state = const AuthState(status: AuthStatus.serverSetupRequired);
  }

  // Get current user
  UserModel? get currentUser => state.user;

  // Check role access
  bool hasAccess(String module) {
    final roles = state.user?.roles;
    if (roles == null) return false;

    switch (module) {
      case 'hr':
        return roles.hasHrAccess;
      case 'sales':
        return roles.hasSalesAccess;
      case 'purchase':
        return roles.hasPurchaseAccess;
      case 'project':
        return roles.hasProjectAccess;
      default:
        return false;
    }
  }
}

// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

// Convenience providers
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final userRolesProvider = Provider<UserRoles?>((ref) {
  return ref.watch(authProvider).user?.roles;
});
