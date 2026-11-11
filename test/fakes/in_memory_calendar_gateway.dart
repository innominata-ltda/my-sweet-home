import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/tasks/domain/calendar_gateway_port.dart';
import 'package:my_sweet_home/features/tasks/domain/models.dart';

class InMemoryCalendarGateway implements CalendarGatewayPort {
  final Map<String, RemoteEvent> _events = {};
  int _etagCounter = 1;
  int _actionCount = 0;
  int get actionCount => _actionCount;
  int? failAfterActions;

  InMemoryCalendarGateway({this.failAfterActions});

  void seed(List<RemoteEvent> events) {
    for (final e in events) {
      _events[e.id] = e;
    }
  }

  List<RemoteEvent> get events => _events.values.toList();

  RemoteEvent? getEvent(String id) => _events[id];

  @override
  Future<Result<RemoteSnapshot, CalendarFailure>> pull(
    DateTimeRange window, {
    DateTime? updatedMin,
  }) async {
    if (_shouldFail()) {
      return const Err(
        CalendarFailure('Simulated network failure', isNetworkError: true),
      );
    }

    final matched = _events.values.where((event) {
      if (updatedMin != null && event.updatedAt.isBefore(updatedMin)) {
        return false;
      }
      if (event.start != null) {
        if (event.start!.isBefore(window.start) ||
            event.start!.isAfter(window.end)) {
          return false;
        }
      }
      return true;
    }).toList();

    return Ok(
      RemoteSnapshot(events: matched, snapshotAt: DateTime.now().toUtc()),
    );
  }

  @override
  Future<Result<RemoteEvent, CalendarFailure>> push(TaskEvent e) async {
    if (_shouldFail()) {
      return const Err(
        CalendarFailure('Simulated network failure', isNetworkError: true),
      );
    }

    final now = DateTime.now().toUtc();
    final eventId = e.remoteEventId ?? 'remote_${e.taskId}';
    final etag = 'etag_${_etagCounter++}';

    final remoteEvent = RemoteEvent(
      id: eventId,
      etag: etag,
      updatedAt: now,
      summary: e.title,
      description: e.description,
      start: e.start,
      allDay: e.allDay,
      status: e.isDeleted ? 'cancelled' : 'confirmed',
    );

    _events[eventId] = remoteEvent;
    return Ok(remoteEvent);
  }

  @override
  Future<Result<void, CalendarFailure>> deleteRemote(
    String eventId,
    String etag,
  ) async {
    if (_shouldFail()) {
      return const Err(
        CalendarFailure('Simulated network failure', isNetworkError: true),
      );
    }

    final existing = _events[eventId];
    if (existing != null) {
      _events[eventId] = RemoteEvent(
        id: existing.id,
        etag: 'etag_${_etagCounter++}',
        updatedAt: DateTime.now().toUtc(),
        summary: existing.summary,
        description: existing.description,
        start: existing.start,
        allDay: existing.allDay,
        status: 'cancelled',
      );
    }
    return const Ok(null);
  }

  @override
  Future<Result<void, CalendarFailure>> disconnect() async {
    if (_shouldFail()) {
      return const Err(
        CalendarFailure('Simulated network failure', isNetworkError: true),
      );
    }
    _events.clear();
    return const Ok(null);
  }

  bool _shouldFail() {
    _actionCount++;
    if (failAfterActions != null && _actionCount > failAfterActions!) {
      return true;
    }
    return false;
  }
}
