enum PaymentMethod {
  cash,
  check,
  bank_transfer,
  credit_card,
  mobile_money,
  cheque,
  debitCard,
  paypal,
  other,
}

enum PaymentStatus {
  pending,
  completed,
  failed,
  cancelled,
  refunded,
}

class Payment {
  final int? id;
  final int? invoiceId;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final DateTime paymentDate;
  final String? reference;
  final String? referenceNumber;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Payment({
    this.id,
    this.invoiceId,
    required this.amount,
    required this.method,
    this.status = PaymentStatus.pending,
    required this.paymentDate,
    this.reference,
    this.referenceNumber,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Get method display text
  String get methodText {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.check:
        return 'Check';
      case PaymentMethod.bank_transfer:
        return 'Bank Transfer';
      case PaymentMethod.credit_card:
        return 'Credit Card';
      case PaymentMethod.mobile_money:
        return 'Mobile Money';
      case PaymentMethod.cheque:
        return 'Cheque';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.other:
        return 'Other';
    }
  }

  // Get status display text
  String get statusText {
    switch (status) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  // Get status color
  String get statusColor {
    switch (status) {
      case PaymentStatus.pending:
        return 'orange';
      case PaymentStatus.completed:
        return 'green';
      case PaymentStatus.failed:
        return 'red';
      case PaymentStatus.cancelled:
        return 'gray';
      case PaymentStatus.refunded:
        return 'blue';
    }
  }

  // Check if payment is completed
  bool get isCompleted {
    return status == PaymentStatus.completed;
  }

  // Get formatted amount
  String get formattedAmount {
    return '\$${amount.toStringAsFixed(2)}';
  }

  // Convert Payment to Map for database storage
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'invoiceId': invoiceId,
      'amount': amount,
      'method': method.index,
      'status': status.index,
      'paymentDate': paymentDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
    
    // Only include id if it's not null and not 0 (for inserts, exclude id to use AUTOINCREMENT)
    if (id != null && id! > 0) {
      map['id'] = id;
    }
    
    // Include optional fields if they have values
    if (reference != null && reference!.isNotEmpty) {
      map['reference'] = reference;
    }
    if (referenceNumber != null && referenceNumber!.isNotEmpty) {
      map['referenceNumber'] = referenceNumber;
    }
    if (notes != null && notes!.isNotEmpty) {
      map['notes'] = notes;
    }
    
    return map;
  }

  // Create Payment from Map (database retrieval)
  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      invoiceId: map['invoiceId'],
      amount: map['amount']?.toDouble() ?? 0.0,
      method: PaymentMethod.values[map['method']],
      status: PaymentStatus.values[map['status']],
      paymentDate: DateTime.parse(map['paymentDate']),
      reference: map['reference'],
      referenceNumber: map['referenceNumber'],
      notes: map['notes'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // Create a copy of Payment with updated fields
  Payment copyWith({
    int? id,
    int? invoiceId,
    double? amount,
    PaymentMethod? method,
    PaymentStatus? status,
    DateTime? paymentDate,
    String? reference,
    String? referenceNumber,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      status: status ?? this.status,
      paymentDate: paymentDate ?? this.paymentDate,
      reference: reference ?? this.reference,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Payment{id: $id, invoiceId: $invoiceId, amount: $amount, method: $method, status: $status}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Payment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}