enum VehicleStatus {
  inStock,
  outOfStock,
  sold,
  reserved,
}

class Vehicle {
  final int? id;
  final String stockNo; // Stock number (e.g., "SWIFT2012")
  final String name; // Full name (e.g., "Suzuki Swift")
  final String description;
  final double priceUSD; // Price in USD
  final double priceUGX; // Price in UGX (calculated)
  final String make; // e.g., "Suzuki"
  final String model; // e.g., "Swift"
  final int year; // e.g., 2012
  final String chassisNo; // Chassis number
  final String engineSize; // e.g., "3,500 C.C"
  final String fuelType; // e.g., "Petrol", "Diesel"
  final String transmission; // e.g., "Automatic", "Manual"
  final int mileage;
  final String color;
  final VehicleStatus status;
  final bool isActive;
  final List<String>? images; // Vehicle images
  final DateTime createdAt;
  final DateTime updatedAt;

  Vehicle({
    this.id,
    required this.stockNo,
    required this.name,
    this.description = '',
    required this.priceUSD,
    this.priceUGX = 0.0,
    required this.make,
    required this.model,
    required this.year,
    this.chassisNo = '',
    this.engineSize = '',
    this.fuelType = '',
    this.transmission = '',
    this.mileage = 0,
    this.color = '',
    this.status = VehicleStatus.inStock,
    this.isActive = true,
    this.images,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Convert Vehicle to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stockNo': stockNo,
      'name': name,
      'description': description,
      'priceUSD': priceUSD,
      'priceUGX': priceUGX,
      'make': make,
      'model': model,
      'year': year,
      'chassisNo': chassisNo,
      'engineSize': engineSize,
      'fuelType': fuelType,
      'transmission': transmission,
      'mileage': mileage,
      'color': color,
      'status': status.name,
      'isActive': isActive ? 1 : 0,
      'images': images?.join(','),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create Vehicle from Map (database retrieval)
  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'],
      stockNo: map['stockNo'] ?? '',
      name: map['name'],
      description: map['description'] ?? '',
      priceUSD: map['priceUSD']?.toDouble() ?? 0.0,
      priceUGX: map['priceUGX']?.toDouble() ?? 0.0,
      make: map['make'] ?? '',
      model: map['model'] ?? '',
      year: map['year'] ?? 0,
      chassisNo: map['chassisNo'] ?? '',
      engineSize: map['engineSize'] ?? '',
      fuelType: map['fuelType'] ?? '',
      transmission: map['transmission'] ?? '',
      mileage: map['mileage'] ?? 0,
      color: map['color'] ?? '',
      status: VehicleStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => VehicleStatus.inStock,
      ),
      isActive: map['isActive'] == 1,
      images: map['images']?.split(','),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // Create a copy of Vehicle with updated fields
  Vehicle copyWith({
    int? id,
    String? stockNo,
    String? name,
    String? description,
    double? priceUSD,
    double? priceUGX,
    String? make,
    String? model,
    int? year,
    String? chassisNo,
    String? engineSize,
    String? fuelType,
    String? transmission,
    int? mileage,
    String? color,
    VehicleStatus? status,
    bool? isActive,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      stockNo: stockNo ?? this.stockNo,
      name: name ?? this.name,
      description: description ?? this.description,
      priceUSD: priceUSD ?? this.priceUSD,
      priceUGX: priceUGX ?? this.priceUGX,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      chassisNo: chassisNo ?? this.chassisNo,
      engineSize: engineSize ?? this.engineSize,
      fuelType: fuelType ?? this.fuelType,
      transmission: transmission ?? this.transmission,
      mileage: mileage ?? this.mileage,
      color: color ?? this.color,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get formatted price in USD
  String get formattedPriceUSD {
    return '\$${priceUSD.toStringAsFixed(0)}';
  }

  // Get formatted price in UGX
  String get formattedPriceUGX {
    return 'UGX ${priceUGX.toStringAsFixed(0)}';
  }

  // Get full vehicle name
  String get fullName {
    return '$year $make $model';
  }

  // Check if vehicle is available for sale
  bool get isAvailable {
    return status == VehicleStatus.inStock && isActive;
  }

  // Get status display text
  String get statusText {
    switch (status) {
      case VehicleStatus.inStock:
        return 'In Stock';
      case VehicleStatus.outOfStock:
        return 'Out of Stock';
      case VehicleStatus.sold:
        return 'Sold';
      case VehicleStatus.reserved:
        return 'Reserved';
    }
  }

  // Get status color
  String get statusColor {
    switch (status) {
      case VehicleStatus.inStock:
        return 'green';
      case VehicleStatus.outOfStock:
        return 'red';
      case VehicleStatus.sold:
        return 'blue';
      case VehicleStatus.reserved:
        return 'orange';
    }
  }

  @override
  String toString() {
    return 'Vehicle{id: $id, stockNo: $stockNo, name: $name, make: $make, model: $model, year: $year, priceUSD: $priceUSD, status: $status}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Vehicle && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
