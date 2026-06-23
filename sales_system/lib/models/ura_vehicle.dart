class UraVehicle {
  final int id;
  final String? serialNumber;
  final String hscCode;
  final String countryOrigin;
  final String make;
  final String model;
  final int year;
  final int engineCC;
  final String description;
  final double cifUsd;
  final String databaseMonth;
  final DateTime downloadedAt;
  final bool isActive;

  UraVehicle({
    required this.id,
    this.serialNumber,
    required this.hscCode,
    required this.countryOrigin,
    required this.make,
    required this.model,
    required this.year,
    required this.engineCC,
    required this.description,
    required this.cifUsd,
    required this.databaseMonth,
    required this.downloadedAt,
    required this.isActive,
  });

  factory UraVehicle.fromMap(Map<String, dynamic> map) {
    return UraVehicle(
      id: map['id'] as int,
      serialNumber: map['serial_number'] as String?,
      hscCode: map['hsc_code'] as String? ?? '',
      countryOrigin: map['country_origin'] as String? ?? '',
      make: map['make'] as String,
      model: map['model'] as String,
      year: map['year'] as int,
      engineCC: map['engine_cc'] as int? ?? 0,
      description: map['description'] as String? ?? '',
      cifUsd: (map['cif_usd'] as num).toDouble(),
      databaseMonth: map['database_month'] as String,
      downloadedAt: DateTime.parse(map['downloaded_at'] as String),
      isActive: (map['is_active'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serial_number': serialNumber,
      'hsc_code': hscCode,
      'country_origin': countryOrigin,
      'make': make,
      'model': model,
      'year': year,
      'engine_cc': engineCC,
      'description': description,
      'cif_usd': cifUsd,
      'database_month': databaseMonth,
      'downloaded_at': downloadedAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  @override
  String toString() {
    return 'UraVehicle(id: $id, make: $make, model: $model, year: $year, engineCC: $engineCC, cifUsd: $cifUsd)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other.runtimeType == runtimeType &&
        other is UraVehicle &&
        other.id == id &&
        other.make == make &&
        other.model == model &&
        other.year == year &&
        other.engineCC == engineCC;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        make.hashCode ^
        model.hashCode ^
        year.hashCode ^
        engineCC.hashCode;
  }
}






