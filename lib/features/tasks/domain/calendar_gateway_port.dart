import 'package:my_sweet_home/core/result/result.dart';

import 'models.dart';

abstract interface class CalendarGatewayPort {
  Future<Result<RemoteSnapshot, CalendarFailure>> pull(
    DateTimeRange window, {
    DateTime? updatedMin,
  });
  Future<Result<RemoteEvent, CalendarFailure>> push(TaskEvent e);
  Future<Result<void, CalendarFailure>> deleteRemote(
    String eventId,
    String etag,
  );
  Future<Result<void, CalendarFailure>> disconnect();
}
