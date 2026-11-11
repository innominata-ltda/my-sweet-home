import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/features/sync/data/lan/frame_reader.dart';

void main() {
  group('CA-2.6, CA-5.2 / RN-404, RN-405, RN-425: FrameReader', () {
    List<int> encodeFrame(List<int> payload) {
      final header = ByteData(4)..setUint32(0, payload.length, Endian.big);
      return [...header.buffer.asUint8List(), ...payload];
    }

    test('CA-2.6: header declaring 17 MB with maxBytes 16 MB throws FrameTooLargeException and bytesCopied == 0', () async {
      final declared17Mb = 17 * 1024 * 1024;
      final header = ByteData(4)..setUint32(0, declared17Mb, Endian.big);
      final controller = StreamController<List<int>>();

      final reader = FrameReader(controller.stream);

      controller.add(header.buffer.asUint8List());

      const max16Mb = 16 * 1024 * 1024;
      await expectLater(
        reader.next(maxBytes: max16Mb, timeout: const Duration(seconds: 1)),
        throwsA(isA<FrameTooLargeException>()),
      );

      // CA-2.6: No payload byte was allocated or copied
      expect(reader.bytesCopied, equals(0));
      await reader.cancel();
      await controller.close();
    });

    test(
      'CA-5.2: 16 MB received in 4 KB chunks has bytesCopied <= 2 * 16 MB',
      () async {
        const payloadSize = 16 * 1024 * 1024; // 16 MB
        const chunkSize = 4 * 1024; // 4 KB

        final controller = StreamController<List<int>>();
        final reader = FrameReader(controller.stream);

        // 16 MB header
        final header = ByteData(4)..setUint32(0, payloadSize, Endian.big);
        controller.add(header.buffer.asUint8List());

        final sampleChunk = Uint8List(chunkSize);
        for (var i = 0; i < chunkSize; i++) {
          sampleChunk[i] = i % 256;
        }

        final future = reader.next(
          maxBytes: payloadSize,
          timeout: const Duration(seconds: 10),
        );

        final totalChunks = payloadSize ~/ chunkSize;
        for (var i = 0; i < totalChunks; i++) {
          controller.add(sampleChunk);
        }

        final frame = await future;
        expect(frame, isNotNull);
        expect(frame!.length, equals(payloadSize));

        // CA-5.2: Total bytes copied <= 2 * message size
        expect(reader.bytesCopied, lessThanOrEqualTo(2 * payloadSize));
        expect(reader.bytesCopied, equals(payloadSize));

        await reader.cancel();
        await controller.close();
      },
    );

    test('reads multiple sequential frames successfully', () async {
      final controller = StreamController<List<int>>();
      final reader = FrameReader(controller.stream);

      final frame1 = [1, 2, 3, 4, 5];
      final frame2 = [10, 20, 30];

      controller.add(encodeFrame(frame1));
      controller.add(encodeFrame(frame2));

      final res1 = await reader.next(
        maxBytes: 1024,
        timeout: const Duration(seconds: 1),
      );
      expect(res1, equals(frame1));

      final res2 = await reader.next(
        maxBytes: 1024,
        timeout: const Duration(seconds: 1),
      );
      expect(res2, equals(frame2));

      await reader.cancel();
      await controller.close();
    });

    test(
      'returns null when reaching end of stream on frame boundary',
      () async {
        final controller = StreamController<List<int>>();
        final reader = FrameReader(controller.stream);

        await controller.close();

        final res = await reader.next(
          maxBytes: 1024,
          timeout: const Duration(seconds: 1),
        );
        expect(res, isNull);
        await reader.cancel();
      },
    );

    test('times out if no byte arrives within timeout limit', () async {
      final controller = StreamController<List<int>>();
      final reader = FrameReader(controller.stream);

      await expectLater(
        reader.next(maxBytes: 1024, timeout: const Duration(milliseconds: 50)),
        throwsA(isA<TimeoutException>()),
      );

      await reader.cancel();
      await controller.close();
    });
  });
}
