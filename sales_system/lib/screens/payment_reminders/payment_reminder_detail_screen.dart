import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/payment_reminder.dart';
import '../../utils/uganda_formatters.dart';
import '../../widgets/glass_container.dart';
import 'payment_reminder_form_screen.dart';
import '../../providers/theme_provider.dart';

class PaymentReminderDetailScreen extends StatelessWidget {
  final PaymentReminder paymentReminder;

  const PaymentReminderDetailScreen({
    super.key,
    required this.paymentReminder,
  });

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
          PopupMenuButton<String>(
            icon: const FaIcon(FontAwesomeIcons.ellipsisVertical, color: Colors.white),
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Text('Edit Reminder'),
              ),
              const PopupMenuItem(
                value: 'send',
                child: Text('Send Now'),
              ),
              const PopupMenuItem(
                value: 'reschedule',
                child: Text('Reschedule'),
              ),
              const PopupMenuItem(
                value: 'cancel',
                child: Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A0A), // Pure black background
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildBasicInfo(),
                const SizedBox(height: 24),
                _buildSchedulingInfo(),
                const SizedBox(height: 24),
                _buildContentSection(),
                const SizedBox(height: 24),
                _buildQuickActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(
                  _getTypeIcon(paymentReminder.type),
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paymentReminder.reminderNumber,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        paymentReminder.subject,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(paymentReminder.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Type', paymentReminder.typeText),
            _buildInfoRow('Status', paymentReminder.statusText),
            _buildInfoRow('Frequency', paymentReminder.frequency.name.toUpperCase()),
            if (paymentReminder.isRecurring)
              _buildInfoRow('Recurring', 'Yes'),
            if (paymentReminder.sentDate != null)
              _buildInfoRow('Sent Date', UgandaFormatters.formatDate(paymentReminder.sentDate!)),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulingInfo() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scheduling Information',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Scheduled Date', UgandaFormatters.formatDate(paymentReminder.scheduledDate)),
            _buildInfoRow('Days Before Due', paymentReminder.daysBeforeDue.toString()),
            _buildInfoRow('Days After Due', paymentReminder.daysAfterDue.toString()),
            if (paymentReminder.nextReminderDate != null)
              _buildInfoRow('Next Reminder', UgandaFormatters.formatDate(paymentReminder.nextReminderDate!)),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Message Content',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Subject:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              paymentReminder.subject,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Message:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              paymentReminder.message,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            if (paymentReminder.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Notes:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                paymentReminder.notes,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Edit',
                    FontAwesomeIcons.pen,
                    Colors.blue,
                    () => _editReminder(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Send Now',
                    FontAwesomeIcons.paperPlane,
                    Colors.green,
                    () => _sendReminder(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Reschedule',
                    FontAwesomeIcons.calendar,
                    Colors.orange,
                    () => _rescheduleReminder(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ReminderStatus status) {
    Color statusColor;
    switch (status) {
      case ReminderStatus.scheduled:
        statusColor = Colors.blue;
        break;
      case ReminderStatus.sent:
        statusColor = Colors.orange;
        break;
      case ReminderStatus.delivered:
        statusColor = Colors.green;
        break;
      case ReminderStatus.failed:
        statusColor = Colors.red;
        break;
      case ReminderStatus.cancelled:
        statusColor = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: statusColor,
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        children: [
          FaIcon(icon, size: 16),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(ReminderType type) {
    switch (type) {
      case ReminderType.email:
        return FontAwesomeIcons.envelope;
      case ReminderType.sms:
        return FontAwesomeIcons.sms;
      case ReminderType.whatsapp:
        return FontAwesomeIcons.whatsapp;
      case ReminderType.phone:
        return FontAwesomeIcons.phone;
      case ReminderType.letter:
        return FontAwesomeIcons.fileLines;
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        _editReminder(context);
        break;
      case 'send':
        _sendReminder(context);
        break;
      case 'reschedule':
        _rescheduleReminder(context);
        break;
      case 'cancel':
        _cancelReminder(context);
        break;
    }
  }

  void _editReminder(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentReminderFormScreen(
          paymentReminder: paymentReminder,
        ),
      ),
    );
  }

  void _sendReminder(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send Reminder'),
        content: Text('Are you sure you want to send this reminder now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement send reminder logic
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Reminder sent successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Send'),
          ),
        ],
      ),
    );
  }

  void _rescheduleReminder(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reschedule Reminder'),
        content: Text('Reschedule functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _cancelReminder(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Reminder'),
        content: Text('Are you sure you want to cancel this reminder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement cancel reminder logic
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Reminder cancelled successfully'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: Text('Yes'),
          ),
        ],
      ),
    );
  }
}
