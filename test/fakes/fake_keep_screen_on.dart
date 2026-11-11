import 'package:my_sweet_home/features/recipes/domain/ports/keep_screen_on_port.dart';

class FakeKeepScreenOn implements KeepScreenOnPort {
  bool isEnabled = false;

  @override
  Future<void> enable() async {
    isEnabled = true;
  }

  @override
  Future<void> disable() async {
    isEnabled = false;
  }
}
