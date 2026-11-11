abstract interface class KeepScreenOnPort {
  Future<void> enable();
  Future<void> disable();
}
