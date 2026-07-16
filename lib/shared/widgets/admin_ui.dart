import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import 'shine_buttons.dart';

/// Slide-up form sheet with gradient header — replaces plain AlertDialogs.
///
/// Validation / API errors stay inside the sheet (field messages + sticky
/// banner). Never shows a SnackBar on the screen behind the modal.
Future<T?> showAdminFormSheet<T>({
  required BuildContext context,
  required String title,
  required String subtitle,
  required IconData icon,
  required List<Widget> fields,
  required String submitLabel,
  required Future<void> Function() onSubmit,
}) {
  // Clear any leftover snackbars from the parent Team / shell scaffold so
  // they cannot sit under / above the modal.
  ScaffoldMessenger.maybeOf(context)?.clearSnackBars();

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) {
      // Local messenger so accidental SnackBars stay off the Team list.
      // Align bottom — a full-screen Scaffold body otherwise parks the
      // DraggableScrollableSheet at the top (under the status bar).
      return ScaffoldMessenger(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: true,
          body: Align(
            alignment: Alignment.bottomCenter,
            child: _AdminFormSheet(
              title: title,
              subtitle: subtitle,
              icon: icon,
              fields: fields,
              submitLabel: submitLabel,
              onSubmit: onSubmit,
            ),
          ),
        ),
      );
    },
  );
}

/// Dispose text controllers after the bottom sheet has finished unmounting.
/// Calling [TextEditingController.dispose] immediately causes rebuild crashes
/// while the sheet / keyboard is still animating closed.
void disposeSheetControllers(Iterable<TextEditingController> controllers) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      for (final controller in controllers) {
        controller.dispose();
      }
    });
  });
}

class _AdminFormSheet extends StatefulWidget {
  const _AdminFormSheet({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.fields,
    required this.submitLabel,
    required this.onSubmit,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> fields;
  final String submitLabel;
  final Future<void> Function() onSubmit;

  @override
  State<_AdminFormSheet> createState() => _AdminFormSheetState();
}

class _AdminFormSheetState extends State<_AdminFormSheet> {
  bool _submitting = false;
  String? _error;
  bool _attemptedSubmit = false;
  final _formKey = GlobalKey<FormState>();
  ScrollController? _scrollController;

  Future<void> _handleSubmit() async {
    if (_submitting) return;
    FocusManager.instance.primaryFocus?.unfocus();
    // Never leak toast onto Team while validating / submitting.
    ScaffoldMessenger.maybeOf(context)?.clearSnackBars();

    setState(() => _attemptedSubmit = true);

    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      setState(() => _error = 'Please fix the highlighted fields above');
      if (_scrollController != null && _scrollController!.hasClients) {
        _scrollController!.animateTo(
          0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.onSubmit();
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      // In-sheet banner only — never SnackBar (that paints on Team behind).
      setState(() {
        _submitting = false;
        _error = formatApiError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    // Cap sheet height so the rounded top stays below the status bar.
    final maxHeight = (screenHeight * 0.88).clamp(360.0, screenHeight - 48);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: DraggableScrollableSheet(
          initialChildSize: 1,
          minChildSize: 0.72,
          maxChildSize: 1,
          expand: false,
          builder: (_, scrollController) {
            _scrollController = scrollController;
            return Material(
              color: AppColors.surfaceCard,
              elevation: 12,
              shadowColor: AppColors.shadowGold,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientHeader,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadowGold,
                          blurRadius: 14,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            widget.icon,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.white
                                          .withValues(alpha: 0.88),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _attemptedSubmit
                          ? AutovalidateMode.always
                          : AutovalidateMode.onUserInteraction,
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        children: [
                          for (final field in widget.fields)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: field,
                            ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Column(
                        children: [
                          ShinePrimaryButton(
                            label: widget.submitLabel,
                            icon: Icons.check_rounded,
                            isLoading: _submitting,
                            onPressed: _submitting ? null : _handleSubmit,
                          ),
                          const SizedBox(height: 8),
                          ShineSecondaryButton(
                            label: 'Cancel',
                            onPressed: _submitting
                                ? null
                                : () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Polished admin form field with icon and filled style.
/// When [obscureText] is true, shows a visibility eye toggle.
class AdminFormField extends StatefulWidget {
  const AdminFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.hint,
    this.validator,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;

  @override
  State<AdminFormField> createState() => _AdminFormFieldState();
}

class _AdminFormFieldState extends State<AdminFormField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  void didUpdateWidget(covariant AdminFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText && widget.obscureText) {
      _obscured = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.obscureText && _obscured,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        errorMaxLines: 3,
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(widget.icon, color: AppColors.primaryDark, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 56, minHeight: 48),
        suffixIcon: widget.obscureText
            ? IconButton(
                tooltip: _obscured ? 'Show password' : 'Hide password',
                icon: Icon(
                  _obscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textMuted,
                ),
                onPressed: () => setState(() => _obscured = !_obscured),
              )
            : null,
        filled: true,
        fillColor: AppColors.canvasDeep,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.6),
        ),
        errorStyle: const TextStyle(
          color: AppColors.error,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

/// Animated team member row for admin lists.
class AdminTeamTile extends StatefulWidget {
  const AdminTeamTile({
    super.key,
    required this.name,
    required this.subtitle,
    required this.photoUrl,
    required this.status,
    required this.onTap,
    this.onLongPress,
    this.visitCount,
  });

  final String name;
  final String subtitle;
  final String photoUrl;
  final dynamic status;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final int? visitCount;

  @override
  State<AdminTeamTile> createState() => _AdminTeamTileState();
}

class _AdminTeamTileState extends State<AdminTeamTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _pressed
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : AppColors.borderSubtle,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight.withValues(
                  alpha: _pressed ? 0.04 : 0.08,
                ),
                blurRadius: _pressed ? 8 : 16,
                offset: Offset(0, _pressed ? 2 : 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    width: 2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowGold,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundImage: NetworkImage(widget.photoUrl),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    if (widget.visitCount != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.route_rounded,
                            size: 13,
                            color: AppColors.secondary.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.visitCount} visits logged',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              _StatusDot(status: widget.status),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.canvasDeep,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final dynamic status;

  @override
  Widget build(BuildContext context) {
    final isBlocked = status.toString().contains('blocked');
    final color = isBlocked ? AppColors.error : AppColors.secondary;
    final label = isBlocked ? 'Blocked' : 'Active';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Polished menu tile for admin More sheet.
class AdminMenuTile extends StatefulWidget {
  const AdminMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.delay = Duration.zero,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final Duration delay;

  @override
  State<AdminMenuTile> createState() => _AdminMenuTileState();
}

class _AdminMenuTileState extends State<AdminMenuTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.color.withValues(alpha: 0.2),
                        widget.color.withValues(alpha: 0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        widget.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: widget.color.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: widget.delay, duration: 350.ms)
        .slideX(
          begin: 0.06,
          end: 0,
          delay: widget.delay,
          curve: Curves.easeOutCubic,
        );
  }
}

/// Custom page route with slide + fade for admin detail screens.
Route<T> adminPageRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Harvest timeline row — not a card box.
class AdminHarvestRow extends StatelessWidget {
  const AdminHarvestRow({
    super.key,
    required this.farmName,
    required this.crop,
    required this.harvestType,
    required this.isLast,
    this.delay = Duration.zero,
  });

  final String farmName;
  final String crop;
  final String harvestType;
  final bool isLast;
  /// Kept for call-site compatibility; entrance animation lives in list parents.
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.secondary.withValues(alpha: 0.5),
                            AppColors.borderSubtle,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.secondary.withValues(alpha: 0.18),
                            AppColors.secondary.withValues(alpha: 0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.spa_rounded,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            farmName,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$crop · $harvestType',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rich contact hub for admin profile — grid tiles with actions.
class AdminContactHub extends StatelessWidget {
  const AdminContactHub({
    super.key,
    required this.mobile,
    required this.address,
    required this.employeeId,
  });

  final String mobile;
  final String address;
  final String employeeId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                gradient: AppColors.gradientBrand,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Contact & Identity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        )
            .animate()
            .fadeIn(duration: 350.ms)
            .slideX(begin: -0.04, end: 0),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _ContactTile(
                icon: Icons.phone_in_talk_rounded,
                label: 'Mobile',
                value: mobile,
                color: AppColors.info,
                actionIcon: Icons.content_copy_rounded,
                actionHint: 'Copy number',
                delay: 80.ms,
                onTap: () => _copy(context, mobile, 'Phone number copied'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ContactTile(
                icon: Icons.badge_rounded,
                label: 'Employee ID',
                value: employeeId,
                color: AppColors.primary,
                actionIcon: Icons.content_copy_rounded,
                actionHint: 'Copy ID',
                delay: 140.ms,
                onTap: () => _copy(context, employeeId, 'Employee ID copied'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ContactTile(
          icon: Icons.location_on_rounded,
          label: 'Office Address',
          value: address,
          color: AppColors.secondary,
          actionIcon: Icons.map_rounded,
          actionHint: 'Headquarters',
          delay: 200.ms,
          fullWidth: true,
          onTap: () => _copy(context, address, 'Address copied'),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.08),
                AppColors.secondary.withValues(alpha: 0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: AppColors.primaryDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verified Administrator',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Full access to farms, team & harvest data',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 260.ms, duration: 400.ms)
            .slideY(begin: 0.06, end: 0),
      ],
    );
  }

  void _copy(BuildContext context, String text, String message) {
    if (text == '—') return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.textPrimary,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _ContactTile extends StatefulWidget {
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.actionIcon,
    required this.actionHint,
    required this.delay,
    required this.onTap,
    this.fullWidth = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final IconData actionIcon;
  final String actionHint;
  final Duration delay;
  final VoidCallback onTap;
  final bool fullWidth;

  @override
  State<_ContactTile> createState() => _ContactTileState();
}

class _ContactTileState extends State<_ContactTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _pressed
                  ? widget.color.withValues(alpha: 0.45)
                  : AppColors.borderSubtle,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _pressed ? 0.06 : 0.1),
                blurRadius: _pressed ? 8 : 16,
                offset: Offset(0, _pressed ? 2 : 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.color.withValues(alpha: 0.22),
                          widget.color.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 20),
                  ),
                  const Spacer(),
                  Tooltip(
                    message: widget.actionHint,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.actionIcon,
                        size: 14,
                        color: widget.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                widget.label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      fontSize: 10,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                maxLines: widget.fullWidth ? 3 : 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                widget.actionHint,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: widget.color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: widget.delay, duration: 380.ms)
        .slideY(begin: 0.08, end: 0, delay: widget.delay, curve: Curves.easeOutCubic);
  }
}
