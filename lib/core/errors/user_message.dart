library;

import '../result/result.dart';

/// Canonical source of error text for user interface (RN-421, CA-4.3).
///
/// NUNCA utiliza `failure.detail`, `failure.cause` ou `failure.toString()`,
/// ensuring file paths, exception class names, and monetary values
/// never leak to the user.
String userMessageFor(Failure failure) {
  if (failure is StorageFailure) {
    return 'Não foi possível salvar ou carregar os dados. Tente novamente.';
  }

  if (failure is NetworkFailure) {
    return failure.isOffline
        ? 'Sem conexão com a internet.'
        : 'Não foi possível conectar ao serviço. Verifique sua conexão.';
  }

  if (failure is ValidationFailure) {
    final sanitizedFields = <String>[];
    for (final val in failure.fields.values) {
      final sanitized = _sanitizeText(val);
      if (sanitized.isNotEmpty) {
        sanitizedFields.add(sanitized);
      }
    }
    if (sanitizedFields.isNotEmpty) {
      return sanitizedFields.join(', ');
    }
    return 'Os dados informados são inválidos. Verifique os campos preenchidos.';
  }

  if (failure is NotFoundFailure) {
    return 'Item não encontrado.';
  }

  if (failure is PermissionFailure) {
    return 'Permissão necessária não concedida.';
  }

  if (failure is CancelledFailure) {
    return 'Operação cancelada.';
  }

  if (failure is OcrFailure) {
    return 'Não foi possível reconhecer o comprovante. Tente tirar outra foto.';
  }

  // Falhas de features mapeadas por identificador de tipo sem acoplamento de import
  return switch (failure.runtimeType.toString()) {
    'KeyStoreFailure' => 'Chave de segurança inacessível.',
    'HouseholdFailure' => 'Falha na sincronização da casa.',
    'InviteExpiredFailure' => 'O convite de pareamento expirou.',
    'PairingFailure' => 'Falha no pareamento de aparelhos.',
    'MaxMembersFailure' => 'Limite de membros da casa atingido.',
    'IntegrityFailure' => 'Pacote de sincronização corrompido ou inválido.',
    'IncompatibleProtocolFailure' =>
      'Versão do aplicativo ou protocolo incompatível.',
    'CalendarFailure' => 'Falha na integração com o calendário.',
    'AppUpdateFailure' => 'Falha ao verificar atualização do aplicativo.',
    _ => 'Ocorreu um erro inesperado. Tente novamente.',
  };
}

/// Sanitizes potential paths, exceptions, class names, and financial digits from free text.
String _sanitizeText(String text) {
  var s = text;
  // Remove caminhos (/... ou \...)
  s = s.replaceAll(RegExp(r'[\\\/][^\s]+'), '');
  // Remove mentions of Exception or Error
  s = s.replaceAll(
    RegExp(r'\b\w*(?:Exception|Error|Failure)\w*\b', caseSensitive: false),
    '',
  );
  // Remove currency mentions and numeric amount digits
  s = s.replaceAll(RegExp(r'R\$\s*[\d\.,]+'), '');
  s = s.replaceAll(RegExp(r'\b\d{3,}\b'), '');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return s;
}
