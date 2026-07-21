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

    final name = TextEditingController();
    final mobile = TextEditingController();
    final address = TextEditingController();
    final pincode = TextEditingController();
    final password = TextEditingController();
    final homeLocation = _HomeLocationDraft();
    String? assignedEmployeeId;

    final created = await showAdminFormSheet<bool>(
      context: context,
      title: 'Add Executive',
      subtitle:
          'Address + PIN must Locate successfully so home GPS is stored.',
      icon: Icons.person_add_alt_1_rounded,
      submitLabel: 'Create Executive',
      fields: [
        AdminFormField(
          controller: name,
          label: 'Full Name',
          icon: Icons.person_outline_rounded,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Full name is required';
            }
            return null;
          },
        ),
        AdminFormField(
          controller: mobile,
          label: 'Mobile Number',
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          hint: '10-digit mobile',
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Mobile number is required';
            }
            final digits = v.replaceAll(RegExp(r'\D'), '');
            if (digits.length < 10) {
              return 'Enter a valid 10-digit mobile number';
            }
            return null;
          },
        ),
        AddressAutocompleteField(
          controller: address,
          pincodeController: pincode,
          label: 'Address',
          hint: 'Start typing to search address',
          validator: (v) {
            final addressText = v?.trim() ?? '';
            if (addressText.isEmpty) return 'Address is required';
            if (addressText.length < 8) {
              return 'Enter a fuller address (street / area / city)';
            }
            final words = addressText
                .split(RegExp(r'[\s,]+'))
                .where((w) => w.trim().length > 1)
                .toList();
            if (words.length < 2) {
              return 'Include locality and city';
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
          label: 'PIN code',
          icon: Icons.markunread_mailbox_outlined,
          keyboardType: TextInputType.number,
          hint: 'Auto-filled from suggestion when possible',
          validator: (v) {
            final pin = v?.trim() ?? '';
            if (pin.isEmpty) return 'PIN code is required';
            if (pin.length != 6 || int.tryParse(pin) == null) {
              return 'Enter a valid 6-digit PIN';
            }
            final first = int.parse(pin[0]);
            if (first < 1 || first > 8) {
              return 'Enter a valid Indian PIN code';
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
          label: 'Password',
          icon: Icons.lock_outline_rounded,
          obscureText: true,
          hint: 'At least 6 characters',
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Password is required';
            }
            if (v.length < 6) {
              return 'Password must be at least 6 characters';
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
          throw Exception(
            'Address could not be verified on the map. '
            'Improve address/PIN, tap Locate, then create again.',
          );
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
          ? 'Executive created successfully'
          : 'Executive created — ID: $assignedEmployeeId';
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
        title: 'Team',
        subtitle: _loading
            ? 'Loading...'
            : '${filtered.length} of ${_executives.length} executives',
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
                hint: 'Search by name, ID, or mobile...',
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
                            ? 'No executives'
                            : 'No matches',
                        subtitle: _searchController.text.isEmpty
                            ? 'Add your first field executive'
                            : 'Try a different search term',
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
      setState(() => _error = 'Enter an address first');
      return;
    }
    if (widget.requiredPin && pinText.isEmpty) {
      setState(() => _error = 'Enter the 6-digit PIN code first');
      return;
    }
    if (pinText.isNotEmpty &&
        (pinText.length != 6 || int.tryParse(pinText) == null)) {
      setState(() => _error = 'PIN code must be a 6-digit number');
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
          _error =
              'Couldn’t verify this address. Add clearer area/city + correct PIN, then try again.';
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
          return 'Locate & verify address before creating';
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
            Text(
              'Home GPS pin (required)',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap Locate after entering address + PIN. Create stays blocked until the pin is verified.',
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
                draft.isSet ? 'Re-verify address' : 'Locate & verify address',
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
                      'Verified · ${draft.lat!.toStringAsFixed(5)}, ${draft.lng!.toStringAsFixed(5)}',
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
