/// Time abstraction — all date/time reads in the domain MUST use [Clock].
///
/// `DateTime.now()` in `lib/` outside of `**/adapters/**` MUST fail the build
/// (RN-004, CA-4.3). In tests, inject [FakeClock]; in production, [SystemClock].
library;

// ---------------------------------------------------------------------------
// Port (domain interface)
// ---------------------------------------------------------------------------

/// Provides the current instant in UTC.
///
/// All domain time reads use this interface; no internal adapter calls
/// `DateTime.now()` directly.
abstract class Clock {
  const Clock();

  /// Current instant in **UTC**.
  DateTime nowUtc();

  /// Current instant in **local** time (device time zone).
  /// Essential for calculations depending on local user time, such as QuietHours.
  DateTime nowLocal();

  /// Current date without time (convenience for day comparisons).
  DateTime todayUtc() {
    final now = nowUtc();
    return DateTime.utc(now.year, now.month, now.day);
  }
}

// ---------------------------------------------------------------------------
// Production adapter
// ---------------------------------------------------------------------------

/// Real implementation of [Clock] using `DateTime.now()`.
///
/// This is the **only** place in the app where `DateTime.now()` is permitted
/// within `lib/`. The architecture tests enforce this invariant.
final class SystemClock extends Clock {
  const SystemClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();

  @override
  DateTime nowLocal() => DateTime.now();
}
