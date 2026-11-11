import 'package:flutter/material.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';

/// Standard deletion SnackBar with undo action (3-second duration).
///
/// **Rule RN-014:** mandatory on all deletions to allow immediate restoration
/// within the 3-second tolerance window.
class AppUndoSnackBar extends SnackBar {
  AppUndoSnackBar({
    super.key,
    required String message,
    required VoidCallback onUndo,
    String undoLabel = 'Desfazer',
    super.duration = const Duration(seconds: 5),
    super.behavior = SnackBarBehavior.floating,
  }) : super(
         content: Semantics(liveRegion: true, child: Text(message)),
         shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(Radius.sm),
         ),
         action: SnackBarAction(label: undoLabel, onPressed: onUndo),
       );

  /// Shows the [AppUndoSnackBar] on the [ScaffoldMessenger] of [context].
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    String undoLabel = 'Desfazer',
    Duration duration = const Duration(seconds: 5),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    return messenger.showSnackBar(
      AppUndoSnackBar(
        message: message,
        onUndo: onUndo,
        undoLabel: undoLabel,
        duration: duration,
      ),
    );
  }
}
