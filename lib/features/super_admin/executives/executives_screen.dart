import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/animations/staggered_list.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/executive.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/utils/geocoding_service.dart';
import '../../../shared/utils/list_search.dart';
import '../../../shared/widgets/ux_components.dart';
import '../../../shared/widgets/admin_ui.dart';
import '../../../shared/widgets/address_autocomplete_field.dart';
import '../../../shared/widgets/animated_loading.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/shine_empty_state.dart';
import 'admin_executive_profile_screen.dart';
import '../../../shared/utils/l10n_ext.dart';

class ExecutivesScreen extends ConsumerStatefulWidget {
  const ExecutivesScreen({super.key});

  @override
  ConsumerState<ExecutivesScreen> createState() => _ExecutivesScreenState();
}

class _ExecutivesScreenState extends ConsumerState<ExecutivesScreen> {
  final _searchController = TextEditingController();
  List<Executive> _executives = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Executive> get _filtered => _executives.where((exec) {
        return matchesListSearch(_searchController.text, [
          exec.name,
          exec.mobile,
          exec.employeeId,
        ]);
      }).toList();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ref.read(executiveRepositoryProvider).list();
      if (mounted) {
        setState(() {
          _executives = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = formatApiError(e);
        });
      }
    }
  }

  Future<void> _showAddSheet() async {
    ScaffoldMessenger.of(context).clearSnackBars();
    // Captured up front: the submit callback runs after awaits, where reaching
    // back through context would be unsafe.
    final l10n = context.l10n;

    final name = TextEditingController();
    final mobile = TextEditingController();
    final address = TextEditingController();
    final pincode = TextEditingController();
    final password = TextEditingController();
    final homeLocation = _HomeLocationDraft();
    String? assignedEmployeeId;

    final created = await showAdminFormSheet<bool>(
      context: context,
      title: context.l10n.addExecutive,
      subtitle: context.l10n.addressPinLocateInfo,
      icon: Icons.person_add_alt_1_rounded,
      submitLabel: context.l10n.createExecutive,
      fields: [
        AdminFormField(
          controller: name,
          label: context.l10n.fullName,
          icon: Icons.person_outline_rounded,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return context.l10n.fullNameRequired;
            }
            return null;
          },
        ),
        AdminFormField(
          controller: mobile,
          label: context.l10n.mobileNumber,
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          hint: context.l10n.tenDigitMobile,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return context.l10n.mobileNumberRequired;
            }
            final digits = v.replaceAll(RegExp(r'\D'), '');
            if (digits.length < 10) {
              return context.l10n.enterValidMobileNumber;
            }
            return null;
          },
        ),
        AddressAutocompleteField(
          controller: address,
          pincodeController: pincode,
          label: context.l10n.address,
          hint: context.l10n.startTypingToSearch,
          validator: (v) {
            final addressText = v?.trim() ?? '';
            if (addressText.isEmpty) return context.l10n.addressRequired;
            if (addressText.length < 8) {
              return context.l10n.enterFullerAddress;
            }
            final words = addressText
                .split(RegExp(r'[\s,]+'))
                .where((w) => w.trim().length > 1)
                .toList();
            if (words.length < 2) {
              return context.l10n.includeLocalityCity;
            }
            return null;
          },
          onSelected: (result) {
            homeLocation.applySuggestion(
              lat: result.point.latitude,
              lng: result.point.longitude,
              label: result.displayName,
            );
          },
        ),
        AdminFormField(
          controller: pincode,
          label: context.l10n.pincode,
          icon: Icons.markunread_mailbox_outlined,
          keyboardType: TextInputType.number,
          hint: context.l10n.autoFilledFromSuggestion,
          validator: (v) {
            final pin = v?.trim() ?? '';
            if (pin.isEmpty) return context.l10n.pinCodeRequired;
            if (pin.length != 6 || int.tryParse(pin) == null) {
              return context.l10n.enterValid6DigitPin;
            }
            final first = int.parse(pin[0]);
            if (first < 1 || first > 8) {
              return context.l10n.enterValidIndianPin;
            }
            return null;
          },
        ),
        _ExecutiveHomeLocationField(
          draft: homeLocation,
          address: address,
          pincode: pincode,
          requiredPin: true,
          geo: GeocodingService(dio: ref.read(dioClientProvider).dio),
        ),
        AdminFormField(
          controller: password,
          label: context.l10n.password,
          icon: Icons.lock_outline_rounded,
          obscureText: true,
          hint: context.l10n.atLeast6Characters,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return context.l10n.passwordRequired;
            }
            if (v.length < 6) {
              return context.l10n.passwordMustBe6Chars;
            }
            return null;
          },
        ),
      ],
      onSubmit: () async {
        final nameText = name.text.trim();
        final mobileText = mobile.text.trim();
        final addressText = address.text.trim();
        final pinText = pincode.text.trim();
        final passwordText = password.text;

        final digits = mobileText.replaceAll(RegExp(r'\D'), '');
        final normalizedMobile =
            digits.length > 10 ? digits.substring(digits.length - 10) : digits;

        // Must resolve a real GPS pin before create — no empty lat/lng.
        if (!homeLocation.isSet) {
          await homeLocation.resolveFromAddress(
            address: addressText,
            pincode: pinText,
            geo: GeocodingService(dio: ref.read(dioClientProvider).dio),
          );
        }
        if (!homeLocation.isSet) {
          throw Exception(l10n.addressCouldNotVerify);
        }

        final fullAddress = '$addressText, $pinText';

        final exec = await ref.read(executiveRepositoryProvider).create(
              CreateExecutiveRequest(
                name: nameText,
                mobile: normalizedMobile,
                password: passwordText,
                address: fullAddress,
                homeLat: homeLocation.lat,
                homeLng: homeLocation.lng,
              ),
            );
        assignedEmployeeId = exec.employeeId;
      },
    );

    disposeSheetControllers([name, mobile, address, pincode, password]);

    if (created == true && mounted) {
      await _load();
      if (!mounted) return;
      final idNote = assignedEmployeeId == null || assignedEmployeeId!.isEmpty
          ? l10n.executiveCreated
          : l10n.executiveCreatedWithId(assignedEmployeeId!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(idNote)),
      );
    }
  }

  Future<void> _openProfile(Executive exec) async {
    await Navigator.of(context).push(
      adminPageRoute(AdminExecutiveProfileScreen(executive: exec)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return AppBackground(
      header: GradientHeader(
        title: context.l10n.navTeam,
        subtitle: _loading
            ? context.l10n.loading
            : context.l10n.xOfYExecutives(filtered.length, _executives.length),
        compact: true,
        trailing: IconButton.filled(
          onPressed: _showAddSheet,
          icon: const Icon(Icons.person_add_rounded),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      child: Column(
        children: [
          if (!_loading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: ShineSearchBar(
                controller: _searchController,
                hint: context.l10n.searchByNameIdMobile,
                onChanged: (_) => setState(() {}),
              ),
            ),
          Expanded(
            child: _loading
                ? const ListLoadingSkeleton(itemCount: 5, itemHeight: 88)
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: FriendlyErrorBanner(
                            message: _error!,
                            onRetry: _load,
                          ),
                        ),
                      )
                : filtered.isEmpty
                    ? ShineEmptyState(
                        icon: Icons.search_off_rounded,
                        title: _searchController.text.isEmpty
                            ? context.l10n.noExecutives
                            : context.l10n.noMatches,
                        subtitle: _searchController.text.isEmpty
                            ? context.l10n.addFirstExecutive
                            : context.l10n.tryDifferentSearch,
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          addAutomaticKeepAlives: false,
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final exec = filtered[index];
                            return StaggeredListItem(
                              key: ValueKey(exec.id),
                              index: index,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: AdminTeamTile(
                                  name: exec.name,
                                  subtitle: exec.mobile,
                                  photoUrl: exec.profilePhotoUrl ?? '',
                                  status: exec.status,
                                  visitCount: exec.totalVisits,
                                  onboardedFarmsCount: exec.onboardedFarmsCount,
                                  onboardedAcres: exec.onboardedAcresTotal,
                                  mobile: exec.mobile,
                                  contactName: exec.name,
                                  onTap: () => _openProfile(exec),
                                  onLongPress: () async {
                                    await ref
                                        .read(executiveRepositoryProvider)
                                        .toggleBlock(exec.id);
                                    _load();
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

/// Holds the resolved home GPS pin for create-executive.
class _HomeLocationDraft extends ChangeNotifier {
  double? lat;
  double? lng;
  String? label;
  bool _suppressClear = false;

  bool get isSet => lat != null && lng != null;

  void applySuggestion({
    required double lat,
    required double lng,
    required String label,
  }) {
    _suppressClear = true;
    this.lat = lat;
    this.lng = lng;
    this.label = label;
    notifyListeners();
    Future<void>.delayed(const Duration(milliseconds: 80), () {
      _suppressClear = false;
    });
  }

  void clearPin() {
    if (_suppressClear) return;
    if (lat == null && lng == null && label == null) return;
    lat = null;
    lng = null;
    label = null;
    notifyListeners();
  }

  Future<void> resolveFromAddress({
    required String address,
    required String pincode,
    GeocodingService? geo,
  }) async {
    final geocoder = geo ?? GeocodingService();
    final queries = <String>[];

    void addQuery(String q) {
      final trimmed = q.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (trimmed.length >= 2 && !queries.contains(trimmed)) {
        queries.add(trimmed);
      }
    }

    addQuery([
      if (address.isNotEmpty) address,
      if (pincode.isNotEmpty) pincode,
      'India',
    ].join(', '));

    if (pincode.length == 6) {
      addQuery('$pincode, India');
    }

    // Drop plot/house numbers so Nominatim can match landmarks / area names.
    final withoutPlot = address
        .replaceAll(
          RegExp(r'\b(plot|house|flat|door|no\.?|#)\s*\d+\b', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
    if (withoutPlot.isNotEmpty && withoutPlot != address) {
      addQuery([
        withoutPlot,
        if (pincode.isNotEmpty) pincode,
        'India',
      ].join(', '));
    }

    // Last two comma/space chunks often carry area + city.
    final parts = address
        .split(RegExp(r'[,\-]'))
        .map((p) => p.trim())
        .where((p) => p.length > 2)
        .toList();
    if (parts.length >= 2) {
      addQuery('${parts.sublist(parts.length - 2).join(', ')}, India');
    } else if (parts.length == 1) {
      addQuery('${parts.first}, India');
    }

    for (final query in queries) {
      final results = await geocoder.search(query);
      if (results.isEmpty) continue;
      final best = results.first;
      lat = best.point.latitude;
      lng = best.point.longitude;
      label = best.displayName;
      notifyListeners();
      return;
    }

    lat = null;
    lng = null;
    label = null;
    notifyListeners();
  }
}

class _ExecutiveHomeLocationField extends StatefulWidget {
  const _ExecutiveHomeLocationField({
    required this.draft,
    required this.address,
    required this.pincode,
    required this.geo,
    this.requiredPin = false,
  });

  final _HomeLocationDraft draft;
  final TextEditingController address;
  final TextEditingController pincode;
  final GeocodingService geo;
  final bool requiredPin;

  @override
  State<_ExecutiveHomeLocationField> createState() =>
      _ExecutiveHomeLocationFieldState();
}

class _ExecutiveHomeLocationFieldState
    extends State<_ExecutiveHomeLocationField> {
  bool _locating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.address.addListener(_onAddressChanged);
    widget.pincode.addListener(_onAddressChanged);
    widget.draft.addListener(_onDraftChanged);
  }

  @override
  void dispose() {
    widget.address.removeListener(_onAddressChanged);
    widget.pincode.removeListener(_onAddressChanged);
    widget.draft.removeListener(_onDraftChanged);
    super.dispose();
  }

  void _onDraftChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onAddressChanged() {
    widget.draft.clearPin();
  }

  Future<void> _locate() async {
    final addressText = widget.address.text.trim();
    final pinText = widget.pincode.text.trim();
    if (addressText.isEmpty) {
      setState(() => _error = context.l10n.enterAddressFirst);
      return;
    }
    if (widget.requiredPin && pinText.isEmpty) {
      setState(() => _error = context.l10n.enterPinFirst);
      return;
    }
    if (pinText.isNotEmpty &&
        (pinText.length != 6 || int.tryParse(pinText) == null)) {
      setState(() => _error = context.l10n.pinMustBe6Digits);
      return;
    }
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      await widget.draft.resolveFromAddress(
        address: addressText,
        pincode: pinText,
        geo: widget.geo,
      );
      if (!mounted) return;
      if (!widget.draft.isSet) {
        setState(() {
          _error = context.l10n.couldNotVerifyAddress;
          _locating = false;
        });
        return;
      }
      setState(() => _locating = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = formatApiError(e);
        _locating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    return FormField<bool>(
      initialValue: draft.isSet,
      validator: (_) {
        if (!widget.draft.isSet) {
          return context.l10n.locateBeforeCreating;
        }
        return null;
      },
      builder: (field) {
        // Keep FormField in sync when Locate succeeds / address edits clear pin.
        if (field.value != draft.isSet) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) field.didChange(draft.isSet);
          });
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.homeGpsPinRequired,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
            ),
            SizedBox(height: 4),
            Text(context.l10n.tapLocateAfterAddress,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _locating ? null : _locate,
              icon: _locating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded),
              label: Text(
                draft.isSet
                    ? context.l10n.reVerifyAddress
                    : context.l10n.locateAndVerifyAddress,
              ),
            ),
            if (draft.isSet) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondaryMuted.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${context.l10n.verified} · '
                      '${draft.lat!.toStringAsFixed(5)}, '
                      '${draft.lng!.toStringAsFixed(5)}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          ),
                    ),
                    if (draft.label != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        draft.label!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
            if (field.hasError) ...[
              const SizedBox(height: 8),
              Text(
                field.errorText!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ],
        );
      },
    );
  }
}
