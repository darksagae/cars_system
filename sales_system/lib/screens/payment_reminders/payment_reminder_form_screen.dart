import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/payment_reminder.dart';
import '../../models/invoice.dart';
import '../../models/customer.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/payment_reminder_provider.dart';
import '../../services/reminders/payment_reminder_service.dart';
import '../../utils/uganda_formatters.dart';
import '../../widgets/glass_container.dart';
import '../../providers/theme_provider.dart';

class PaymentReminderFormScreen extends StatefulWidget {
  final PaymentReminder? paymentReminder;
  final Invoice? invoice;

  const PaymentReminderFormScreen({
    super.key,
    this.paymentReminder,
    this.invoice,
  });

  @override
  State<PaymentReminderFormScreen> createState() => _PaymentReminderFormScreenState();
}

class _PaymentReminderFormScreenState extends State<PaymentReminderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reminderService = PaymentReminderService();

  // Controllers
  late TextEditingController _subjectController;
  late TextEditingController _messageController;
  late TextEditingController _notesController;
  late TextEditingController _daysBeforeDueController;
  late TextEditingController _daysAfterDueController;

  // Form data
  Invoice? _selectedInvoice;
  Customer? _selectedCustomer;
  ReminderType _selectedType = ReminderType.email;
  ReminderTemplate _selectedTemplate = ReminderTemplate.friendly;
  ReminderFrequency _selectedFrequency = ReminderFrequency.once;
  DateTime _scheduledDate = DateTime.now();
  bool _isRecurring = false;

  bool _isLoading = false;
  bool _isEdit = false;
  bool _sendImmediately = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.paymentReminder != null;
    _initializeControllers();
    _loadData();
  }

  void _initializeControllers() {
    _subjectController = TextEditingController();
    _messageController = TextEditingController();
    _notesController = TextEditingController();
    _daysBeforeDueController = TextEditingController();
    _daysAfterDueController = TextEditingController();

    if (_isEdit) {
      final reminder = widget.paymentReminder!;
      _subjectController.text = reminder.subject;
      _messageController.text = reminder.message;
      _notesController.text = reminder.notes;
      _daysBeforeDueController.text = reminder.daysBeforeDue.toString();
      _daysAfterDueController.text = reminder.daysAfterDue.toString();
      _selectedType = reminder.type;
      _selectedTemplate = ReminderTemplate.friendly; // Default template since model doesn't have template field
      _selectedFrequency = reminder.frequency;
      _scheduledDate = reminder.scheduledDate;
      _isRecurring = reminder.isRecurring;
    }
  }

  void _loadData() {
    Provider.of<InvoiceProvider>(context, listen: false).loadInvoices();
    Provider.of<CustomerProvider>(context, listen: false).loadCustomers();
    
    if (widget.invoice != null) {
      _selectedInvoice = widget.invoice;
      _selectedCustomer = widget.invoice!.customer;
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _notesController.dispose();
    _daysBeforeDueController.dispose();
    _daysAfterDueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
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
              _isEdit ? 'Edit Payment Reminder' : 'Create Payment Reminder',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              if (_isEdit)
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.trash, color: Colors.red),
                  onPressed: _deleteReminder,
                ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: themeProvider.backgroundGradient,
            ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildInvoiceSelection(),
                  const SizedBox(height: 24),
                  _buildTypeSelection(),
                  const SizedBox(height: 24),
                  _buildTemplateSelection(),
                  const SizedBox(height: 24),
                  _buildSchedulingSection(),
                  const SizedBox(height: 24),
                  _buildContentSection(),
                  const SizedBox(height: 24),
                  _buildNotesSection(),
                  const SizedBox(height: 32),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
        );
      },
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
                const FaIcon(
                  FontAwesomeIcons.bell,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  _isEdit ? 'Edit Payment Reminder' : 'Create Payment Reminder',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _isEdit 
                ? 'Update payment reminder details'
                : 'Create a new payment reminder for customers',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceSelection() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invoice Selection',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Consumer<InvoiceProvider>(
              builder: (context, provider, child) {
                return DropdownButtonFormField<Invoice>(
                  value: _selectedInvoice,
                  decoration: InputDecoration(
                    labelText: 'Select Invoice',
                    labelStyle: GoogleFonts.poppins(color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                  dropdownColor: Colors.grey[800],
                  style: GoogleFonts.poppins(color: Colors.white),
                  items: provider.invoices.map((invoice) {
                    return DropdownMenuItem<Invoice>(
                      value: invoice,
                      child: Text(
                        '${invoice.invoiceNumber} - ${UgandaFormatters.formatCurrency(invoice.totalAmount)}',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (Invoice? invoice) {
                    setState(() {
                      _selectedInvoice = invoice;
                      if (invoice != null) {
                        _selectedCustomer = invoice.customer;
                        // Auto-generate content when invoice is selected
                        _generateContent();
                      }
                    });
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelection() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reminder Type',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ReminderType>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'Select Type',
                labelStyle: GoogleFonts.poppins(color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white, width: 2),
                ),
              ),
              dropdownColor: Colors.grey[800],
              style: GoogleFonts.poppins(color: Colors.white),
              items: ReminderType.values.map((type) {
                return DropdownMenuItem<ReminderType>(
                  value: type,
                  child: Row(
                    children: [
                      FaIcon(
                        _getTypeIcon(type),
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        type.name.toUpperCase(),
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (ReminderType? type) {
                setState(() {
                  _selectedType = type!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateSelection() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Template Selection',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ReminderTemplate>(
              value: _selectedTemplate,
              decoration: InputDecoration(
                labelText: 'Select Template',
                labelStyle: GoogleFonts.poppins(color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white, width: 2),
                ),
              ),
              dropdownColor: Colors.grey[800],
              style: GoogleFonts.poppins(color: Colors.white),
              items: ReminderTemplate.values.map((template) {
                return DropdownMenuItem<ReminderTemplate>(
                  value: template,
                  child: Text(
                    template.name.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim(),
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (ReminderTemplate? template) {
                setState(() {
                  _selectedTemplate = template!;
                  _generateContent();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulingSection() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scheduling',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(
                'Scheduled Date',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              subtitle: Text(
                UgandaFormatters.formatDate(_scheduledDate),
                style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8)),
              ),
              trailing: const FaIcon(
                FontAwesomeIcons.calendar,
                color: Colors.white,
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _scheduledDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    _scheduledDate = date;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _daysBeforeDueController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Days Before Due',
                      labelStyle: GoogleFonts.poppins(color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _daysAfterDueController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Days After Due',
                      labelStyle: GoogleFonts.poppins(color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _isRecurring,
                  onChanged: (value) {
                    setState(() {
                      _isRecurring = value ?? false;
                    });
                  },
                  activeColor: Colors.blue,
                ),
                Text(
                  'Recurring Reminder',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                const Spacer(),
                if (_isRecurring)
                  Expanded(
                    child: DropdownButtonFormField<ReminderFrequency>(
                      value: _selectedFrequency,
                      decoration: InputDecoration(
                        labelText: 'Frequency',
                        labelStyle: GoogleFonts.poppins(color: Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white, width: 2),
                        ),
                      ),
                      dropdownColor: Colors.grey[800],
                      style: GoogleFonts.poppins(color: Colors.white),
                      items: ReminderFrequency.values.map((frequency) {
                        return DropdownMenuItem<ReminderFrequency>(
                          value: frequency,
                          child: Text(
                            frequency.name.toUpperCase(),
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (ReminderFrequency? frequency) {
                        setState(() {
                          _selectedFrequency = frequency!;
                        });
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _sendImmediately,
                  onChanged: (value) {
                    setState(() {
                      _sendImmediately = value ?? false;
                    });
                  },
                  activeColor: Colors.green,
                ),
                Expanded(
                  child: Text(
                    'Send Immediately (Skip scheduling)',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
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
            Row(
              children: [
                Text(
                  'Content',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _generateContent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Generate Content'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _subjectController,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Subject',
                labelStyle: GoogleFonts.poppins(color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageController,
              maxLines: 6,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Message',
                labelStyle: GoogleFonts.poppins(color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Additional Notes',
                labelStyle: GoogleFonts.poppins(color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveReminder,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    _isEdit ? 'Update Reminder' : 'Create Reminder',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
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

  void _generateContent() {
    if (_selectedInvoice == null || _selectedCustomer == null) return;

    final template = _reminderService.getReminderTemplate(
      _selectedInvoice!,
      _selectedCustomer!,
      _selectedType,
    );

    // Generate dynamic subject based on invoice status and days overdue
    final daysOverdue = _selectedInvoice!.dueDate.difference(DateTime.now()).inDays;
    String subject;
    if (daysOverdue < 0) {
      subject = 'URGENT: Overdue Payment - Invoice ${_selectedInvoice!.invoiceNumber}';
    } else if (daysOverdue <= 7) {
      subject = 'Payment Due Soon - Invoice ${_selectedInvoice!.invoiceNumber}';
    } else {
      subject = 'Payment Reminder - Invoice ${_selectedInvoice!.invoiceNumber}';
    }

    setState(() {
      _subjectController.text = subject;
      _messageController.text = template;
    });
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedInvoice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an invoice'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final reminderNumber = 'REM-${DateTime.now().millisecondsSinceEpoch}';
      
      final reminder = PaymentReminder(
        id: _isEdit ? widget.paymentReminder!.id : null,
        invoiceId: _selectedInvoice!.id!,
        customerId: _selectedInvoice!.customerId,
        reminderNumber: _isEdit ? widget.paymentReminder!.reminderNumber : reminderNumber,
        type: _selectedType,
        scheduledDate: _scheduledDate,
        subject: _subjectController.text,
        message: _messageController.text,
        frequency: _selectedFrequency,
        daysBeforeDue: int.tryParse(_daysBeforeDueController.text) ?? 0,
        daysAfterDue: int.tryParse(_daysAfterDueController.text) ?? 0,
        isRecurring: _isRecurring,
        notes: _notesController.text,
      );

      if (_isEdit) {
        await _reminderService.updateReminder(reminder);
      } else {
        await _reminderService.createReminder(reminder);
      }

      // Send immediately if requested
      if (_sendImmediately && !_isEdit) {
        try {
          await _reminderService.sendReminder(reminder, _selectedInvoice!, _selectedCustomer!);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Reminder created and sent successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Reminder created but failed to send: ${e.toString()}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEdit ? 'Reminder updated successfully' : 'Reminder created successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      Provider.of<PaymentReminderProvider>(context, listen: false).loadReminders();

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteReminder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Payment Reminder'),
        content: Text('Are you sure you want to delete this payment reminder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _reminderService.deleteReminder(widget.paymentReminder!.id!);
        Provider.of<PaymentReminderProvider>(context, listen: false).loadReminders();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment reminder deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting reminder: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

