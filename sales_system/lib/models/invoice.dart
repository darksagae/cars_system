import 'customer.dart';
import 'invoice_type.dart';
import 'vehicle.dart';

enum InvoiceStatus {
  draft,
  sent,
  pending,
  paid,
  overdue,
  cancelled,
}

class InvoiceItem {
  final int? id;
  final int? productId;
  final String productName;
  final String description;
  final double price;
  final int quantity;
  final double taxRate;
  final double discount;

  InvoiceItem({
    this.id,
    this.productId,
    required this.productName,
    this.description = '',
    required this.price,
    required this.quantity,
    this.taxRate = 0.0,
    this.discount = 0.0,
  });

  // Calculate line total
  double get lineTotal {
    double subtotal = price * quantity;
    double discountAmount = subtotal * discount / 100;
    double afterDiscount = subtotal - discountAmount;
    double taxAmount = afterDiscount * taxRate / 100;
    return afterDiscount + taxAmount;
  }

  // Calculate subtotal (before tax and discount)
  double get subtotal {
    return price * quantity;
  }

  // Calculate discount amount
  double get discountAmount {
    return subtotal * discount / 100;
  }

  // Calculate tax amount
  double get taxAmount {
    double afterDiscount = subtotal - discountAmount;
    return afterDiscount * taxRate / 100;
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId, // Can be null for custom items
      'productName': productName,
      'description': description,
      'price': price,
      'quantity': quantity,
      'taxRate': taxRate,
      'discount': discount,
    };
  }

  // Create from Map
  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'] as int?,
      productId: map['productId'] as int?,
      productName: map['productName'] as String,
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as int?) ?? 0,
      taxRate: (map['taxRate'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  InvoiceItem copyWith({
    int? id,
    int? productId,
    String? productName,
    String? description,
    double? price,
    int? quantity,
    double? taxRate,
    double? discount,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      taxRate: taxRate ?? this.taxRate,
      discount: discount ?? this.discount,
    );
  }
}

class Invoice {
  final int? id;
  final String invoiceNumber;
  final InvoiceType invoiceType; // Car Sale, Clearance, Custom
  final int customerId;
  final Customer? customer;
  final int? vehicleId; // Optional link to vehicle
  final Vehicle? vehicle; // Optional vehicle reference
  final DateTime invoiceDate;
  final DateTime dueDate;
  final InvoiceStatus status;
  
  // Vehicle Details (for quotation)
  final String stockNo;
  final String vehicleMake;
  final String vehicleModel;
  final int vehicleYear;
  final String chassisNo;
  final String engineSize;
  final String fuelType;
  final String transmission;
  final String color; // e.g., White, Black, etc. or custom
  final String countryOfOrigin; // ISO-like code, e.g., JP, DE
  
  // First Installment (USD)
  final double carPriceUSD; // Car Kamunye price in USD
  final double clearanceFeeUSD; // Clearance Mombasa in USD
  final double exchangeRate; // USD to UGX exchange rate
  final double firstInstallmentUGX; // Total first installment in UGX
  
  // Second Installment (UGX)
  final double taxesURA; // Manual entry
  final double numberPlatesFee; // 714,300 UGX
  final double thirdPartyInsurance; // Manual entry
  final double agencyFees; // Manual entry
  final double secondInstallmentUGX; // Total second installment
  
  // Totals
  final List<InvoiceItem> items;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount; // Grand Total in UGX
  final double paidAmount;
  final double balanceAmount;
  final double carAmount;
  final double downPayment;
  final double remainingAmount;
  final double taxRate;
  final String notes;
  final String terms;
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;

  Invoice({
    this.id,
    required this.invoiceNumber,
    this.invoiceType = InvoiceType.carSale,
    required this.customerId,
    this.customer,
    this.vehicleId,
    this.vehicle,
    required this.invoiceDate,
    required this.dueDate,
    this.status = InvoiceStatus.draft,
    
    // Vehicle details
    this.stockNo = '',
    this.vehicleMake = '',
    this.vehicleModel = '',
    this.vehicleYear = 0,
    this.chassisNo = '',
    this.engineSize = '',
    this.fuelType = '',
    this.transmission = '',
    this.color = '',
    this.countryOfOrigin = 'JP',
    
    // First Installment (USD)
    this.carPriceUSD = 0.0,
    this.clearanceFeeUSD = 0.0,
    this.exchangeRate = 3834.56, // Default exchange rate
    this.firstInstallmentUGX = 0.0,
    
    // Second Installment (UGX)
    this.taxesURA = 0.0,
    this.numberPlatesFee = 714300.0, // Fixed price
    this.thirdPartyInsurance = 0.0,
    this.agencyFees = 0.0,
    this.secondInstallmentUGX = 0.0,
    
    // Totals
    this.items = const [],
    this.subtotal = 0.0,
    this.taxAmount = 0.0,
    this.discountAmount = 0.0,
    this.totalAmount = 0.0,
    this.paidAmount = 0.0,
    this.balanceAmount = 0.0,
    this.carAmount = 0.0,
    this.downPayment = 0.0,
    this.remainingAmount = 0.0,
    this.taxRate = 0.0,
    this.notes = '',
    this.terms = '',
    this.images = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Calculate totals from items
  Invoice calculateTotals() {
    double calculatedSubtotal = 0.0;
    double calculatedTaxAmount = 0.0;
    double calculatedDiscountAmount = 0.0;

    for (var item in items) {
      calculatedSubtotal += item.subtotal;
      calculatedDiscountAmount += item.discountAmount;
      calculatedTaxAmount += item.taxAmount;
    }

    double calculatedTotal = calculatedSubtotal - calculatedDiscountAmount + calculatedTaxAmount;
    double calculatedBalance = calculatedTotal - paidAmount;

    return copyWith(
      subtotal: calculatedSubtotal,
      taxAmount: calculatedTaxAmount,
      discountAmount: calculatedDiscountAmount,
      totalAmount: calculatedTotal,
      balanceAmount: calculatedBalance,
    );
  }

  // Check if invoice is overdue
  bool get isOverdue {
    return status != InvoiceStatus.paid && 
           status != InvoiceStatus.cancelled && 
           DateTime.now().isAfter(dueDate);
  }

  // Get total amount (alias for totalAmount)
  double get total => totalAmount;

  // Check if invoice is paid
  bool get isPaid {
    return status == InvoiceStatus.paid || balanceAmount <= 0;
  }

  // Get status display text
  String get statusText {
    switch (status) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.sent:
        return 'Sent';
      case InvoiceStatus.pending:
        return 'Pending';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.overdue:
        return 'Overdue';
      case InvoiceStatus.cancelled:
        return 'Cancelled';
    }
  }

  // Get status color
  String get statusColor {
    switch (status) {
      case InvoiceStatus.draft:
        return 'gray';
      case InvoiceStatus.sent:
        return 'blue';
      case InvoiceStatus.pending:
        return 'orange';
      case InvoiceStatus.paid:
        return 'green';
      case InvoiceStatus.overdue:
        return 'red';
      case InvoiceStatus.cancelled:
        return 'orange';
    }
  }

  // Convert Invoice to Map for database storage
  Map<String, dynamic> toMap() {
    final map = {
      'invoiceNumber': invoiceNumber,
      'invoiceType': invoiceType.name,
      'customerId': customerId,
      'vehicleId': vehicleId,
      'invoiceDate': invoiceDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'status': status.index,
      
      // Vehicle details
      'stockNo': stockNo,
      'vehicleMake': vehicleMake,
      'vehicleModel': vehicleModel,
      'vehicleYear': vehicleYear,
      'chassisNo': chassisNo,
      'engineSize': engineSize,
      'fuelType': fuelType,
      'transmission': transmission,
      'color': color,
      'countryOfOrigin': countryOfOrigin,
      
      // First Installment
      'carPriceUSD': carPriceUSD,
      'clearanceFeeUSD': clearanceFeeUSD,
      'exchangeRate': exchangeRate,
      'firstInstallmentUGX': firstInstallmentUGX,
      
      // Second Installment
      'taxesURA': taxesURA,
      'numberPlatesFee': numberPlatesFee,
      'thirdPartyInsurance': thirdPartyInsurance,
      'agencyFees': agencyFees,
      'secondInstallmentUGX': secondInstallmentUGX,
      
      // Totals
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'balanceAmount': balanceAmount,
      'carAmount': carAmount,
      'downPayment': downPayment,
      'remainingAmount': remainingAmount,
      'notes': notes,
      'terms': terms,
      'images': images.join(','),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
    
    // Only include id if it's not 0 (for updates)
    if (id != null && id != 0) {
      map['id'] = id!;
    }
    
    return map;
  }

  // Create Invoice from Map (database retrieval)
  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as int?,
      invoiceNumber: map['invoiceNumber'] as String,
      invoiceType: InvoiceType.values.firstWhere(
        (e) => e.name == map['invoiceType'],
        orElse: () => InvoiceType.carSale,
      ),
      customerId: (map['customerId'] as int?) ?? 0,
      vehicleId: map['vehicleId'] as int?,
      invoiceDate: DateTime.parse(map['invoiceDate'] as String),
      dueDate: DateTime.parse(map['dueDate'] as String),
      status: InvoiceStatus.values[(map['status'] as int?) ?? 0],
      
      // Vehicle details
      stockNo: map['stockNo'] as String? ?? '',
      vehicleMake: map['vehicleMake'] as String? ?? '',
      vehicleModel: map['vehicleModel'] as String? ?? '',
      vehicleYear: (map['vehicleYear'] as int?) ?? 0,
      chassisNo: map['chassisNo'] as String? ?? '',
      engineSize: map['engineSize'] as String? ?? '',
      fuelType: map['fuelType'] as String? ?? '',
      transmission: map['transmission'] as String? ?? '',
      color: map['color'] as String? ?? '',
      countryOfOrigin: map['countryOfOrigin'] as String? ?? 'JP',
      
      // First Installment
      carPriceUSD: (map['carPriceUSD'] as num?)?.toDouble() ?? 0.0,
      clearanceFeeUSD: (map['clearanceFeeUSD'] as num?)?.toDouble() ?? 0.0,
      exchangeRate: (map['exchangeRate'] as num?)?.toDouble() ?? 3834.56,
      firstInstallmentUGX: (map['firstInstallmentUGX'] as num?)?.toDouble() ?? 0.0,
      
      // Second Installment
      taxesURA: (map['taxesURA'] as num?)?.toDouble() ?? 0.0,
      numberPlatesFee: (map['numberPlatesFee'] as num?)?.toDouble() ?? 714300.0,
      thirdPartyInsurance: (map['thirdPartyInsurance'] as num?)?.toDouble() ?? 0.0,
      agencyFees: (map['agencyFees'] as num?)?.toDouble() ?? 0.0,
      secondInstallmentUGX: (map['secondInstallmentUGX'] as num?)?.toDouble() ?? 0.0,
      
      // Totals
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (map['taxAmount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      balanceAmount: (map['balanceAmount'] as num?)?.toDouble() ?? 0.0,
      carAmount: (map['carAmount'] as num?)?.toDouble() ?? 0.0,
      downPayment: (map['downPayment'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (map['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String? ?? '',
      terms: map['terms'] as String? ?? '',
      images: (map['images'] as String?)?.isNotEmpty == true 
          ? (map['images'] as String).split(',') 
          : [],
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  // Create a copy of Invoice with updated fields
  Invoice copyWith({
    int? id,
    String? invoiceNumber,
    InvoiceType? invoiceType,
    int? customerId,
    Customer? customer,
    int? vehicleId,
    Vehicle? vehicle,
    DateTime? invoiceDate,
    DateTime? dueDate,
    InvoiceStatus? status,
    String? stockNo,
    String? vehicleMake,
    String? vehicleModel,
    int? vehicleYear,
    String? chassisNo,
    String? engineSize,
    String? fuelType,
    String? transmission,
    String? color,
    String? countryOfOrigin,
    double? carPriceUSD,
    double? clearanceFeeUSD,
    double? exchangeRate,
    double? firstInstallmentUGX,
    double? taxesURA,
    double? numberPlatesFee,
    double? thirdPartyInsurance,
    double? agencyFees,
    double? secondInstallmentUGX,
    List<InvoiceItem>? items,
    double? subtotal,
    double? taxAmount,
    double? discountAmount,
    double? totalAmount,
    double? paidAmount,
    double? balanceAmount,
    double? carAmount,
    double? downPayment,
    double? remainingAmount,
    double? taxRate,
    String? notes,
    String? terms,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceType: invoiceType ?? this.invoiceType,
      customerId: customerId ?? this.customerId,
      customer: customer ?? this.customer,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicle: vehicle ?? this.vehicle,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      stockNo: stockNo ?? this.stockNo,
      vehicleMake: vehicleMake ?? this.vehicleMake,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      chassisNo: chassisNo ?? this.chassisNo,
      engineSize: engineSize ?? this.engineSize,
      fuelType: fuelType ?? this.fuelType,
      transmission: transmission ?? this.transmission,
      color: color ?? this.color,
      countryOfOrigin: countryOfOrigin ?? this.countryOfOrigin,
      carPriceUSD: carPriceUSD ?? this.carPriceUSD,
      clearanceFeeUSD: clearanceFeeUSD ?? this.clearanceFeeUSD,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      firstInstallmentUGX: firstInstallmentUGX ?? this.firstInstallmentUGX,
      taxesURA: taxesURA ?? this.taxesURA,
      numberPlatesFee: numberPlatesFee ?? this.numberPlatesFee,
      thirdPartyInsurance: thirdPartyInsurance ?? this.thirdPartyInsurance,
      agencyFees: agencyFees ?? this.agencyFees,
      secondInstallmentUGX: secondInstallmentUGX ?? this.secondInstallmentUGX,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      balanceAmount: balanceAmount ?? this.balanceAmount,
      carAmount: carAmount ?? this.carAmount,
      downPayment: downPayment ?? this.downPayment,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      taxRate: taxRate ?? this.taxRate,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Invoice{id: $id, invoiceNumber: $invoiceNumber, customerId: $customerId, totalAmount: $totalAmount, status: $status}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Invoice && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Empty invoice factory
  static Invoice empty() {
    return Invoice(
      id: 0,
      invoiceNumber: '',
      invoiceType: InvoiceType.invoice,
      customerId: 0,
      invoiceDate: DateTime.now(),
      dueDate: DateTime.now(),
      status: InvoiceStatus.draft,
      totalAmount: 0.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}