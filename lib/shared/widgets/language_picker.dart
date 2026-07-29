import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';

/// In-app language picker for English / Telugu / Kannada, reached from the
/// admin menu and both profile screens. The first-run choice lives in
/// `LanguageSelectionScreen` instead.
///
/// Deliberately takes no [WidgetRef]: the admin menu opens this from a bottom
/// sheet that pops itself first, and a ref handed over from that sheet is dead
/// by the time anyone taps a language ("Cannot use ref after the widget was
/// disposed"), which silently swallowed every selection. The [Consumer] below
/// gets a live ref from the dialog's own element, and watching the locale
/// there is what moves the tick.
Future<void> showLanguagePicker(
  BuildContext context, {
  bool barrierDismissible = true,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) {
      return Consumer(
        builder: (context, ref, _) {
          // Re-resolved on every rebuild so the dialog itself switches
          // language the moment a new one is picked.
          final l10n = AppLocalizations.of(context);
          final current = ref.watch(localeProvider);

          void select(Locale locale) {
            ref.read(localeProvider.notifier).setLocale(locale);
          }

          return AlertDialog(
            title: Text(l10n.chooseLanguage),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.chooseLanguageSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                _LanguageOption(
                  label: l10n.english,
                  selected: current.languageCode == 'en',
                  onTap: () => select(const Locale('en')),
                ),
                _LanguageOption(
                  label: l10n.telugu,
                  selected: current.languageCode == 'te',
                  onTap: () => select(const Locale('te')),
                ),
                _LanguageOption(
                  label: l10n.kannada,
                  selected: current.languageCode == 'kn',
                  onTap: () => select(const Locale('kn')),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.continueLabel),
              ),
            ],
          );
        },
      );
    },
  );
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: selected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : const Icon(Icons.circle_outlined),
      onTap: onTap,
    );
  }
}
