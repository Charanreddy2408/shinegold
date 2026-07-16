import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/network/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../utils/async_ui.dart';
import '../utils/geocoding_service.dart';

/// Address field with live suggestions (via API Nominatim proxy).
///
/// On suggestion pick, fills the address text and optionally notifies
/// with lat/lng + resolved display name / PIN.
class AddressAutocompleteField extends ConsumerStatefulWidget {
  const AddressAutocompleteField({
    super.key,
    required this.controller,
    this.pincodeController,
    this.label = 'Address',
    this.hint = 'Start typing to search address',
    this.icon = Icons.home_work_outlined,
    this.validator,
    this.onSelected,
  });

  final TextEditingController controller;
  final TextEditingController? pincodeController;
  final String label;
  final String? hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final void Function(GeocodingResult result)? onSelected;

  @override
  ConsumerState<AddressAutocompleteField> createState() =>
      _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState
    extends ConsumerState<AddressAutocompleteField> {
  final _debounce = Debouncer(delay: const Duration(milliseconds: 350));
  final _loadGen = LoadGeneration();
  final _focusNode = FocusNode();

  List<GeocodingResult> _suggestions = [];
  bool _searching = false;
  bool _suppressSearch = false;
  String? _searchError;

  GeocodingService get _geo =>
      GeocodingService(dio: ref.read(dioClientProvider).dio);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && mounted) {
        // Keep suggestions briefly so a tap can register before dismiss.
        Future<void>.delayed(const Duration(milliseconds: 180), () {
          if (!mounted || _focusNode.hasFocus) return;
          setState(() {
            _suggestions = [];
            _searchError = null;
          });
        });
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    _debounce.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_suppressSearch) return;
    final query = widget.controller.text.trim();
    if (query.length < 2) {
      _debounce.cancel();
      if (_suggestions.isNotEmpty || _searchError != null || _searching) {
        setState(() {
          _suggestions = [];
          _searchError = null;
          _searching = false;
        });
      }
      return;
    }

    setState(() {
      _searching = true;
      _searchError = null;
    });
    _debounce.run(() => _runSearch(query));
  }

  Future<void> _runSearch(String query) async {
    final gen = _loadGen.next();
    try {
      final results = await _geo.search(query);
      if (!mounted || !_loadGen.isCurrent(gen)) return;
      setState(() {
        _suggestions = results.take(8).toList();
        _searching = false;
        _searchError = results.isEmpty
            ? 'No matching places found. Try area + city names.'
            : null;
      });
    } catch (_) {
      if (!mounted || !_loadGen.isCurrent(gen)) return;
      setState(() {
        _suggestions = [];
        _searching = false;
        _searchError =
            'Could not load address suggestions. Check connection and try again.';
      });
    }
  }

  Future<void> _pick(GeocodingResult result) async {
    _suppressSearch = true;
    widget.onSelected?.call(result);

    widget.controller.text = result.displayName;
    widget.controller.selection = TextSelection.collapsed(
      offset: result.displayName.length,
    );

    final pin = _extractPincode(result.displayName);
    if (pin != null && widget.pincodeController != null) {
      widget.pincodeController!.text = pin;
    }

    setState(() {
      _suggestions = [];
      _searching = false;
      _searchError = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 50));
    _suppressSearch = false;
    _focusNode.unfocus();
  }

  static String? _extractPincode(String displayName) {
    final match = RegExp(r'\b([1-8]\d{5})\b').firstMatch(displayName);
    return match?.group(1);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          validator: widget.validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          textInputAction: TextInputAction.search,
          maxLines: 2,
          onFieldSubmitted: (_) {
            final q = widget.controller.text.trim();
            if (q.length >= 2) _runSearch(q);
          },
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
            prefixIconConstraints:
                const BoxConstraints(minWidth: 56, minHeight: 48),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: 'Search address',
                    icon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () {
                      final q = widget.controller.text.trim();
                      if (q.length >= 2) {
                        setState(() => _searching = true);
                        _runSearch(q);
                      }
                    },
                  ),
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
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: AppColors.error, width: 1.4),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: AppColors.error, width: 1.6),
            ),
            errorStyle: const TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(14),
            color: AppColors.surfaceCard,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _suggestions[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.place_outlined,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                    title: Text(
                      item.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    onTap: () => _pick(item),
                  );
                },
              ),
            ),
          ),
        ] else if (_searchError != null &&
            widget.controller.text.trim().length >= 2 &&
            !_searching) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.errorSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              _searchError!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Convenience: apply suggestion into a home-location draft-like setter.
void applyGeocodeToControllers({
  required GeocodingResult result,
  required TextEditingController address,
  TextEditingController? pincode,
  void Function(double lat, double lng, String label)? onPin,
}) {
  address.text = result.displayName;
  final pinMatch = RegExp(r'\b([1-8]\d{5})\b').firstMatch(result.displayName);
  if (pinMatch != null && pincode != null) {
    pincode.text = pinMatch.group(1)!;
  }
  onPin?.call(result.point.latitude, result.point.longitude, result.displayName);
}

extension GeocodingResultPin on GeocodingResult {
  LatLng get coordinates => point;
}
