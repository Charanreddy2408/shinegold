import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/animations/staggered_list.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/executive.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/utils/list_search.dart';
import '../../../shared/widgets/ux_components.dart';
import '../../../shared/widgets/admin_ui.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/gold_shimmer.dart';
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
    _searchController.addListener(() => setState(() {}));
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
    final empId = TextEditingController();
    final name = TextEditingController();
    final mobile = TextEditingController();
    final address = TextEditingController();
    final password = TextEditingController();

    final created = await showAdminFormSheet<bool>(
      context: context,
      title: 'Add Executive',
      subtitle: 'Onboard a new field team member',
      icon: Icons.person_add_alt_1_rounded,
      submitLabel: 'Create Executive',
      fields: [
        AdminFormField(
          controller: empId,
          label: 'Employee ID',
          icon: Icons.badge_outlined,
          hint: 'e.g. EMP004',
        ),
        AdminFormField(
          controller: name,
          label: 'Full Name',
          icon: Icons.person_outline_rounded,
        ),
        AdminFormField(
          controller: mobile,
          label: 'Mobile Number',
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          hint: '+91 XXXXX XXXXX',
        ),
        AdminFormField(
          controller: address,
          label: 'Address',
          icon: Icons.location_on_outlined,
          hint: 'Work / home address',
        ),
        AdminFormField(
          controller: password,
          label: 'Password',
          icon: Icons.lock_outline_rounded,
          obscureText: true,
        ),
      ],
      onSubmit: () async {
        await ref.read(executiveRepositoryProvider).create(
              CreateExecutiveRequest(
                employeeId: empId.text.trim(),
                name: name.text.trim(),
                mobile: mobile.text.trim(),
                password: password.text,
                address: address.text.trim().isEmpty
                    ? 'Not provided'
                    : address.text.trim(),
              ),
            );
      },
    );

    empId.dispose();
    name.dispose();
    mobile.dispose();
    address.dispose();
    password.dispose();

    if (created == true && mounted) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Executive created successfully')),
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
              ),
            ),
          Expanded(
            child: _loading
                ? ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 4,
                    itemBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: ShimmerBox(height: 88),
                    ),
                  )
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
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final exec = filtered[index];
                            final photo = exec.profilePhotoUrl ??
                                'https://i.pravatar.cc/150?u=${exec.employeeId}';
                            return StaggeredListItem(
                              index: index,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: AdminTeamTile(
                                  name: exec.name,
                                  subtitle: exec.mobile,
                                  photoUrl: photo,
                                  status: exec.status,
                                  visitCount: exec.totalVisits,
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
