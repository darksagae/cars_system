enum ReminderType {
  email,
  sms,
  whatsapp,
  phone,
  letter,
}

enum ReminderStatus {
  scheduled,
  sent,
  delivered,
  failed,
  cancelled,
}

enum ReminderFrequency {
  once,
  daily,
  weekly,
  monthly,
}

enum ReminderTemplate {
  friendly,
  formal,
  urgent,
  finalNotice,
  legalNotice,
}

class PaymentReminder {
  final int? id;
  final int invoiceId;
  final int customerId;
  final String reminderNumber;
  final ReminderType type;
  final ReminderStatus status;
  final DateTime scheduledDate;
  final DateTime? sentDate;
  final String subject;
  final String message;
  final ReminderFrequency frequency;
  final int daysBeforeDue;
  final int daysAfterDue;
  final bool isRecurring;
  final DateTime? nextReminderDate;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentReminder({
    this.id,
    required this.invoiceId,
    required this.customerId,
    required this.reminderNumber,
    required this.type,
    this.status = ReminderStatus.scheduled,
    required this.scheduledDate,
    this.sentDate,
    required this.subject,
    required this.message,
    this.frequency = ReminderFrequency.once,
    this.daysBeforeDue = 0,
    this.daysAfterDue = 0,
    this.isRecurring = false,
    this.nextReminderDate,
    this.notes = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Get type display text
  String get typeText {
    switch (type) {
      case ReminderType.email:
        return 'Email';
      case ReminderType.sms:
        return 'SMS';
      case ReminderType.whatsapp:
        return 'WhatsApp';
      case ReminderType.phone:
        return 'Phone Call';
      case ReminderType.letter:
        return 'Letter';
    }
  }

  // Get status display text
  String get statusText {
    switch (status) {
      case ReminderStatus.scheduled:
        return 'Scheduled';
      case ReminderStatus.sent:
        return 'Sent';
      case ReminderStatus.delivered:
        return 'Delivered';
      case ReminderStatus.failed:
        return 'Failed';
      case ReminderStatus.cancelled:
        return 'Cancelled';
    }
  }

  // Get status color
  String get statusColor {
    switch (status) {
      case ReminderStatus.scheduled:
        return 'blue';
      case ReminderStatus.sent:
        return 'orange';
      case ReminderStatus.delivered:
        return 'green';
      case ReminderStatus.failed:
        return 'red';
      case ReminderStatus.cancelled:
        return 'gray';
    }
  }

  // Get frequency display text
  String get frequencyText {
    switch (frequency) {
      case ReminderFrequency.once:
        return 'Once';
      case ReminderFrequency.daily:
        return 'Daily';
      case ReminderFrequency.weekly:
        return 'Weekly';
      case ReminderFrequency.monthly:
        return 'Monthly';
    }
  }

  // Check if reminder is overdue
  bool get isOverdue {
    return status == ReminderStatus.scheduled && 
           DateTime.now().isAfter(scheduledDate);
  }

  // Check if reminder is sent
  bool get isSent {
    return status == ReminderStatus.sent || 
           status == ReminderStatus.delivered;
  }

  // Check if reminder is failed
  bool get isFailed {
    return status == ReminderStatus.failed;
  }

  // Convert PaymentReminder to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'customer_id': customerId,
      'reminder_number': reminderNumber,
      'type': type.name,
      'status': status.name,
      'scheduled_date': scheduledDate.toIso8601String(),
      'sent_date': sentDate?.toIso8601String(),
      'subject': subject,
      'message': message,
      'frequency': frequency.name,
      'days_before_due': daysBeforeDue,
      'days_after_due': daysAfterDue,
      'is_recurring': isRecurring ? 1 : 0,
      'next_reminder_date': nextReminderDate?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create PaymentReminder from Map (database retrieval)
  factory PaymentReminder.fromMap(Map<String, dynamic> map) {
    return PaymentReminder(
      id: map['id'],
      invoiceId: map['invoice_id'],
      customerId: map['customer_id'],
      reminderNumber: map['reminder_number'],
      type: ReminderType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ReminderType.email,
      ),
      status: ReminderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ReminderStatus.scheduled,
      ),
      scheduledDate: DateTime.parse(map['scheduled_date']),
      sentDate: map['sent_date'] != null ? DateTime.parse(map['sent_date']) : null,
      subject: map['subject'],
      message: map['message'],
      frequency: ReminderFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
        orElse: () => ReminderFrequency.once,
      ),
      daysBeforeDue: map['days_before_due'] ?? 0,
      daysAfterDue: map['days_after_due'] ?? 0,
      isRecurring: map['is_recurring'] == 1,
      nextReminderDate: map['next_reminder_date'] != null 
          ? DateTime.parse(map['next_reminder_date']) 
          : null,
      notes: map['notes'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  // Create a copy of PaymentReminder with updated fields
  PaymentReminder copyWith({
    int? id,
    int? invoiceId,
    int? customerId,
    String? reminderNumber,
    ReminderType? type,
    ReminderStatus? status,
    DateTime? scheduledDate,
    DateTime? sentDate,
    String? subject,
    String? message,
    ReminderFrequency? frequency,
    int? daysBeforeDue,
    int? daysAfterDue,
    bool? isRecurring,
    DateTime? nextReminderDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentReminder(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      customerId: customerId ?? this.customerId,
      reminderNumber: reminderNumber ?? this.reminderNumber,
      type: type ?? this.type,
      status: status ?? this.status,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      sentDate: sentDate ?? this.sentDate,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      frequency: frequency ?? this.frequency,
      daysBeforeDue: daysBeforeDue ?? this.daysBeforeDue,
      daysAfterDue: daysAfterDue ?? this.daysAfterDue,
      isRecurring: isRecurring ?? this.isRecurring,
      nextReminderDate: nextReminderDate ?? this.nextReminderDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'PaymentReminder{id: $id, reminderNumber: $reminderNumber, type: $type, status: $status}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentReminder && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}