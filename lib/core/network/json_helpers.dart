import '../../data/models/enums.dart';

String? apiErrorMessage(dynamic data) {
  if (data == null) return null;
  if (data is String) {
    final trimmed = data.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (data is Map<String, dynamic>) {
    final detail = data['detail'];
    if (detail is String) return detail;
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map && first['msg'] != null) {
        return first['msg'].toString();
      }
      return detail.first.toString();
    }
    if (data['message'] is String) return data['message'] as String;
  }
  return null;
}

UserRole parseUserRole(String value) {
  switch (value) {
    case 'super_admin':
      return UserRole.superAdmin;
    case 'executive':
      return UserRole.executive;
    default:
      return UserRole.values.byName(value);
  }
}

String userRoleToApi(UserRole role) =>
    role == UserRole.superAdmin ? 'super_admin' : role.name;

FarmVisitStatus parseFarmVisitStatus(String value) {
  switch (value) {
    case 'pending_visit':
    case 'pending':
      return FarmVisitStatus.pending;
    case 'ongoing':
    case 'in_progress':
      return FarmVisitStatus.ongoing;
    case 'visited':
      return FarmVisitStatus.visited;
    case 'harvested':
      return FarmVisitStatus.harvested;
    case 'blocked':
      return FarmVisitStatus.blocked;
    default:
      return FarmVisitStatus.pending;
  }
}

String farmVisitStatusToApi(FarmVisitStatus status) {
  switch (status) {
    case FarmVisitStatus.pending:
      return 'pending_visit';
    case FarmVisitStatus.ongoing:
      return 'pending_visit';
    case FarmVisitStatus.visited:
      return 'visited';
    case FarmVisitStatus.harvested:
      return 'harvested';
    case FarmVisitStatus.blocked:
      return 'pending_visit';
  }
}

VisitStatus parseVisitStatus(String value) {
  switch (value) {
    case 'in_progress':
      return VisitStatus.ongoing;
    case 'completed':
      return VisitStatus.completed;
    case 'cancelled':
      return VisitStatus.cancelled;
    default:
      return VisitStatus.ongoing;
  }
}

String visitStatusToApi(VisitStatus status) {
  switch (status) {
    case VisitStatus.ongoing:
      return 'in_progress';
    case VisitStatus.completed:
      return 'completed';
    case VisitStatus.cancelled:
      return 'cancelled';
  }
}

InteractionStatus parseInteractionStatus(String value) {
  switch (value) {
    case 'ready_to_onboard':
      return InteractionStatus.readyToOnboard;
    case 'taking_time':
      return InteractionStatus.takingTime;
    case 'uncertain':
      return InteractionStatus.uncertain;
    default:
      return InteractionStatus.uncertain;
  }
}

String interactionStatusToApi(InteractionStatus status) {
  switch (status) {
    case InteractionStatus.readyToOnboard:
      return 'ready_to_onboard';
    case InteractionStatus.takingTime:
      return 'taking_time';
    case InteractionStatus.uncertain:
      return 'uncertain';
  }
}

String? sortOrderToApi(SortOrder order) {
  switch (order) {
    case SortOrder.nearbyToFarthest:
      return 'distance';
    case SortOrder.farthestToNearby:
      return 'farthest';
    case SortOrder.nameAsc:
      return null;
  }
}

class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<T> items;
  final int total;
  final int page;
  final int pageSize;
}

PaginatedResult<T> parsePaginated<T>(
  dynamic data,
  T Function(Map<String, dynamic> json) fromJson,
) {
  if (data is Map) {
    final map = Map<String, dynamic>.from(data);
    final items = map['items'] as List<dynamic>? ?? [];
    return PaginatedResult(
      items: items
          .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      total: map['total'] as int? ?? items.length,
      page: map['page'] as int? ?? 1,
      pageSize: map['page_size'] as int? ?? items.length,
    );
  }
  if (data is List) {
    return PaginatedResult(
      items: data
          .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      total: data.length,
      page: 1,
      pageSize: data.length,
    );
  }
  return const PaginatedResult(items: [], total: 0, page: 1, pageSize: 0);
}

List<T> parseList<T>(
  dynamic data,
  T Function(Map<String, dynamic> json) fromJson,
) {
  return parsePaginated(data, fromJson).items;
}

Map<String, dynamic> queryParams(Map<String, dynamic> params) {
  return Map.fromEntries(
    params.entries.where(
      (e) => e.value != null && e.value.toString().isNotEmpty,
    ),
  );
}
