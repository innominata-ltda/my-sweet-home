// Testes de Result — cobre RN-006 (SPEC-001)
// Verifica exaustividade do fold e hierarquia de Failure.

import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/result/result.dart';

void main() {
  group('Ok', () {
    test('fold chama onOk com o valor', () {
      const r = Ok<int, StorageFailure>(42);
      final result = r.fold((v) => v * 2, (_) => -1);
      expect(result, 84);
    });

    test('isOk is true', () {
      expect(const Ok<String, StorageFailure>('hi').isOk, isTrue);
    });

    test('isErr is false', () {
      expect(const Ok<String, StorageFailure>('hi').isErr, isFalse);
    });

    test('valueOrNull retorna o valor', () {
      expect(const Ok<int, StorageFailure>(7).valueOrNull, 7);
    });

    test('failureOrNull retorna null', () {
      expect(const Ok<int, StorageFailure>(7).failureOrNull, isNull);
    });

    test('readable toString', () {
      expect(const Ok<int, StorageFailure>(1).toString(), 'Ok(1)');
    });
  });

  group('Err', () {
    const failure = StorageFailure(detail: 'disco cheio');

    test('fold chama onErr com a falha', () {
      const r = Err<int, StorageFailure>(failure);
      final result = r.fold((_) => -1, (f) => f.detail);
      expect(result, 'disco cheio');
    });

    test('isErr is true', () {
      expect(const Err<int, StorageFailure>(failure).isErr, isTrue);
    });

    test('isOk is false', () {
      expect(const Err<int, StorageFailure>(failure).isOk, isFalse);
    });

    test('failureOrNull retorna a falha', () {
      expect(const Err<int, StorageFailure>(failure).failureOrNull, failure);
    });

    test('valueOrNull retorna null', () {
      expect(const Err<int, StorageFailure>(failure).valueOrNull, isNull);
    });

    test('readable toString', () {
      expect(
        const Err<int, StorageFailure>(failure).toString(),
        contains('StorageFailure'),
      );
    });
  });

  group('Failure — hierarquia selada', () {
    test('StorageFailure tem detail', () {
      const f = StorageFailure(detail: 'tabela corrompida');
      expect(f.detail, 'tabela corrompida');
    });

    test('ValidationFailure tem fields', () {
      const f = ValidationFailure(fields: {'amount': 'required'});
      expect(f.fields['amount'], 'required');
    });

    test('NotFoundFailure tem what', () {
      const f = NotFoundFailure(what: 'produto#123');
      expect(f.what, 'produto#123');
    });

    test('PermissionFailure tem permission', () {
      const f = PermissionFailure(permission: 'CAMERA');
      expect(f.permission, 'CAMERA');
    });

    test('NetworkFailure distingue offline de erro de servidor', () {
      const offline = NetworkFailure(isOffline: true);
      const serverErr = NetworkFailure(isOffline: false);
      expect(offline.isOffline, isTrue);
      expect(serverErr.isOffline, isFalse);
    });

    test('CancelledFailure com reason opcional', () {
      const f = CancelledFailure(reason: 'timeout');
      expect(f.reason, 'timeout');
      expect(f.toString(), 'CancelledFailure(timeout)');
      const fNoReason = CancelledFailure();
      expect(fNoReason.reason, isNull);
      expect(fNoReason.toString(), 'CancelledFailure(null)');
    });

    test('OcrFailure com message e cause opcional', () {
      const f = OcrFailure(message: 'imagem borrada', cause: 'blur');
      expect(f.message, 'imagem borrada');
      expect(f.cause, 'blur');
      expect(f.toString(), 'OcrFailure(imagem borrada)');
    });

    test('toString de todas as falhas', () {
      expect(
        const ValidationFailure(fields: {'k': 'v'}).toString(),
        'ValidationFailure({k: v})',
      );
      expect(
        const NotFoundFailure(what: 'item').toString(),
        'NotFoundFailure(item)',
      );
      expect(
        const PermissionFailure(permission: 'P').toString(),
        'PermissionFailure(P)',
      );
      expect(
        const NetworkFailure(isOffline: true).toString(),
        'NetworkFailure(offline=true)',
      );
      expect(const StorageFailure(detail: 'd', cause: 'c').cause, 'c');
    });
  });

  group('Exhaustividade — switch pattern', () {
    // Este teste garante que adicionar um tipo a Failure sem atualizar
    // switches break at compile time (sealed class).
    test('switch on Result is exhaustive', () {
      final Result<int, StorageFailure> r = const Ok(1);
      final label = switch (r) {
        Ok(:final value) => 'ok:$value',
        Err(:final failure) => 'err:${failure.detail}',
      };
      expect(label, 'ok:1');

      final Result<int, StorageFailure> err = const Err(
        StorageFailure(detail: 'x'),
      );
      final label2 = switch (err) {
        Ok(:final value) => 'ok:$value',
        Err(:final failure) => 'err:${failure.detail}',
      };
      expect(label2, 'err:x');
    });
  });
}
