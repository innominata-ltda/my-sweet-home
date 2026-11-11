import 'package:flutter/foundation.dart';
import 'package:my_sweet_home/features/backup/domain/wipe_all_data_use_case.dart';

sealed class WipeAllDataState {}

final class WipeAllDataInitial extends WipeAllDataState {}

final class WipeAllDataLoading extends WipeAllDataState {}

final class WipeAllDataSuccess extends WipeAllDataState {}

final class WipeAllDataError extends WipeAllDataState {
  final String message;
  WipeAllDataError(this.message);
}

class WipeAllDataController extends ValueNotifier<WipeAllDataState> {
  final WipeAllDataUseCase wipeAllDataUseCase;

  WipeAllDataController({required this.wipeAllDataUseCase})
    : super(WipeAllDataInitial());

  Future<void> executeWipe() async {
    value = WipeAllDataLoading();
    try {
      await wipeAllDataUseCase();
      value = WipeAllDataSuccess();
    } catch (_) {
      // CA-4.3 / RN-421: Friendly UI message without exposing raw exception
      value = WipeAllDataError(
        'Failed to wipe application data. Please try again.',
      );
    }
  }
}
