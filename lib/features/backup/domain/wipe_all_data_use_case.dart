/// Use case to wipe all application data.
///
/// **RN-233:** Wipe all data MUST delete database, files and preferences,
/// and MUST NOT leave any token or cache residue.
abstract interface class WipeAllDataUseCase {
  /// Performs full wipe of application data.
  Future<void> call();
}
