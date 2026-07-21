import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/enums.dart';
import '../../data/models/user.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/executive/checkin/checkin_screen.dart';
import '../../features/executive/farm_detail/farm_detail_screen.dart';
import '../../features/executive/farms/farm_invitations_screen.dart';
import '../../features/executive/interactions/interaction_form_screen.dart';
import '../../features/executive/interactions/interactions_list_screen.dart';
import '../../features/executive/onboard_farm/farm_boundary_picker_screen.dart';
import '../../features/executive/onboard_farm/onboard_farm_screen.dart';
import '../../features/executive/shell/executive_shell.dart';
import '../../features/super_admin/shell/admin_shell.dart';
import '../../features/visits/presentation/visit_report_screen.dart';
import '../../features/welcome/welcome_screen.dart';
import '../../data/models/interaction.dart';
import '../../shared/models/farm_boundary.dart';
import '../../shared/providers/auth_provider.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRoutes {
  AppRoutes._();

  static const welcome = '/';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const executive = '/executive';
  static const boundaryPicker = '/executive/boundary-picker';
  static const admin = '/admin';
  static const farmDetail = '/farm/:id';
  static const checkin = '/checkin/:farmId';
  static const visitDetail = '/visit/:id';
  static const farmInvitations = '/executive/invitations';
  static const interactions = '/executive/interactions';
  static const interactionNew = '/executive/interactions/new';
  static const interactionEdit = '/executive/interactions/:id';
  static const adminCreateFarm = '/admin/create-farm';
}

/// Notifies [GoRouter] when auth changes without recreating the router instance.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<AsyncValue<AuthSession?>>(authProvider, (_, __) {
      notifyListeners();
    });
  }
}

String? _resolveRedirect(GoRouterState state, AsyncValue<AuthSession?> authState) {
  if (authState.hasError) {
    final loc = state.matchedLocation;
    if (loc == AppRoutes.welcome ||
        loc == AppRoutes.login ||
        loc == AppRoutes.forgotPassword) {
      return null;
    }
    return AppRoutes.login;
  }

  final session = authState.valueOrNull;
  final loc = state.matchedLocation;
  final isAuthRoute =
      loc == AppRoutes.login || loc == AppRoutes.forgotPassword;
  final isWelcome = loc == AppRoutes.welcome;

  if (authState.isLoading && !isWelcome) return AppRoutes.welcome;

  if (session == null) {
    if (loc.startsWith('/executive') ||
        loc.startsWith('/admin') ||
        loc.startsWith('/farm') ||
        loc.startsWith('/checkin') ||
        loc.startsWith('/visit')) {
      return AppRoutes.login;
    }
    return null;
  }

  // Let welcome animation play on every cold start; it navigates itself.
  if (isWelcome) return null;

  if (isAuthRoute) {
    return session.user.role == UserRole.superAdmin
        ? AppRoutes.admin
        : AppRoutes.executive;
  }

  if (loc.startsWith('/executive') &&
      session.user.role == UserRole.superAdmin) {
    if (loc == AppRoutes.boundaryPicker) return null;
    return AppRoutes.admin;
  }

  if (loc.startsWith('/admin') && session.user.role == UserRole.executive) {
    return AppRoutes.executive;
  }

  if (loc == AppRoutes.adminCreateFarm &&
      session.user.role != UserRole.superAdmin) {
    return AppRoutes.executive;
  }

  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefreshNotifier(ref);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.welcome,
    refreshListenable: refresh,
    redirect: (context, state) =>
        _resolveRedirect(state, ref.read(authProvider)),
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.executive,
        builder: (_, __) => const ExecutiveShell(),
        routes: [
          GoRoute(
            path: 'boundary-picker',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, state) {
              final args = state.extra;
              if (args is BoundaryPickerArgs) {
                return FarmBoundaryPickerScreen(
                  initialCenter: args.initialCenter,
                  initialPins: args.initialPins,
                  initialAddress: args.initialAddress,
                  userLocation: args.userLocation,
                );
              }
              return const FarmBoundaryPickerScreen();
            },
          ),
          GoRoute(
            path: 'invitations',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, __) => const FarmInvitationsScreen(),
          ),
          GoRoute(
            path: 'interactions',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, __) => const InteractionsListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                parentNavigatorKey: rootNavigatorKey,
                builder: (_, __) => const InteractionFormScreen(),
              ),
              GoRoute(
                path: ':id',
                parentNavigatorKey: rootNavigatorKey,
                builder: (_, state) {
                  final existing = state.extra;
                  return InteractionFormScreen(
                    existing: existing is FarmerInteraction ? existing : null,
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.adminCreateFarm,
        builder: (_, __) => const OnboardFarmScreen(isAdminCreate: true),
      ),
      GoRoute(
        path: AppRoutes.admin,
        builder: (_, __) => const AdminShell(),
      ),
      GoRoute(
        path: AppRoutes.farmDetail,
        builder: (_, state) => FarmDetailScreen(
          farmId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.checkin,
        builder: (_, state) => CheckinScreen(
          farmId: state.pathParameters['farmId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.visitDetail,
        builder: (_, state) => VisitReportScreen(
          visitId: state.pathParameters['id']!,
        ),
      ),
    ],
  );

  ref.onDispose(() {
    refresh.dispose();
    router.dispose();
  });

  return router;
});
