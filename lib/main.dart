import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'shared/widgets/ux_components.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ensureVoiceAudioContext();
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
