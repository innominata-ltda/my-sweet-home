/// Descriptor for a supported application UI locale.
class AppLocaleDescriptor {
  const AppLocaleDescriptor({
    required this.id,
    required this.languageCode,
    this.countryCode,
    required this.displayName,
  });

  /// Canonical persistence identifier (e.g., `pt_BR`, `en_US`).
  final String id;

  /// ISO 639-1 language code.
  final String languageCode;

  /// Optional ISO 3166-1 alpha-2 country code.
  final String? countryCode;

  /// Human-readable label shown in the Settings language picker.
  final String displayName;
}

/// Central registry of application locales available to the UI and Settings.
abstract final class AppLocaleRegistry {
  static const String systemLocaleId = 'system';
  static const String defaultLocaleId = 'pt_BR';

  /// Registered UI locales.
  ///
  /// Contributors adding a new `app_<lang>.arb` bundle append an entry here.
  static const List<AppLocaleDescriptor> supportedLocales = [
    AppLocaleDescriptor(
      id: 'pt_BR',
      languageCode: 'pt',
      countryCode: 'BR',
      displayName: 'Português (Brasil)',
    ),
  ];

  /// Returns the matching [AppLocaleDescriptor] or `null` for `system`/unknown IDs.
  static AppLocaleDescriptor? findById(String localeId) {
    for (final descriptor in supportedLocales) {
      if (descriptor.id == localeId) return descriptor;
    }
    return null;
  }

  /// Normalizes persisted locale IDs, falling back to [systemLocaleId] when unknown.
  static String normalizeLocaleId(String? localeId) {
    if (localeId == null || localeId == systemLocaleId) {
      return systemLocaleId;
    }
    return findById(localeId)?.id ?? systemLocaleId;
  }
}

/// Descriptor for a regional receipt OCR parser format.
class ReceiptFormatDescriptor {
  const ReceiptFormatDescriptor({
    required this.id,
    required this.regionCode,
    required this.displayName,
    required this.description,
  });

  /// Canonical persistence and registry key (e.g., `br_nfce`).
  final String id;

  /// Country or region code (e.g., `BR`, `US`, `EU`).
  final String regionCode;

  /// Display title shown in the Settings receipt format picker.
  final String displayName;

  /// Short subtitle describing the receipt standard.
  final String description;
}

/// Catalog of registered regional receipt format descriptors.
abstract final class ReceiptFormatCatalog {
  static const String autoFormatId = 'auto';
  static const String brNfceFormatId = 'br_nfce';

  /// Registered receipt formats.
  ///
  /// Contributors adding a new `ReceiptParser` append its descriptor here and
  /// register the parser instance in `ReceiptFormatRegistry`.
  static const List<ReceiptFormatDescriptor> descriptors = [
    ReceiptFormatDescriptor(
      id: brNfceFormatId,
      regionCode: 'BR',
      displayName: 'Brasil (NFC-e / SAT / Cupom Fiscal)',
      description: 'CNPJ, chave de acesso e padrão monetário BRL',
    ),
  ];

  /// Returns the matching [ReceiptFormatDescriptor] or `null` for `auto`/unknown IDs.
  static ReceiptFormatDescriptor? findById(String formatId) {
    for (final descriptor in descriptors) {
      if (descriptor.id == formatId) return descriptor;
    }
    return null;
  }

  /// Normalizes persisted format IDs, falling back to [autoFormatId] when unknown.
  static String normalizeFormatId(String? formatId) {
    if (formatId == null || formatId == autoFormatId) {
      return autoFormatId;
    }
    return findById(formatId)?.id ?? autoFormatId;
  }
}
