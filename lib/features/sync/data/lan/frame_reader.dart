library;

import 'dart:async';
import 'dart:typed_data';

/// Exception thrown when a frame declares size exceeding maximum limit (RN-404, RN-405, CA-2.6).
final class FrameTooLargeException implements Exception {
  final int declaredBytes;
  final int maxBytes;

  const FrameTooLargeException({
    required this.declaredBytes,
    required this.maxBytes,
  });

  @override
  String toString() =>
      'FrameTooLargeException: quadro declara $declaredBytes bytes (limite: $maxBytes bytes)';
}

/// Exception thrown when stream terminates prematurely mid-frame.
final class FrameIncompleteException implements Exception {
  final int expectedBytes;
  final int receivedBytes;

  const FrameIncompleteException({
    required this.expectedBytes,
    required this.receivedBytes,
  });

  @override
  String toString() =>
      'FrameIncompleteException: esperado $expectedBytes bytes, recebido apenas $receivedBytes';
}

/// Leitor de quadros prefixados por comprimento (4 bytes big-endian) para o protocolo LAN (RN-404, RN-405, RN-425).
///
/// Ensures linear copy cost (single allocation with exact header size)
/// and rejects excessive frames before allocating memory for payload (CA-2.6, CA-5.2).
final class FrameReader {
  FrameReader(Stream<List<int>> source) {
    _subscription = source.listen(
      (chunk) {
        if (chunk.isNotEmpty) {
          _queue.add(chunk);
          _signal();
        }
      },
      onDone: () {
        _isDone = true;
        _signal();
      },
      onError: (Object e) {
        _error = e;
        _signal();
      },
      cancelOnError: false,
    );
  }

  late final StreamSubscription<List<int>> _subscription;
  final List<List<int>> _queue = [];
  int _queueOffset = 0;
  bool _isDone = false;
  Object? _error;
  Completer<void>? _waiter;

  int _bytesCopied = 0;

  /// Cumulative total of bytes copied to payload buffers (instrumentation for CA-5.2).
  int get bytesCopied => _bytesCopied;

  void _signal() {
    if (_waiter != null && !_waiter!.isCompleted) {
      _waiter!.complete();
    }
  }

  Future<void> _waitForData() {
    if (_queue.isNotEmpty || _isDone || _error != null) {
      return Future.value();
    }
    _waiter = Completer<void>();
    return _waiter!.future;
  }

  Future<int> _readInto(Uint8List target, int targetOffset, int needed) async {
    var copied = 0;
    while (copied < needed) {
      if (_queue.isEmpty) {
        if (_isDone) break;
        if (_error != null) throw _error!;
        await _waitForData();
        continue;
      }

      final chunk = _queue.first;
      final available = chunk.length - _queueOffset;
      final toCopy = (needed - copied < available)
          ? (needed - copied)
          : available;

      target.setRange(
        targetOffset + copied,
        targetOffset + copied + toCopy,
        chunk,
        _queueOffset,
      );
      _queueOffset += toCopy;
      copied += toCopy;

      if (_queueOffset >= chunk.length) {
        _queue.removeAt(0);
        _queueOffset = 0;
      }
    }
    return copied;
  }

  /// Reads next frame with prefixed length [u32 BE][payload].
  ///
  /// Retorna `null` se o stream terminar de forma limpa na borda de um quadro.
  /// Throws [FrameTooLargeException] if header exceeds [maxBytes] (without allocating payload).
  /// Throws [TimeoutException] if [timeout] limit is reached during read.
  Future<Uint8List?> next({
    required int maxBytes,
    required Duration timeout,
  }) async {
    return _readNext(maxBytes).timeout(timeout);
  }

  Future<Uint8List?> _readNext(int maxBytes) async {
    while (_queue.isEmpty && !_isDone && _error == null) {
      await _waitForData();
    }
    if (_queue.isEmpty && _isDone) {
      return null;
    }

    final header = Uint8List(4);
    final headerBytesRead = await _readInto(header, 0, 4);
    if (headerBytesRead == 0) {
      return null;
    }
    if (headerBytesRead < 4) {
      throw FrameIncompleteException(
        expectedBytes: 4,
        receivedBytes: headerBytesRead,
      );
    }

    final payloadLength = ByteData.sublistView(header).getUint32(0);

    // 2. Validation before allocating memory (CA-2.6)
    if (payloadLength > maxBytes) {
      throw FrameTooLargeException(
        declaredBytes: payloadLength,
        maxBytes: maxBytes,
      );
    }

    if (payloadLength == 0) {
      return Uint8List(0);
    }

    // 3. SINGLE allocation of payload buffer
    final buffer = Uint8List(payloadLength);
    final payloadBytesRead = await _readInto(buffer, 0, payloadLength);
    _bytesCopied += payloadBytesRead;

    if (payloadBytesRead < payloadLength) {
      throw FrameIncompleteException(
        expectedBytes: payloadLength,
        receivedBytes: payloadBytesRead,
      );
    }

    return buffer;
  }

  /// Cancela o leitor e libera o stream subjacente.
  Future<void> cancel() async {
    _isDone = true;
    _signal();
    await _subscription.cancel();
  }
}
