import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/demand_letter.dart';
import '../../models/invoice.dart';
import '../../models/customer.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/demand_letter_provider.dart';
import '../../services/demand_letter/demand_letter_service.dart';
import '../../utils/uganda_formatters.dart';
import '../../widgets/glass_container.dart';
import '../../providers/theme_provider.dart';
import '../widgets/glass_liquid_theme.dart';

class DemandLetterFormScreen extends StatefulWidget {
  final DemandLetter? demandLetter;
  final Invoice? invoice;

  const DemandLetterFormScreen({
    super.key,
    this.demandLetter,
    this.invoice,
  });

  @override
  State<DemandLetterFormScreen> createState() => _DemandLetterFormScreenState();
}

class _DemandLetterFormScreenState extends State<DemandLetterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _demandLetterService = DemandLetterService();

  // Controllers
  late TextEditingController _subjectController;
  late TextEditingController _contentController;
  late TextEditingController _notesController;
  late TextEditingController _amountController;
  late TextEditingController _interestRateController;
  late TextEditingController _daysOverdueController;

  // Form data
  Invoice? _selectedInvoice;
  Customer? _selectedCustomer;
  DemandLetterTemplate _selectedTemplate = DemandLetterTemplate.firstNotice;
  DateTime _issueDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  double _amount = 0.0;
  double _interestRate = 0.0;
  int _daysOverdue = 0;

  bool _isLoading = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.demandLetter != null;
    _initializeControllers();
    _loadData();
  }

  void _initializeControllers() {
    _subjectController = TextEditingController();
    _contentController = TextEditingController();
    _notesController = TextEditingController();
    _amountController = TextEditingController();
    _interestRateController = TextEditingController();
    _daysOverdueController = TextEditingController();

    if (_isEdit) {
      final letter = widget.demandLetter!;
      _subjectController.text = letter.subject;
      _contentController.text = letter.content;
      _notesController.text = letter.notes;
      _amountController.text = letter.amount.toString();
      _interestRateController.text = letter.interestRate.toString();
      _daysOverdueController.text = letter.daysOverdue.toString();
      _issueDate = letter.issueDate;
      _dueDate = letter.dueDate;
      _amount = letter.amount;
      _interestRate = letter.interestRate;
      _daysOverdue = letter.daysOverdue;
    }
  }

  void _loadData() {
    Provider.of<InvoiceProvider>(context, listen: false).loadInvoices();
    Provider.of<CustomerProvider>(context, listen: false).loadCustomers();
    
    if (widget.invoice != null) {
      _selectedInvoice = widget.invoice;
      _amount = widget.invoice!.totalAmount;
      _amountController.text = _amount.toString();
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _contentController.dispose();
    _notesController.dispose();
    _amountController.dispose();
    _interestRateController.dispose();
    _daysOverdueController.dispose();
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
              _isEdit ? 'Edit Demand Letter' : 'Create Demand Letter',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              if (_isEdit)
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.trash, color: Colors.red),
                  onPressed: _deleteDemandLetter,
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
                _buildTemplateSelection(),
                const SizedBox(height: 24),
                  _buildAmountSection(),
                  const SizedBox(height: 24),
                  _buildDateSection(),
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
                  FontAwesomeIcons.fileLines,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  _isEdit ? 'Edit Demand Letter' : 'Create Demand Letter',
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
                ? 'Update demand letter details'
                : 'Create a new demand letter for overdue payments',
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
                        _amount = invoice.totalAmount;
                        _amountController.text = _amount.toString();
                      _selectedCustomer = invoice.customer;
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
          DropdownButtonFormField<DemandLetterTemplate>(
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
            items: DemandLetterTemplate.values.map((template) {
              return DropdownMenuItem<DemandLetterTemplate>(
                value: template,
                child: Text(
                    template.name.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim(),
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              );
            }).toList(),
              onChanged: (DemandLetterTemplate? template) {
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

  Widget _buildAmountSection() {
    return GlassContainer(
      child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              'Amount & Interest',
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
                child: TextFormField(
                    controller: _amountController,
                  keyboardType: TextInputType.number,
                    style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                      labelText: 'Amount',
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
                    onChanged: (value) {
                      _amount = double.tryParse(value) ?? 0.0;
                    },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                    controller: _interestRateController,
                  keyboardType: TextInputType.number,
                    style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                      labelText: 'Interest Rate (%)',
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
                    onChanged: (value) {
                      _interestRate = double.tryParse(value) ?? 0.0;
                    },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
            TextFormField(
              controller: _daysOverdueController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Days Overdue',
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
              onChanged: (value) {
                _daysOverdue = int.tryParse(value) ?? 0;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
              'Dates',
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
                  child: ListTile(
                    title: Text(
                      'Issue Date',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    subtitle: Text(
                      UgandaFormatters.formatDate(_issueDate),
                      style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8)),
                    ),
                    trailing: const FaIcon(
                      FontAwesomeIcons.calendar,
                      color: Colors.white,
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _issueDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _issueDate = date;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ListTile(
                    title: Text(
                      'Due Date',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    subtitle: Text(
                      UgandaFormatters.formatDate(_dueDate),
                      style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8)),
                    ),
                    trailing: const FaIcon(
                      FontAwesomeIcons.calendar,
                      color: Colors.white,
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _dueDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _dueDate = date;
                        });
                      }
                    },
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
                    backgroundColor: GlassLiquidTheme.accentBlue,
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
              controller: _contentController,
              maxLines: 8,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Content',
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
            onPressed: _isLoading ? null : _saveDemandLetter,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    _isEdit ? 'Update Letter' : 'Create Letter',
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

  void _generateContent() async {
    if (_selectedInvoice == null || _selectedCustomer == null) return;

    final content = await _demandLetterService.generateDemandLetterContent(
      invoice: _selectedInvoice!,
      customer: _selectedCustomer!,
      template: _selectedTemplate,
      interestRate: _interestRate,
      daysOverdue: _daysOverdue,
    );

    setState(() {
      _subjectController.text = 'Payment Reminder - Invoice ${_selectedInvoice!.invoiceNumber}';
      _contentController.text = content;
    });
  }

  Future<void> _saveDemandLetter() async {
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
      final letterNumber = await _demandLetterService.generateDemandLetterNumber();
      
      final demandLetter = DemandLetter(
        id: _isEdit ? widget.demandLetter!.id : null,
        invoiceId: _selectedInvoice!.id!,
        customerId: _selectedInvoice!.customerId,
        letterNumber: _isEdit ? widget.demandLetter!.letterNumber : letterNumber,
        issueDate: _issueDate,
        dueDate: _dueDate,
        amount: _amount,
        interestRate: _interestRate,
        daysOverdue: _daysOverdue,
        subject: _subjectController.text,
        content: _contentController.text,
        notes: _notesController.text,
      );

      if (_isEdit) {
        await _demandLetterService.updateDemandLetter(demandLetter);
      } else {
        await _demandLetterService.createDemandLetter(demandLetter);
      }

      Provider.of<DemandLetterProvider>(context, listen: false).loadDemandLetters();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit ? 'Demand letter updated successfully' : 'Demand letter created successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
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

  Future<void> _deleteDemandLetter() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Demand Letter'),
        content: Text('Are you sure you want to delete this demand letter?'),
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
        await _demandLetterService.deleteDemandLetter(widget.demandLetter!.id!);
        Provider.of<DemandLetterProvider>(context, listen: false).loadDemandLetters();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Demand letter deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting demand letter: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}