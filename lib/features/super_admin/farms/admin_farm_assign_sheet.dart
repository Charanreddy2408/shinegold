import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/executive.dart';
import '../../../data/models/farm.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/animated_loading.dart';
import '../../../shared/widgets/shine_buttons.dart';

Future<bool?> showAdminFarmAssignSheet(
  BuildContext context,
  WidgetRef ref,
  Farm farm,
) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _AdminFarmAssignSheet(farm: farm),
  );
}

class _AdminFarmAssignSheet extends ConsumerStatefulWidget {
  const _AdminFarmAssignSheet({required this.farm});

  final Farm farm;

  @override
  ConsumerState<_AdminFarmAssignSheet> createState() =>
      _AdminFarmAssignSheetState();
}

class _AdminFarmAssignSheetState extends ConsumerState<_AdminFarmAssignSheet> {
  List<Executive> _executives = [];
  final Set<String> _selected = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.farm.assignedExecutives.map((e) => e.id));
    _load();
  }

  Future<void> _load() async {
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

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(farmRepositoryProvider).assignFarmExecutives(
            widget.farm.id,
            executiveIds: _selected.toList(),
            mode: 'replace',
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = formatApiError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Assign Executives',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.farm.name,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
              ),
            ),
          if (_loading)
            const SizedBox(
              height: 160,
              child: ListLoadingSkeleton(itemCount: 2, itemHeight: 56),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _executives.map((exec) {
                    final selected = _selected.contains(exec.id);
                    return FilterChip(
                      label: Text(exec.name),
                      selected: selected,
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            _selected.add(exec.id);
                          } else {
                            _selected.remove(exec.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 16),
          ShinePrimaryButton(
            label: 'Save Assignment',
            isLoading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
