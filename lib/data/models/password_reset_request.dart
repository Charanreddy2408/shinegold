class PasswordResetRequestItem {
  const PasswordResetRequestItem({
    required this.id,
    required this.userId,
    required this.employeeId,
    required this.userName,
    required this.status,
    required this.requestedAt,
  });

  final String id;
  final String userId;
  final String employeeId;
  final String userName;
  final String status;
  final DateTime requestedAt;

  bool get isPending => status == 'pending';

  factory PasswordResetRequestItem.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return PasswordResetRequestItem(
      id: json['id']?.toString() ?? '',
      userId: user['id']?.toString() ?? '',
      employeeId: user['employee_id'] as String? ?? '',
      userName: user['name'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      requestedAt: DateTime.parse(json['requested_at'] as String),
    );
  }
}

class PasswordResetStatusInfo {
  const PasswordResetStatusInfo({
    required this.employeeId,
    required this.approved,
    required this.message,
    this.status,
  });

  final String employeeId;
  final String? status;
  final bool approved;
  final String message;

  bool get isPending => status == 'pending';
  bool get isApproved => approved;
  bool get isCompleted => status == 'completed';

  factory PasswordResetStatusInfo.fromJson(Map<String, dynamic> json) {
    return PasswordResetStatusInfo(
      employeeId: json['employee_id'] as String? ?? '',
      status: json['status'] as String?,
      approved: json['approved'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );
  }
}
