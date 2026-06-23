
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/demand_letter.dart';
import '../../providers/demand_letter_provider.dart';
import '../../widgets/glass_container.dart';

class DemandLetterDetailScreen extends StatelessWidget {
  final DemandLetter demandLetter;

  const DemandLetterDetailScreen({super.key, required this.demandLetter});

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
          'Demand Letter Details',
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
                child: Row(
                  children: [
                    FaIcon(FontAwesomeIcons.pen, size: 14),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'send',
                child: Row(
                  children: [
                    FaIcon(FontAwesomeIcons.paperPlane, size: 14),
                    SizedBox(width: 8),
                    Text('Send'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    FaIcon(FontAwesomeIcons.filePdf, size: 14),
                    SizedBox(width: 8),
                    Text('Generate PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    FaIcon(FontAwesomeIcons.trash, size: 14),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
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
              _buildDemandLetterInfo(),
              const SizedBox(height: 24),
              _buildContentSection(),
              const SizedBox(height: 24),
              _buildQuickActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemandLetterInfo() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor(demandLetter.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FaIcon(
                  _getTemplateIcon(demandLetter.status),
                  color: _getStatusColor(demandLetter.status),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      demandLetter.letterNumber,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      demandLetter.subject,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${demandLetter.totalAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(demandLetter.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      demandLetter.statusText,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _getStatusColor(demandLetter.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoGrid(),
        ],
      ),
    );
  }

  Widget _buildInfoGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                'Issue Date',
                _formatDate(demandLetter.issueDate),
                FontAwesomeIcons.calendar,
              ),
            ),
            Expanded(
              child: _buildInfoItem(
                'Due Date',
                _formatDate(demandLetter.dueDate),
                FontAwesomeIcons.clock,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                'Days Overdue',
                '${demandLetter.daysOverdue} days',
                FontAwesomeIcons.exclamationTriangle,
              ),
            ),
            Expanded(
              child: _buildInfoItem(
                'Interest Rate',
                '${demandLetter.interestRate.toStringAsFixed(2)}%',
                FontAwesomeIcons.percent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                'Original Amount',
                '\$${demandLetter.amount.toStringAsFixed(2)}',
                FontAwesomeIcons.dollarSign,
              ),
            ),
            Expanded(
              child: _buildInfoItem(
                'Interest Amount',
                '\$${demandLetter.interestAmount.toStringAsFixed(2)}',
                FontAwesomeIcons.calculator,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                'Total Amount',
                '\$${demandLetter.totalAmount.toStringAsFixed(2)}',
                FontAwesomeIcons.moneyBill,
              ),
            ),
            Expanded(
              child: _buildInfoItem(
                'Urgency',
                demandLetter.urgencyLevel,
                FontAwesomeIcons.fire,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(
                icon,
                color: Colors.white.withOpacity(0.7),
                size: 14,
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
    );
  }

  Widget _buildContentSection() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Letter Content',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              demandLetter.content,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
            ),
          ),
          if (demandLetter.notes != null && demandLetter.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
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
              ),
              child: Text(
                demandLetter.notes!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          ],
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Send Letter',
                  FontAwesomeIcons.paperPlane,
                  Colors.blue,
                  () => _sendDemandLetter(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Generate PDF',
                  FontAwesomeIcons.filePdf,
                  Colors.red,
                  () => _generatePDF(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Mark as Delivered',
                  FontAwesomeIcons.checkCircle,
                  Colors.green,
                  () => _markAsDelivered(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Mark as Paid',
                  FontAwesomeIcons.moneyBill,
                  Colors.green,
                  () => _markAsPaid(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              FaIcon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'sent':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'acknowledged':
        return Colors.purple;
      case 'paid':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      case 'cancelled':
        return Colors.orange;
      default:
        return Colors.white;
    }
  }

  IconData _getTemplateIcon(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return FontAwesomeIcons.fileLines;
      case 'sent':
        return FontAwesomeIcons.paperPlane;
      case 'delivered':
        return FontAwesomeIcons.checkCircle;
      case 'acknowledged':
        return FontAwesomeIcons.handshake;
      case 'paid':
        return FontAwesomeIcons.moneyBill;
      case 'overdue':
        return FontAwesomeIcons.exclamationTriangle;
      case 'cancelled':
        return FontAwesomeIcons.xmark;
      default:
        return FontAwesomeIcons.fileLines;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        // Navigate to edit screen
        break;
      case 'send':
        _sendDemandLetter(context);
        break;
      case 'pdf':
        _generatePDF(context);
        break;
      case 'delete':
        _showDeleteDialog(context);
        break;
    }
  }

  void _sendDemandLetter(BuildContext context) {
    context.read<DemandLetterProvider>().sendDemandLetter(demandLetter.id!);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Demand letter sent successfully',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green.withOpacity(0.8),
      ),
    );
  }

  void _generatePDF(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'PDF generation coming soon',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.blue.withOpacity(0.8),
      ),
    );
  }

  void _markAsDelivered(BuildContext context) {
    context.read<DemandLetterProvider>().markAsDelivered(demandLetter.id!);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Demand letter marked as delivered',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green.withOpacity(0.8),
      ),
    );
  }

  void _markAsPaid(BuildContext context) {
    context.read<DemandLetterProvider>().markAsPaid(demandLetter.id!);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Demand letter marked as paid',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green.withOpacity(0.8),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
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
                'Delete Demand Letter',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete this demand letter?',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
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
                        context.read<DemandLetterProvider>().deleteDemandLetter(demandLetter.id!);
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
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

