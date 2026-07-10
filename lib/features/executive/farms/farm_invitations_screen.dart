import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/animations/staggered_list.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/visit_form.dart';
import '../../../shared/providers/location_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/widgets/animated_loading.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/shine_buttons.dart';
import '../../../shared/widgets/shine_empty_state.dart';
import '../../../shared/widgets/ux_components.dart';

class FarmInvitationsScreen extends ConsumerStatefulWidget {
  const FarmInvitationsScreen({super.key});

  @override
  ConsumerState<FarmInvitationsScreen> createState() =>
      _FarmInvitationsScreenState();
}

class _FarmInvitationsScreenState extends ConsumerState<FarmInvitationsScreen> {
  List<FarmInvitation> _invitations = [];
  bool _loading = true;
  String? _error;
  String? _acceptingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationProvider.notifier).requestLocation();
      _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final loc = ref.read(locationProvider);
      final items = await ref.read(farmRepositoryProvider).getFarmInvitations(
            lat: loc.position?.latitude,
            lng: loc.position?.longitude,
          );
      if (mounted) {
        setState(() {
          _invitations = items;
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

  Future<void> _accept(FarmInvitation invitation) async {
    setState(() => _acceptingId = invitation.id);
    try {
      await ref
          .read(farmRepositoryProvider)
          .acceptFarmInvitation(invitation.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${invitation.name} added to your farms'),
          backgroundColor: AppColors.secondary,
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(formatApiError(e))),
      );
    } finally {
      if (mounted) setState(() => _acceptingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasDeep,
      body: AppBackground(
        header: GradientHeader(
          title: 'Nearby Farms',
          subtitle: _loading
              ? 'Loading...'
              : '${_invitations.length} unassigned farms within 70 km',
          compact: true,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
        ),
        child: Column(
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: FriendlyErrorBanner(message: _error!, onRetry: _load),
              ),
            Expanded(
              child: _loading
                  ? const ListLoadingSkeleton()
                  : _invitations.isEmpty
                      ? ShineEmptyState(
                          icon: Icons.explore_off_rounded,
                          title: 'No nearby invitations',
                          subtitle:
                              'Unassigned farms within 70 km of your home location will appear here. Set your home location in Profile if needed.',
                          action: ShineSecondaryButton(
                            label: 'Refresh',
                            onPressed: _load,
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.primary,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.all(16),
                            itemCount: _invitations.length,
                            itemBuilder: (context, index) {
                              final item = _invitations[index];
                              return StaggeredListItem(
                                index: index,
                                child: _InvitationCard(
                                  invitation: item,
                                  accepting: _acceptingId == item.id,
                                  onAccept: () => _accept(item),
                                  onTap: () => context.push(
                                    AppRoutes.farmDetail.replaceFirst(
                                      ':id',
                                      item.id,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({
    required this.invitation,
    required this.accepting,
    required this.onAccept,
    required this.onTap,
  });

  final FarmInvitation invitation;
  final bool accepting;
  final VoidCallback onAccept;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppColors.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invitation.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                if (invitation.locationAddress != null)
                  Text(
                    invitation.locationAddress!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (invitation.farmerName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Farmer: ${invitation.farmerName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
                if (invitation.distanceKm != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.near_me_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${invitation.distanceKm!.toStringAsFixed(1)} km away',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          ShinePrimaryButton(
            label: 'Accept Assignment',
            isLoading: accepting,
            icon: Icons.check_rounded,
            onPressed: accepting ? null : onAccept,
          ),
        ],
      ),
    );
  }
}
