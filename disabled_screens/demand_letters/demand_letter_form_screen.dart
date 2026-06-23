
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/demand_letter.dart';
import '../../models/invoice.dart';
import '../../models/customer.dart';
import '../../providers/demand_letter_provider.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/glass_container.dart';

class DemandLetterFormScreen extends StatefulWidget {
  final DemandLetter? demandLetter;

  const DemandLetterFormScreen({super.key, this.demandLetter});

  @override
  State<DemandLetterFormScreen> createState() => _DemandLetterFormScreenState();
}

class _DemandLetterFormScreenState extends State<DemandLetterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  Invoice? _selectedInvoice;
  Customer? _selectedCustomer;
  DemandLetterTemplate _selectedTemplate = DemandLetterTemplate.firstNotice;
  double _interestRate = 0.0;
  int _daysOverdue = 0;
  String _customContent = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.demandLetter != null) {
      _loadDemandLetterData();
    }
  }

  void _loadDemandLetterData() {
    // Load existing demand letter data
    // This would be implemented based on your data structure
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

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
          widget.demandLetter != null ? 'Edit Demand Letter' : 'Create Demand Letter',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInvoiceSelection(),
                const SizedBox(height: 24),
                _buildTemplateSelection(),
                const SizedBox(height: 24),
                _buildInterestSettings(),
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
    );
  }

  Widget _buildInvoiceSelection() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invoice Selection',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Consumer<InvoiceProvider>(
            builder: (context, invoiceProvider, child) {
              return DropdownButtonFormField<Invoice>(
                value: _selectedInvoice,
                decoration: InputDecoration(
                  labelText: 'Select Invoice',
                  labelStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                ),
                dropdownColor: Colors.black.withOpacity(0.8),
                style: GoogleFonts.poppins(color: Colors.white),
                items: invoiceProvider.invoices.map((invoice) {
                  return DropdownMenuItem<Invoice>(
                    value: invoice,
                    child: Text(
                      '${invoice.invoiceNumber} - \$${invoice.balanceAmount.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (invoice) {
                  setState(() {
                    _selectedInvoice = invoice;
                    if (invoice != null) {
                      _selectedCustomer = invoice.customer;
                      _daysOverdue = DateTime.now().difference(invoice.dueDate).inDays;
                    }
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select an invoice';
                  }
                  return null;
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSelection() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Letter Template',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<DemandLetterTemplate>(
            value: _selectedTemplate,
            decoration: InputDecoration(
              labelText: 'Select Template',
              labelStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white),
              ),
            ),
            dropdownColor: Colors.black.withOpacity(0.8),
            style: GoogleFonts.poppins(color: Colors.white),
            items: DemandLetterTemplate.values.map((template) {
              return DropdownMenuItem<DemandLetterTemplate>(
                value: template,
                child: Text(
                  _getTemplateDisplayName(template),
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: (template) {
              setState(() {
                _selectedTemplate = template!;
              });
            },
          ),
          const SizedBox(height: 16),
          Text(
            _getTemplateDescription(_selectedTemplate),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestSettings() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interest Settings',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _interestRate.toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Interest Rate (%)',
                    labelStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                  ),
                  style: GoogleFonts.poppins(color: Colors.white),
                  onChanged: (value) {
                    setState(() {
                      _interestRate = double.tryParse(value) ?? 0.0;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: _daysOverdue.toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Days Overdue',
                    labelStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                  ),
                  style: GoogleFonts.poppins(color: Colors.white),
                  onChanged: (value) {
                    setState(() {
                      _daysOverdue = int.tryParse(value) ?? 0;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_selectedInvoice != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Interest Calculation',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Outstanding Amount: \$${_selectedInvoice!.balanceAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    'Interest Amount: \$${(_selectedInvoice!.balanceAmount * _interestRate * _daysOverdue / 365).toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    'Total Amount: \$${(_selectedInvoice!.balanceAmount + (_selectedInvoice!.balanceAmount * _interestRate * _daysOverdue / 365)).toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
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

  Widget _buildContentSection() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Letter Content',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedTemplate == DemandLetterTemplate.custom)
            TextFormField(
              initialValue: _customContent,
              maxLines: 10,
              decoration: InputDecoration(
                labelText: 'Custom Content',
                labelStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white),
                ),
              ),
              style: GoogleFonts.poppins(color: Colors.white),
              onChanged: (value) {
                setState(() {
                  _customContent = value;
                });
              },
            )
          else
            Container(
              child: Text('No template selected'),
            ),
        ],
      ),
    );
  }
}
