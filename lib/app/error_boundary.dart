import 'package:flutter/material.dart' hide DiagnosticLevel;

import '../core/diagnostics/diagnostic_log_port.dart';
import '../core/time/clock.dart';

/// Sets up global error handling so build exceptions do not display
/// the red screen (Gray Box of Death), but rather a user-friendly error screen
/// without exposing internal details (RN-421, CA-4.3),
/// recording the failure in diagnostic log if [log] is provided (RN-432).
void setupGlobalErrorHandling({
  DiagnosticLogPort? log,
  Clock clock = const SystemClock(),
}) {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (log != null) {
      log.record(
        DiagnosticEntry.fromError(
          atUtc: clock.nowUtc(),
          level: DiagnosticLevel.error,
          origin: 'ui.error_boundary',
          error: details.exception,
          stack: details.stack,
        ),
      );
    }
    return const AppErrorState();
  };
}

/// Friendly screen displayed when an unhandled UI error occurs.
class AppErrorState extends StatelessWidget {
  const AppErrorState({super.key});

  @override
  Widget build(BuildContext context) {
    // Pure Material is used here to ensure error displays even if theme or navigation is broken.
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Ops! Ocorreu um erro inesperado.',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Por favor, reinicie o aplicativo.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
