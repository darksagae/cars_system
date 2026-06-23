enum ProductStatus {
  active,
  inactive,
  discontinued,
}

class Product {
  final int? id;
  final String name;
  final String description;
  final double price;
  final String sku;
  final String category;
  final int stock;
  final int minStock;
  final int lowStockThreshold;
  final String unit;
  final double taxRate;
  final bool isActive;
  final ProductStatus status;
  final String? barcode;
  final String? barcodeType;
  final List<String>? images;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    this.id,
    required this.name,
    this.description = '',
    required this.price,
    this.sku = '',
    this.category = '',
    this.stock = 0,
    this.minStock = 0,
    this.lowStockThreshold = 5,
    this.unit = 'pcs',
    this.taxRate = 0.0,
    this.isActive = true,
    this.status = ProductStatus.active,
    this.barcode,
    this.barcodeType,
    this.images,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Convert Product to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'sku': sku,
      'category': category,
      'stock': stock,
      'minStock': minStock,
      'lowStockThreshold': lowStockThreshold,
      'unit': unit,
      'taxRate': taxRate,
      'isActive': isActive ? 1 : 0,
      'status': status.name,
      'barcode': barcode,
      'barcodeType': barcodeType,
      'images': images?.join(','),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create Product from Map (database retrieval)
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      description: map['description'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      sku: map['sku'] ?? '',
      category: map['category'] ?? '',
      stock: map['stock'] ?? 0,
      minStock: map['minStock'] ?? 0,
      lowStockThreshold: map['lowStockThreshold'] ?? 5,
      unit: map['unit'] ?? 'pcs',
      taxRate: map['taxRate']?.toDouble() ?? 0.0,
      isActive: map['isActive'] == 1,
      status: ProductStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ProductStatus.active,
      ),
      barcode: map['barcode'],
      barcodeType: map['barcodeType'],
      images: map['images']?.split(','),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // Create a copy of Product with updated fields
  Product copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? sku,
    String? category,
    int? stock,
    int? minStock,
    int? lowStockThreshold,
    String? unit,
    double? taxRate,
    bool? isActive,
    ProductStatus? status,
    String? barcode,
    String? barcodeType,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      unit: unit ?? this.unit,
      taxRate: taxRate ?? this.taxRate,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      barcode: barcode ?? this.barcode,
      barcodeType: barcodeType ?? this.barcodeType,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Calculate price with tax
  double get priceWithTax {
    return price + (price * taxRate / 100);
  }

  // Check if stock is low
  bool get isLowStock {
    return stock <= minStock;
  }

  // Get formatted price
  String get formattedPrice {
    return '\$${price.toStringAsFixed(2)}';
  }

  // Get formatted price with tax
  String get formattedPriceWithTax {
    return '\$${priceWithTax.toStringAsFixed(2)}';
  }

  @override
  String toString() {
    return 'Product{id: $id, name: $name, sku: $sku, price: $price, stock: $stock}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}