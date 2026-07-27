import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/app_remote_config_provider.dart';
import 'shared/services/notification_service.dart';

class ShineGoldApp extends ConsumerStatefulWidget {
  const ShineGoldApp({super.key});

  @override
  ConsumerState<ShineGoldApp> createState() => _ShineGoldAppState();
}

class _ShineGoldAppState extends ConsumerState<ShineGoldApp> {
  @override
  void initState() {
    super.initState();
    // Request after first frame so the Activity is ready for the system dialog.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_requestNotifications());
      unawaited(ref.read(appRemoteConfigProvider.notifier).load());
    });
  }

  Future<void> _requestNotifications() async {
    try {
      await NotificationService.instance.requestPermissionAtStartup();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Shine Gold',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.app,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        // Executives run phones with the system font enlarged. Unclamped, a
        // 1.5-2.0x scale overflows every fixed-height row and grid in the app.
        // 1.3x keeps text meaningfully larger while staying inside the layouts.
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.3,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
