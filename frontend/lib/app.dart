import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/landing_page.dart';
import 'package:kloudshop/providers/theme_provider.dart';
import 'package:kloudshop/services/auth_service.dart';
import 'package:kloudshop/providers/auth_providers.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/dashboard_page.dart';
import 'package:kloudshop/provisioning_page.dart';
import 'package:kloudshop/views/consumer_registration_view.dart';
import 'package:kloudshop/views/consumer_dashboard_view.dart';
import 'package:kloudshop/views/consumer_order_details_view.dart';
import 'package:kloudshop/views/splash_page.dart';
import 'package:kloudshop/views/unblock_verification_page.dart';
import 'package:kloudshop/views/theme_preview_page.dart';

class KloudShopApp extends ConsumerWidget {
  const KloudShopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'KloudShop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const SplashPage(),
      onGenerateRoute: (settings) {
        final uri = Uri.tryParse(settings.name ?? '');
        if (uri != null && (uri.path == '/preview' || uri.path == '/#/preview' || (settings.name ?? '').contains('/preview'))) {
          final queryParams = uri.queryParameters.isNotEmpty 
              ? uri.queryParameters 
              : Uri.parse(settings.name!.replaceFirst('/#', '')).queryParameters;
          final configId = queryParams['configId'];
          if (configId != null) {
            return MaterialPageRoute(
              builder: (context) => ThemePreviewPage(configId: configId),
            );
          }
        }

        if (settings.name == '/storefront/register') {
          final args = settings.arguments as Map<String, String?>?;
          return MaterialPageRoute(
            builder: (context) => ConsumerRegistrationView(
              orderId: args?['order_id'],
              email: args?['email'],
            ),
          );
        }
        if (settings.name == '/storefront/orders/details') {
          final orderId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => ConsumerOrderDetailsView(orderId: orderId),
          );
        }
        return null;
      },
      routes: {
        '/dashboard': (context) => const AuthGate(),
        '/storefront/dashboard': (context) => const ConsumerDashboardView(),
        '/unblock': (context) => const UnblockVerificationPage(),
      },
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Scaffold(
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: SelectableText(
                  'KloudShop Rendering Exception:\n\n$details',
                  style: const TextStyle(
                    color: Colors.red,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          );
        };
        return child!;
      },
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) return const KloudShopLandingPage();

        // If logged in to Firebase, we must check our backend identity
        final claimsState = ref.watch(userClaimsProvider);

        return claimsState.when(
          data: (claims) {
            if (claims == null) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // If the user is authenticated but has no tenant_id, send them to provisioning
            // Platform admins are exempt as they see the global dashboard.
            if (claims.tenantId == null &&
                claims.accountType != 'platform_admin') {
              return ProvisioningPage(email: user.email);
            }

            // SUCCESS: We have a user and they belong to a tenant
            return DashboardPage(claims: claims);
          },
          loading: () => const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Verifying merchant identity...'),
                ],
              ),
            ),
          ),
          error: (e, s) {
            if (e is ApiException && e.statusCode == 403) {
              // Authenticated but no tenant_id found in claims
              return ProvisioningPage(email: user.email);
            }
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text('Backend Error: $e'),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        await ref.read(authServiceProvider).getIdToken(forceRefresh: true);
                        ref.invalidate(userClaimsProvider);
                      },
                      child: const Text('Retry Connection & Sync'),
                    ),
                    TextButton(
                      onPressed: () => ref.read(authServiceProvider).signOut(),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) =>
          Scaffold(body: Center(child: Text('Firebase Error: $e'))),
    );
  }
}
