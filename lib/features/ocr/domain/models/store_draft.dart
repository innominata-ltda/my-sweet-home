/// Store information draft extracted from receipt header.
final class StoreDraft {
  /// Store name (Corporate Name or Trade Name).
  final String? name;

  /// Clean CNPJ (14 digits) or formatted if validated.
  /// If CNPJ is invalid, may contain read string or raw digits.
  final String? cnpj;

  /// Indicates whether CNPJ check digits were validated successfully (RN-194).
  ///
  /// `true`: valid CNPJ.
  /// `false`: CNPJ with invalid check digits ("unconfirmed") or absent.
  final bool isCnpjValid;

  /// CNPJ bruto tal como foi lido pelo OCR no documento.
  final String? rawCnpj;

  /// Store address, if identified.
  final String? address;

  /// Confidence (0.0 to 1.0) associated with header extraction.
  final double confidence;

  const StoreDraft({
    this.name,
    this.cnpj,
    this.isCnpjValid = false,
    this.rawCnpj,
    this.address,
    this.confidence = 1.0,
  });

  factory StoreDraft.fromJson(Map<String, dynamic> json) {
    return StoreDraft(
      name: json['name'] as String?,
      cnpj: json['cnpj'] as String?,
      isCnpjValid: json['isCnpjValid'] as bool? ?? false,
      rawCnpj: json['rawCnpj'] as String?,
      address: json['address'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }

  StoreDraft copyWith({
    String? name,
    String? cnpj,
    bool? isCnpjValid,
    String? rawCnpj,
    String? address,
    double? confidence,
  }) {
    return StoreDraft(
      name: name ?? this.name,
      cnpj: cnpj ?? this.cnpj,
      isCnpjValid: isCnpjValid ?? this.isCnpjValid,
      rawCnpj: rawCnpj ?? this.rawCnpj,
      address: address ?? this.address,
      confidence: confidence ?? this.confidence,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'cnpj': cnpj,
    'isCnpjValid': isCnpjValid,
    'rawCnpj': rawCnpj,
    'address': address,
    'confidence': confidence,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoreDraft &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          cnpj == other.cnpj &&
          isCnpjValid == other.isCnpjValid &&
          rawCnpj == other.rawCnpj &&
          address == other.address &&
          confidence == other.confidence;

  @override
  int get hashCode =>
      Object.hash(name, cnpj, isCnpjValid, rawCnpj, address, confidence);

  @override
  String toString() =>
      'StoreDraft(name: $name, cnpj: $cnpj, isCnpjValid: $isCnpjValid, rawCnpj: $rawCnpj, address: $address, confidence: ${confidence.toStringAsFixed(2)})';
}
