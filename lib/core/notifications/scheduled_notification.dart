class ScheduledNotification {
  final String id;
  final String title;
  final String body;
  final DateTime scheduledAt;

  const ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduledNotification &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          body == other.body &&
          scheduledAt == other.scheduledAt;

  @override
  int get hashCode =>
      id.hashCode ^ title.hashCode ^ body.hashCode ^ scheduledAt.hashCode;
}

enum PermissionState { granted, denied, permanentlyDenied }
