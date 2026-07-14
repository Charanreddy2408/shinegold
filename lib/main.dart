import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'shared/services/notification_service.dart';
import 'shared/widgets/ux_components.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await ensureVoiceAudioContext();
  } catch (_) {
    // Audio setup is best-effort; playback will retry later.
  }

  try {
    await NotificationService.instance.initialize();
  } catch (_) {
    // Notifications are best-effort; app should still open.
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: ShineGoldApp(),
    ),
  );
}
