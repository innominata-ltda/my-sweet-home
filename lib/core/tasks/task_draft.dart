/// DTO for task drafts exchanged between preset catalogs and task creation.
/// Pure Dart: no Flutter or Drift dependencies.
final class TaskDraft {
  const TaskDraft({
    required this.title,
    required this.firstOccurrence,
    required this.allDay,
    this.rrule,
    this.sourcePresetId,
    this.categoryId,
  });

  final String title;
  final DateTime firstOccurrence;
  final bool allDay;
  final String? rrule;
  final String? sourcePresetId;
  final String? categoryId;
}
