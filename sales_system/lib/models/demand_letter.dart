enum DemandLetterStatus {
  draft,
  sent,
  acknowledged,
  resolved,
  escalated,
}

enum DemandLetterTemplate {
  firstNotice,
  secondNotice,
  finalNotice,
  legalNotice,
}

class DemandLetter {
  final int? id;
  final int invoiceId;
  final int customerId;
  final String letterNumber;
  final DateTime issueDate;
  final DateTime dueDate;
  final double amount;
  final double interestRate;
  final int daysOverdue;
  final DemandLetterStatus status;
  final String subject;
  final String content;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  DemandLetter({
    this.id,
    required this.invoiceId,
    required this.customerId,
    required this.letterNumber,
    required this.issueDate,
    required this.dueDate,
    required this.amount,
    this.interestRate = 0.0,
    this.daysOverdue = 0,
    this.status = DemandLetterStatus.draft,
    required this.subject,
    required this.content,
    this.notes = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Calculate interest amount
  double get interestAmount {
    return amount * interestRate / 100;
  }

  // Calculate total amount with interest
  double get totalAmount {
    return amount + interestAmount;
  }

  // Get status display text
  String get statusText {
    switch (status) {
      case DemandLetterStatus.draft:
        return 'Draft';
      case DemandLetterStatus.sent:
        return 'Sent';
      case DemandLetterStatus.acknowledged:
        return 'Acknowledged';
      case DemandLetterStatus.resolved:
        return 'Resolved';
      case DemandLetterStatus.escalated:
        return 'Escalated';
    }
  }

  // Get status color
  String get statusColor {
    switch (status) {
      case DemandLetterStatus.draft:
        return 'gray';
      case DemandLetterStatus.sent:
        return 'blue';
      case DemandLetterStatus.acknowledged:
        return 'orange';
      case DemandLetterStatus.resolved:
        return 'green';
      case DemandLetterStatus.escalated:
        return 'red';
    }
  }

  // Check if letter is overdue
  bool get isOverdue {
    return DateTime.now().isAfter(dueDate);
  }

  // Get formatted amount
  String get formattedAmount {
    return '\$${amount.toStringAsFixed(2)}';
  }

  // Get formatted total amount
  String get formattedTotalAmount {
    return '\$${totalAmount.toStringAsFixed(2)}';
  }

  // Convert DemandLetter to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceId': invoiceId,
      'customerId': customerId,
      'letterNumber': letterNumber,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'amount': amount,
      'interestRate': interestRate,
      'daysOverdue': daysOverdue,
      'status': status.name,
      'subject': subject,
      'content': content,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create DemandLetter from Map (database retrieval)
  factory DemandLetter.fromMap(Map<String, dynamic> map) {
    return DemandLetter(
      id: map['id'],
      invoiceId: map['invoiceId'],
      customerId: map['customerId'],
      letterNumber: map['letterNumber'],
      issueDate: DateTime.parse(map['issueDate']),
      dueDate: DateTime.parse(map['dueDate']),
      amount: map['amount']?.toDouble() ?? 0.0,
      interestRate: map['interestRate']?.toDouble() ?? 0.0,
      daysOverdue: map['daysOverdue'] ?? 0,
      status: DemandLetterStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DemandLetterStatus.draft,
      ),
      subject: map['subject'],
      content: map['content'],
      notes: map['notes'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // Create a copy of DemandLetter with updated fields
  DemandLetter copyWith({
    int? id,
    int? invoiceId,
    int? customerId,
    String? letterNumber,
    DateTime? issueDate,
    DateTime? dueDate,
    double? amount,
    double? interestRate,
    int? daysOverdue,
    DemandLetterStatus? status,
    String? subject,
    String? content,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DemandLetter(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      customerId: customerId ?? this.customerId,
      letterNumber: letterNumber ?? this.letterNumber,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      amount: amount ?? this.amount,
      interestRate: interestRate ?? this.interestRate,
      daysOverdue: daysOverdue ?? this.daysOverdue,
      status: status ?? this.status,
      subject: subject ?? this.subject,
      content: content ?? this.content,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'DemandLetter{id: $id, letterNumber: $letterNumber, amount: $amount, status: $status}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DemandLetter && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}