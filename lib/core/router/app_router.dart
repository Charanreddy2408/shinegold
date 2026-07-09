import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/enums.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/executive/checkin/checkin_screen.dart';
import '../../features/executive/farm_detail/farm_detail_screen.dart';
import '../../features/executive/onboard_farm/farm_boundary_picker_screen.dart';
import '../../features/executive/shell/executive_shell.dart';
import '../../features/super_admin/shell/admin_shell.dart';
import '../../features/welcome/welcome_screen.dart';
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
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.welcome,
    redirect: (context, state) {
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
            loc.startsWith('/checkin')) {
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
        return AppRoutes.admin;
      }

      if (loc.startsWith('/admin') &&
          session.user.role == UserRole.executive) {
        return AppRoutes.executive;
      }

      if (loc.startsWith('/checkin') &&
          session.user.role == UserRole.superAdmin) {
        return AppRoutes.admin;
      }

      return null;
    },
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
                );
              }
              return const FarmBoundaryPickerScreen();
            },
          ),
        ],
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
    ],
  );
});
