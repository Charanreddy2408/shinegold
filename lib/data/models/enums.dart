enum UserRole { executive, superAdmin }

enum FarmVisitStatus { pending, ongoing, visited, harvested, blocked }

enum VisitStatus { ongoing, completed, cancelled }

enum ExecutiveStatus { active, blocked }

enum HarvestStatus { upcoming, inProgress, completed }

enum SortOrder { nearbyToFarthest, farthestToNearby, nameAsc }

enum DashboardFilter { all, visits, onboarded }

enum Gender { male, female, other }

enum FarmHealthStatus { healthy, needsWater, needsAttention, critical, urgentVisit }

enum SyncStatus { synced, pendingSync, syncFailed }

enum QuickFarmFilter {
  all,
  nearby,
  pending,
  harvestSoon,
  recentlyVisited,
  completed,
}

extension FarmHealthStatusUi on FarmHealthStatus {
  String get label {
    switch (this) {
      case FarmHealthStatus.healthy:
        return 'Healthy';
      case FarmHealthStatus.needsWater:
        return 'Needs Water';
      case FarmHealthStatus.needsAttention:
        return 'Needs Attention';
      case FarmHealthStatus.critical:
        return 'Critical';
      case FarmHealthStatus.urgentVisit:
        return 'Urgent Visit';
    }
  }

  String get emoji {
    switch (this) {
      case FarmHealthStatus.healthy:
        return '🟢';
      case FarmHealthStatus.needsWater:
        return '🟡';
      case FarmHealthStatus.needsAttention:
        return '🟠';
      case FarmHealthStatus.critical:
        return '🔴';
      case FarmHealthStatus.urgentVisit:
        return '🔴';
    }
  }
}

extension SyncStatusUi on SyncStatus {
  String get label {
    switch (this) {
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.pendingSync:
        return 'Pending Sync';
      case SyncStatus.syncFailed:
        return 'Sync Failed';
    }
  }

  String get emoji {
    switch (this) {
      case SyncStatus.synced:
        return '🟢';
      case SyncStatus.pendingSync:
        return '🟡';
      case SyncStatus.syncFailed:
        return '🔴';
    }
  }
}

extension QuickFarmFilterLabel on QuickFarmFilter {
  String get label {
    switch (this) {
      case QuickFarmFilter.all:
        return 'All';
      case QuickFarmFilter.nearby:
        return 'Nearby';
      case QuickFarmFilter.pending:
        return 'Pending';
      case QuickFarmFilter.harvestSoon:
        return 'Harvest Soon';
      case QuickFarmFilter.recentlyVisited:
        return 'Recently Visited';
      case QuickFarmFilter.completed:
        return 'Completed';
    }
  }
}

extension GenderLabel on Gender {
  String get label {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
    }
  }
}

extension HarvestStatusLabel on HarvestStatus {
  String get label {
    switch (this) {
      case HarvestStatus.upcoming:
        return 'Upcoming';
      case HarvestStatus.inProgress:
        return 'In Progress';
      case HarvestStatus.completed:
        return 'Completed';
    }
  }
}
