import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shine_gold/features/super_admin/more/admin_more_sheet.dart';
import 'package:shine_gold/l10n/app_localizations.dart';
import 'package:shine_gold/shared/providers/locale_provider.dart';
import 'package:shine_gold/shared/widgets/language_picker.dart';

Widget _app(Widget home) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedAppLocales,
      home: home,
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'sheet menu opens the language dialog after the sheet closes',
    (tester) async {
      // Phone-sized window: the sheet's fixed column needs the height.
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => const AdminMoreSheet(),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Change language'));
      await tester.pumpAndSettle();

      expect(find.text('Choose language'), findsOneWidget);
      expect(find.text('తెలుగు'), findsOneWidget);
    },
  );

  testWidgets(
    'change-language tile stays reachable on a short screen with large text',
    (tester) async {
      // Small phone + the 1.3x text scale the app clamps to: the sheet used to
      // overflow here, clipping the last tiles (language + logout) off-screen.
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (_) => const AdminMoreSheet(),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.text('Change language'),
        120,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Change language'));
      await tester.pumpAndSettle();

      expect(find.text('Choose language'), findsOneWidget);
    },
  );

  testWidgets('picking a language in the dialog updates the app locale',
      (tester) async {
    late WidgetRef capturedRef;
    await tester.pumpWidget(
      _app(
        Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showLanguagePicker(context, ref: ref),
                  child: const Text('open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('తెలుగు'));
    await tester.pumpAndSettle();

    expect(capturedRef.read(localeProvider).languageCode, 'te');
  });

  testWidgets('language prompt is re-armed only by a deliberate logout',
      (tester) async {
    expect(await LocaleNotifier.isLanguagePromptDone(), isFalse);

    await LocaleNotifier.markLanguagePromptDone();
    expect(await LocaleNotifier.isLanguagePromptDone(), isTrue);
    expect(LocaleNotifier.languagePromptDoneCached, isTrue);

    await LocaleNotifier.resetLanguagePrompt();
    expect(await LocaleNotifier.isLanguagePromptDone(), isFalse);
    expect(LocaleNotifier.languagePromptDoneCached, isFalse);
  });
}
