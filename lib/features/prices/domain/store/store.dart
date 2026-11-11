import 'cnpj.dart';

/// Entidade que representa um estabelecimento comercial.
class Store {
  Store({
    required this.id,
    required this.name,
    this.cnpj,
    this.address,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final Cnpj? cnpj;
  final String? address;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime updatedAt;

  Store copyWith({
    String? name,
    Cnpj? cnpj,
    String? address,
    double? latitude,
    double? longitude,
    DateTime? updatedAt,
  }) {
    return Store(
      id: id,
      name: name ?? this.name,
      cnpj: cnpj ?? this.cnpj,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Store &&
          other.id == id &&
          other.name == name &&
          other.cnpj == cnpj &&
          other.address == address &&
          other.latitude == latitude &&
          other.longitude == longitude &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    cnpj,
    address,
    latitude,
    longitude,
    createdAt,
    updatedAt,
  );
}
