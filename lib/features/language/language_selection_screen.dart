import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/enums.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/locale_provider.dart';
import '../../shared/utils/l10n_ext.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/shine_buttons.dart';
import '../../shared/widgets/shine_logo.dart';

/// First-run language screen, shown once after a sign-in until the user
/// confirms. Deliberate logout re-arms it; a cold start with a live session
/// does not.
class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen> {
  bool _saving = false;

  Future<void> _select(Locale locale) async {
    // Apply immediately so the screen itself previews the choice.
    await ref.read(localeProvider.notifier).setLocale(locale);
  }

  Future<void> _continue() async {
    if (_saving) return;
    setState(() => _saving = true);
    await LocaleNotifier.markLanguagePromptDone();
    if (!mounted) return;
    final role = ref.read(userRoleProvider);
    context.go(
      role == UserRole.superAdmin ? AppRoutes.admin : AppRoutes.executive,
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(localeProvider);

    return PopScope(
      // Nothing to go back to — the choice has to be made to move on.
      canPop: false,
      child: Scaffold(
        body: AppBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: AppSpacing.xl),
                  const Center(child: ShineLogo(size: 96))
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .scale(begin: const Offset(0.9, 0.9)),
                  SizedBox(height: AppSpacing.xxl),
                  Text(
                    context.l10n.chooseLanguage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                  ).animate().fadeIn(delay: 80.ms, duration: 400.ms),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    context.l10n.chooseLanguageScreenSubtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                  ).animate().fadeIn(delay: 140.ms, duration: 400.ms),
                  SizedBox(height: AppSpacing.xxl),
                  _LanguageCard(
                    label: context.l10n.english,
                    nativeLabel: 'English',
                    selected: current.languageCode == 'en',
                    delay: 200.ms,
                    onTap: () => _select(const Locale('en')),
                  ),
                  SizedBox(height: AppSpacing.md),
                  _LanguageCard(
                    label: context.l10n.telugu,
                    nativeLabel: 'Telugu',
                    selected: current.languageCode == 'te',
                    delay: 260.ms,
                    onTap: () => _select(const Locale('te')),
                  ),
                  SizedBox(height: AppSpacing.md),
                  _LanguageCard(
                    label: context.l10n.kannada,
                    nativeLabel: 'Kannada',
                    selected: current.languageCode == 'kn',
                    delay: 320.ms,
                    onTap: () => _select(const Locale('kn')),
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  ShinePrimaryButton(
                    label: context.l10n.continueLabel,
                    isLoading: _saving,
                    onPressed: _saving ? null : _continue,
                  ).animate().fadeIn(delay: 380.ms, duration: 400.ms),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    context.l10n.changeLanguageLaterHint,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                  SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.label,
    required this.nativeLabel,
    required this.selected,
    required this.delay,
    required this.onTap,
  });

  final String label;
  final String nativeLabel;
  final bool selected;
  final Duration delay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primarySoft.withValues(alpha: 0.55)
                : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.borderSubtle,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? AppColors.primaryDark
                                : AppColors.textPrimary,
                          ),
                    ),
                    Text(
                      nativeLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? AppColors.primary : AppColors.borderSubtle,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay, duration: 380.ms).slideY(
          begin: 0.08,
          end: 0,
          delay: delay,
          duration: 380.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
