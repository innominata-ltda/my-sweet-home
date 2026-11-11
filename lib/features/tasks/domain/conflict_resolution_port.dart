import 'package:my_sweet_home/core/result/result.dart';

import 'models.dart';

/// User choice when resolving a synchronization conflict.
///
/// RN-156: system MUST NOT choose automatically — decision belongs to user.
enum ConflictChoice {
  /// Preserves local version; discards remote version.
  keepLocal,

  /// Preserves remote version; discards local version.
  keepRemote,
}

/// Domain port for synchronization conflict resolution.
///
/// A real adapter presents a dialog/screen to user. Deterministic fake
/// in `test/fakes/` follows configured strategy in test,
/// without any UI dependency.
///
/// RN-156 / CA-3.2
abstract interface class ConflictResolutionPort {
  /// Presents [conflict] to user and awaits their choice.
  ///
  /// Returns [Ok] with selected [ConflictChoice], or [Err] with
  /// [CancelledFailure] if user dismisses without deciding.
  Future<Result<ConflictChoice, Failure>> resolve(Conflict conflict);
}
