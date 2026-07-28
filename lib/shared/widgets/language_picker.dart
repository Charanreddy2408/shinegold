import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';

/// Post-login and menu language picker for English / Telugu / Kannada.
Future<void> showLanguagePicker(
  BuildContext context, {
  required WidgetRef ref,
  bool markPromptDone = false,
  bool barrierDismissible = true,
}) async {
  final l10n = AppLocalizations.of(context);
  final current = ref.read(localeProvider);

  await showDialog<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.chooseLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.chooseLanguageSubtitle,
              style: Theme.of(dialogContext).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _LanguageOption(
              label: l10n.english,
              selected: current.languageCode == 'en',
              onTap: () => _select(
                dialogContext,
                ref,
                const Locale('en'),
                markPromptDone: markPromptDone,
              ),
            ),
            _LanguageOption(
              label: l10n.telugu,
              selected: current.languageCode == 'te',
              onTap: () => _select(
                dialogContext,
                ref,
                const Locale('te'),
                markPromptDone: markPromptDone,
              ),
            ),
            _LanguageOption(
              label: l10n.kannada,
              selected: current.languageCode == 'kn',
              onTap: () => _select(
                dialogContext,
                ref,
                const Locale('kn'),
                markPromptDone: markPromptDone,
              ),
            ),
          ],
        ),
        actions: [
          if (barrierDismissible)
            TextButton(
              onPressed: () async {
                if (markPromptDone) {
                  await LocaleNotifier.markLanguagePromptDone();
                }
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: Text(l10n.continueLabel),
            ),
        ],
      );
    },
  );
}

Future<void> _select(
  BuildContext context,
  WidgetRef ref,
  Locale locale, {
  required bool markPromptDone,
}) async {
  await ref.read(localeProvider.notifier).setLocale(locale);
  if (markPromptDone) {
    await LocaleNotifier.markLanguagePromptDone();
  }
  if (context.mounted) Navigator.pop(context);
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
          ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
          : const Icon(Icons.circle_outlined),
      onTap: onTap,
    );
  }
}
