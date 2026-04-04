// lib/shared/providers/app_providers.dart
//
// Central barrel for cross-feature providers that don't belong to a single feature.
// Import this file in widgets that need cross-cutting providers (e.g. connectivity,
// current tenant settings, deep-link state).

export '../../core/network/api_client.dart' show apiClientProvider;
export '../../core/services/connectivity_service.dart' show connectivityProvider;
export '../../features/auth/providers/auth_provider.dart'
    show authProvider, AuthState, AuthAuthenticated, AuthUnauthenticated, AuthUser;
