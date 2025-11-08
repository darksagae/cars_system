
class PaymentReminderDetailScreen extends StatelessWidget {
  final PaymentReminder reminder;

  const PaymentReminderDetailScreen({super.key, required this.reminder});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Reminder Details',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.edit, color: Colors.white),
            onPressed: () => _editReminder(context),
          ),
          PopupMenuButton<String>(
            icon: const FaIcon(FontAwesomeIcons.ellipsisVertical, color: Colors.white),
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              if (reminder.status == ReminderStatus.scheduled) ...[
                const PopupMenuItem(
                  value: 'send',
                  child: ListTile(
                    leading: FaIcon(FontAwesomeIcons.play, color: Colors.white),
                    title: Text('Send Now', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const PopupMenuItem(
                  value: 'reschedule',
                  child: ListTile(
                    leading: FaIcon(FontAwesomeIcons.calendar, color: Colors.white),
                    title: Text('Reschedule', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const PopupMenuItem(
                  value: 'cancel',
                  child: ListTile(
                    leading: FaIcon(FontAwesomeIcons.xmark, color: Colors.red),
                    title: Text('Cancel', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: FaIcon(FontAwesomeIcons.trash, color: Colors.red),
                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildStatusCard(),
              const SizedBox(height: 24),
              _buildReminderInfo(),
              const SizedBox(height: 24),
              _buildContentSection(),
              const SizedBox(height: 24),
              _buildSchedulingInfo(),
              const SizedBox(height: 24),
              _buildQuickActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          reminder.subject,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Reminder #${reminder.reminderNumber}',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatusChip(reminder.status),
              const SizedBox(width: 12),
              _buildUrgencyChip(reminder.urgencyLevel),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoItem(
                'Type',
                reminder.typeText,
                _getTypeIcon(reminder.type),
                _getTypeColor(reminder.type),
              ),
              const SizedBox(width: 16),
              _buildInfoItem(
                'Frequency',
                reminder.frequencyText,
                FontAwesomeIcons.clock,
                Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ReminderStatus status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            _getStatusIcon(status),
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            status.name.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyChip(String urgency) {
    final color = _getUrgencyColor(urgency);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            _getUrgencyIcon(urgency),
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            urgency.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(
                  icon,
                  color: color,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderInfo() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reminder Information',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Invoice ID', '${reminder.invoiceId}'),
          _buildInfoRow('Customer ID', '${reminder.customerId}'),
          _buildInfoRow('Days Before Due', '${reminder.daysBeforeDue}'),
          _buildInfoRow('Days After Due', '${reminder.daysAfterDue}'),
          _buildInfoRow('Recurring', reminder.isRecurring ? 'Yes' : 'No'),
          if (reminder.nextReminderDate != null)
            _buildInfoRow('Next Reminder', _formatDate(reminder.nextReminderDate!)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Message Content',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Text(
              reminder.message,
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
            ),
          ),
          if (reminder.notes != null && reminder.notes!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Notes',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Text(
                reminder.notes!,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSchedulingInfo() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scheduling Information',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          _buildScheduleItem(
            'Scheduled Date',
            _formatDateTime(reminder.scheduledDate),
            FontAwesomeIcons.calendar,
            Colors.blue,
          ),
          if (reminder.sentDate != null)
            _buildScheduleItem(
              'Sent Date',
              _formatDateTime(reminder.sentDate!),
              FontAwesomeIcons.paperPlane,
              Colors.green,
            ),
          _buildScheduleItem(
            'Created',
            _formatDateTime(reminder.createdAt),
            FontAwesomeIcons.plus,
            Colors.orange,
          ),
          _buildScheduleItem(
            'Last Updated',
            _formatDateTime(reminder.updatedAt),
            FontAwesomeIcons.pen,
            Colors.purple,
          ),
          const SizedBox(height: 16),
          _buildTimeInfo(),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FaIcon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo() {
    final now = DateTime.now();
    final scheduled = reminder.scheduledDate;
    final difference = scheduled.difference(now);
    final days = difference.inDays;
    final hours = difference.inHours % 24;

    String timeText;
    Color timeColor;

    if (difference.isNegative) {
      timeText = 'Overdue by ${-days} day${-days == 1 ? '' : 's'}';
      timeColor = Colors.red;
    } else if (days == 0) {
      timeText = 'Due today';
      timeColor = Colors.orange;
    } else if (days == 1) {
      timeText = 'Due tomorrow';
      timeColor = Colors.yellow;
    } else {
      timeText = 'Due in $days day${days == 1 ? '' : 's'}';
      timeColor = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: timeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: timeColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          FaIcon(
            FontAwesomeIcons.clock,
            color: timeColor,
            size: 16,
          ),
          const SizedBox(width: 12),
          Text(
            timeText,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: timeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (reminder.status == ReminderStatus.scheduled) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _sendReminder(context),
                    icon: const FaIcon(FontAwesomeIcons.play, size: 16),
                    label: Text(
                      'Send Now',
                      style: GoogleFonts.poppins(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rescheduleReminder(context),
                    icon: const FaIcon(FontAwesomeIcons.calendar, size: 16),
                    label: Text(
                      'Reschedule',
                      style: GoogleFonts.poppins(),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editReminder(context),
                    icon: const FaIcon(FontAwesomeIcons.edit, size: 16),
                    label: Text(
                      'Edit',
                      style: GoogleFonts.poppins(),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.scheduled:
        return Colors.blue;
      case ReminderStatus.sent:
        return Colors.green;
      case ReminderStatus.delivered:
        return Colors.green;
      case ReminderStatus.failed:
        return Colors.red;
      case ReminderStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.scheduled:
        return FontAwesomeIcons.clock;
      case ReminderStatus.sent:
        return FontAwesomeIcons.paperPlane;
      case ReminderStatus.delivered:
        return FontAwesomeIcons.check;
      case ReminderStatus.failed:
        return FontAwesomeIcons.xmark;
      case ReminderStatus.cancelled:
        return FontAwesomeIcons.xmark;
    }
  }

  IconData _getTypeIcon(ReminderType type) {
    switch (type) {
      case ReminderType.email:
        return FontAwesomeIcons.envelope;
      case ReminderType.sms:
        return FontAwesomeIcons.message;
      case ReminderType.whatsapp:
        return FontAwesomeIcons.whatsapp;
      case ReminderType.phone:
        return FontAwesomeIcons.phone;
      case ReminderType.letter:
        return FontAwesomeIcons.fileLines;
    }
  }

  Color _getTypeColor(ReminderType type) {
    switch (type) {
      case ReminderType.email:
        return Colors.blue;
      case ReminderType.sms:
        return Colors.green;
      case ReminderType.whatsapp:
        return Colors.green;
      case ReminderType.phone:
        return Colors.orange;
      case ReminderType.letter:
        return Colors.purple;
    }
  }

  IconData _getUrgencyIcon(String urgency) {
    switch (urgency) {
      case 'Critical':
        return FontAwesomeIcons.exclamationTriangle;
      case 'High':
        return FontAwesomeIcons.exclamation;
      case 'Medium':
        return FontAwesomeIcons.info;
      case 'Low':
        return FontAwesomeIcons.check;
      default:
        return FontAwesomeIcons.circle;
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency) {
      case 'Critical':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.yellow;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Action methods
  void _editReminder(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentReminderFormScreen(reminder: reminder),
      ),
    );
  }

  void _sendReminder(BuildContext context) {
    context.read<PaymentReminderProvider>().sendReminder(reminder);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reminder sent successfully!',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green.withOpacity(0.8),
      ),
    );
  }

  void _rescheduleReminder(BuildContext context) {
    showDatePicker(
      context: context,
      initialDate: reminder.scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    ).then((date) {
      if (date != null) {
        context.read<PaymentReminderProvider>().rescheduleReminder(reminder, date);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reminder rescheduled successfully!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green.withOpacity(0.8),
          ),
        );
      }
    });
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'send':
        _sendReminder(context);
        break;
      case 'reschedule':
        _rescheduleReminder(context);
        break;
      case 'cancel':
        _cancelReminder(context);
        break;
      case 'delete':
        _deleteReminder(context);
        break;
    }
  }

  void _cancelReminder(BuildContext context) {
    context.read<PaymentReminderProvider>().cancelReminder(reminder);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reminder cancelled successfully!',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.orange.withOpacity(0.8),
      ),
    );
  }

  void _deleteReminder(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Delete Reminder',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete this reminder? This action cannot be undone.',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                        context.read<PaymentReminderProvider>().deleteReminder(reminder.id!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Reminder deleted successfully!',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: Colors.red.withOpacity(0.8),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Delete',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentReminderDetailScreen extends StatelessWidget {
  final PaymentReminder reminder;

  const PaymentReminderDetailScreen({super.key, required this.reminder});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Reminder Details',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.edit, color: Colors.white),
            onPressed: () => _editReminder(context),
          ),
          PopupMenuButton<String>(
            icon: const FaIcon(FontAwesomeIcons.ellipsisVertical, color: Colors.white),
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              if (reminder.status == ReminderStatus.scheduled) ...[
                const PopupMenuItem(
                  value: 'send',
                  child: ListTile(
                    leading: FaIcon(FontAwesomeIcons.play, color: Colors.white),
                    title: Text('Send Now', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const PopupMenuItem(
                  value: 'reschedule',
                  child: ListTile(
                    leading: FaIcon(FontAwesomeIcons.calendar, color: Colors.white),
                    title: Text('Reschedule', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const PopupMenuItem(
                  value: 'cancel',
                  child: ListTile(
                    leading: FaIcon(FontAwesomeIcons.xmark, color: Colors.red),
                    title: Text('Cancel', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: FaIcon(FontAwesomeIcons.trash, color: Colors.red),
                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildStatusCard(),
              const SizedBox(height: 24),
              _buildReminderInfo(),
              const SizedBox(height: 24),
              _buildContentSection(),
              const SizedBox(height: 24),
              _buildSchedulingInfo(),
              const SizedBox(height: 24),
              _buildQuickActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          reminder.subject,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Reminder #${reminder.reminderNumber}',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatusChip(reminder.status),
              const SizedBox(width: 12),
              _buildUrgencyChip(reminder.urgencyLevel),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoItem(
                'Type',
                reminder.typeText,
                _getTypeIcon(reminder.type),
                _getTypeColor(reminder.type),
              ),
              const SizedBox(width: 16),
              _buildInfoItem(
                'Frequency',
                reminder.frequencyText,
                FontAwesomeIcons.clock,
                Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ReminderStatus status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            _getStatusIcon(status),
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            status.name.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyChip(String urgency) {
    final color = _getUrgencyColor(urgency);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            _getUrgencyIcon(urgency),
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            urgency.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(
                  icon,
                  color: color,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderInfo() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reminder Information',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Invoice ID', '${reminder.invoiceId}'),
          _buildInfoRow('Customer ID', '${reminder.customerId}'),
          _buildInfoRow('Days Before Due', '${reminder.daysBeforeDue}'),
          _buildInfoRow('Days After Due', '${reminder.daysAfterDue}'),
          _buildInfoRow('Recurring', reminder.isRecurring ? 'Yes' : 'No'),
          if (reminder.nextReminderDate != null)
            _buildInfoRow('Next Reminder', _formatDate(reminder.nextReminderDate!)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Message Content',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Text(
              reminder.message,
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
            ),
          ),
          if (reminder.notes != null && reminder.notes!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Notes',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Text(
                reminder.notes!,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSchedulingInfo() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scheduling Information',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          _buildScheduleItem(
            'Scheduled Date',
            _formatDateTime(reminder.scheduledDate),
            FontAwesomeIcons.calendar,
            Colors.blue,
          ),
          if (reminder.sentDate != null)
            _buildScheduleItem(
              'Sent Date',
              _formatDateTime(reminder.sentDate!),
              FontAwesomeIcons.paperPlane,
              Colors.green,
            ),
          _buildScheduleItem(
            'Created',
            _formatDateTime(reminder.createdAt),
            FontAwesomeIcons.plus,
            Colors.orange,
          ),
          _buildScheduleItem(
            'Last Updated',
            _formatDateTime(reminder.updatedAt),
            FontAwesomeIcons.pen,
            Colors.purple,
          ),
          const SizedBox(height: 16),
          _buildTimeInfo(),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FaIcon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo() {
    final now = DateTime.now();
    final scheduled = reminder.scheduledDate;
    final difference = scheduled.difference(now);
    final days = difference.inDays;
    final hours = difference.inHours % 24;

    String timeText;
    Color timeColor;

    if (difference.isNegative) {
      timeText = 'Overdue by ${-days} day${-days == 1 ? '' : 's'}';
      timeColor = Colors.red;
    } else if (days == 0) {
      timeText = 'Due today';
      timeColor = Colors.orange;
    } else if (days == 1) {
      timeText = 'Due tomorrow';
      timeColor = Colors.yellow;
    } else {
      timeText = 'Due in $days day${days == 1 ? '' : 's'}';
      timeColor = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: timeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: timeColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          FaIcon(
            FontAwesomeIcons.clock,
            color: timeColor,
            size: 16,
          ),
          const SizedBox(width: 12),
          Text(
            timeText,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: timeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (reminder.status == ReminderStatus.scheduled) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _sendReminder(context),
                    icon: const FaIcon(FontAwesomeIcons.play, size: 16),
                    label: Text(
                      'Send Now',
                      style: GoogleFonts.poppins(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rescheduleReminder(context),
                    icon: const FaIcon(FontAwesomeIcons.calendar, size: 16),
                    label: Text(
                      'Reschedule',
                      style: GoogleFonts.poppins(),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editReminder(context),
                    icon: const FaIcon(FontAwesomeIcons.edit, size: 16),
                    label: Text(
                      'Edit',
                      style: GoogleFonts.poppins(),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.scheduled:
        return Colors.blue;
      case ReminderStatus.sent:
        return Colors.green;
      case ReminderStatus.delivered:
        return Colors.green;
      case ReminderStatus.failed:
        return Colors.red;
      case ReminderStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.scheduled:
        return FontAwesomeIcons.clock;
      case ReminderStatus.sent:
        return FontAwesomeIcons.paperPlane;
      case ReminderStatus.delivered:
        return FontAwesomeIcons.check;
      case ReminderStatus.failed:
        return FontAwesomeIcons.xmark;
      case ReminderStatus.cancelled:
        return FontAwesomeIcons.xmark;
    }
  }

  IconData _getTypeIcon(ReminderType type) {
    switch (type) {
      case ReminderType.email:
        return FontAwesomeIcons.envelope;
      case ReminderType.sms:
        return FontAwesomeIcons.message;
      case ReminderType.whatsapp:
        return FontAwesomeIcons.whatsapp;
      case ReminderType.phone:
        return FontAwesomeIcons.phone;
      case ReminderType.letter:
        return FontAwesomeIcons.fileLines;
    }
  }

  Color _getTypeColor(ReminderType type) {
    switch (type) {
      case ReminderType.email:
        return Colors.blue;
      case ReminderType.sms:
        return Colors.green;
      case ReminderType.whatsapp:
        return Colors.green;
      case ReminderType.phone:
        return Colors.orange;
      case ReminderType.letter:
        return Colors.purple;
    }
  }

  IconData _getUrgencyIcon(String urgency) {
    switch (urgency) {
      case 'Critical':
        return FontAwesomeIcons.exclamationTriangle;
      case 'High':
        return FontAwesomeIcons.exclamation;
      case 'Medium':
        return FontAwesomeIcons.info;
      case 'Low':
        return FontAwesomeIcons.check;
      default:
        return FontAwesomeIcons.circle;
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency) {
      case 'Critical':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.yellow;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Action methods
  void _editReminder(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentReminderFormScreen(reminder: reminder),
      ),
    );
  }

  void _sendReminder(BuildContext context) {
    context.read<PaymentReminderProvider>().sendReminder(reminder);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reminder sent successfully!',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green.withOpacity(0.8),
      ),
    );
  }

  void _rescheduleReminder(BuildContext context) {
    showDatePicker(
      context: context,
      initialDate: reminder.scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    ).then((date) {
      if (date != null) {
        context.read<PaymentReminderProvider>().rescheduleReminder(reminder, date);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reminder rescheduled successfully!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green.withOpacity(0.8),
          ),
        );
      }
    });
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'send':
        _sendReminder(context);
        break;
      case 'reschedule':
        _rescheduleReminder(context);
        break;
      case 'cancel':
        _cancelReminder(context);
        break;
      case 'delete':
        _deleteReminder(context);
        break;
    }
  }

  void _cancelReminder(BuildContext context) {
    context.read<PaymentReminderProvider>().cancelReminder(reminder);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reminder cancelled successfully!',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.orange.withOpacity(0.8),
      ),
    );
  }

  void _deleteReminder(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Delete Reminder',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete this reminder? This action cannot be undone.',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                        context.read<PaymentReminderProvider>().deleteReminder(reminder.id!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Reminder deleted successfully!',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: Colors.red.withOpacity(0.8),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Delete',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
