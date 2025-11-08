import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../services/payment_service.dart';
import '../services/invoice_service.dart';
import '../services/customer_service.dart';
import '../models/payment.dart';
import '../models/invoice.dart';
import '../models/customer.dart';
import 'dart:async';
import '../providers/theme_provider.dart';

class PaymentFormScreen extends StatefulWidget {
  final Payment? payment;
  
  const PaymentFormScreen({Key? key, this.payment}) : super(key: key);

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final PaymentService _paymentService = PaymentService();
  final InvoiceService _invoiceService = InvoiceService();
  final CustomerService _customerService = CustomerService();
  
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  
  Invoice? _selectedInvoice;
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  PaymentStatus _selectedStatus = PaymentStatus.pending;
  DateTime _selectedDate = DateTime.now();
  
  List<Invoice> _invoices = [];
  List<Customer> _customers = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.payment != null) {
      _loadPaymentData();
    }
  }

  Future<void> _loadData() async {
    try {
      final invoices = await _invoiceService.getAllInvoices();
      final customers = await _customerService.getAllCustomers();
      
      setState(() {
        _invoices = invoices;
        _customers = customers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  void _loadPaymentData() {
    if (widget.payment != null) {
      final payment = widget.payment!;
      _amountController.text = payment.amount.toString();
      _referenceController.text = payment.reference ?? '';
      _notesController.text = payment.notes ?? '';
      _selectedMethod = payment.method;
      _selectedStatus = payment.status;
      _selectedDate = payment.paymentDate;
      
      _selectedInvoice = _invoices.firstWhere(
        (inv) => inv.id == payment.invoiceId,
        orElse: () => Invoice.empty(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              widget.payment != null ? 'Edit Payment' : 'Add Payment',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFFFAF0)),
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: themeProvider.backgroundGradient,
                  ),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInvoiceSelection(),
                          const SizedBox(height: 24),
                          _buildPaymentDetails(),
                          const SizedBox(height: 24),
                          _buildPaymentMethod(),
                          const SizedBox(height: 24),
                          _buildStatusAndDate(),
                          const SizedBox(height: 24),
                          _buildNotes(),
                          const SizedBox(height: 32),
                          _buildSaveButton(),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildInvoiceSelection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt, color: Color(0xFFFFFAF0)),
              const SizedBox(width: 12),
          Text(
                'Invoice Selection',
            style: GoogleFonts.poppins(
                  fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Invoice>(
            value: _selectedInvoice,
            decoration: InputDecoration(
              labelText: 'Select Invoice',
              labelStyle: GoogleFonts.poppins(color: Colors.white70),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFFFFAF0)),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
            ),
            dropdownColor: const Color(0xFF1A1F3A),
            style: GoogleFonts.poppins(color: Colors.white),
            itemHeight: 60,
            selectedItemBuilder: (BuildContext context) {
              return _invoices.map<Widget>((Invoice invoice) {
                return Text(
                  invoice.invoiceNumber,
                  style: GoogleFonts.poppins(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                );
              }).toList();
            },
            items: _invoices.map((invoice) {
              final customer = _customers.firstWhere(
                (cust) => cust.id == invoice.customerId,
                orElse: () => Customer.empty(),
              );
              
              return DropdownMenuItem<Invoice>(
                value: invoice,
                child: Row(
                  children: [
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.invoiceNumber,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            customer.name.isNotEmpty ? customer.name : 'Unknown Customer',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'UGX ${_formatNumber(invoice.totalAmount)}',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (invoice) {
              setState(() {
                _selectedInvoice = invoice;
                if (invoice != null) {
                  _amountController.text = invoice.totalAmount.toString();
                }
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Please select an invoice';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payment, color: Color(0xFFFFFAF0)),
              const SizedBox(width: 12),
              Text(
                'Payment Details',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _amountController,
            label: 'Amount (UGX)',
            icon: Icons.payments,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter amount';
              }
              if (double.tryParse(value) == null || double.parse(value) <= 0) {
                return 'Please enter a valid amount';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _referenceController,
            label: 'Reference Number',
            icon: Icons.receipt_long,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.credit_card, color: Color(0xFFFFFAF0)),
              const SizedBox(width: 12),
              Text(
                'Payment Method',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: PaymentMethod.values.map((method) {
              final isSelected = _selectedMethod == method;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMethod = method;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFFFAF0) : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFFFFAF0) : Colors.white.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getPaymentMethodIcon(method),
                        color: isSelected ? Colors.black : Colors.white.withOpacity(0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        method.toString().split('.').last,
                        style: GoogleFonts.poppins(
                          color: isSelected ? Colors.black : Colors.white.withOpacity(0.7),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusAndDate() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings, color: Color(0xFFFFFAF0)),
              const SizedBox(width: 12),
              Text(
                'Status & Date',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<PaymentStatus>(
                  value: _selectedStatus,
            decoration: InputDecoration(
                    labelText: 'Status',
                    labelStyle: GoogleFonts.poppins(color: Colors.white70),
              border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFFFFAF0)),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                  ),
                  dropdownColor: const Color(0xFF1A1F3A),
                  style: GoogleFonts.poppins(color: Colors.white),
                  items: PaymentStatus.values.map((status) {
                    return DropdownMenuItem<PaymentStatus>(
                      value: status,
                      child: Text(
                        status.toString().split('.').last,
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              );
            }).toList(),
                  onChanged: (status) {
              setState(() {
                      _selectedStatus = status!;
              });
            },
          ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white.withOpacity(0.05),
              ),
              child: Row(
                children: [
                        const Icon(Icons.calendar_today, color: Color(0xFFFFFAF0)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotes() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.note, color: Color(0xFFFFFAF0)),
                  const SizedBox(width: 12),
                  Text(
                'Notes',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _notesController,
            label: 'Additional notes',
            icon: Icons.edit,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.white70),
        prefixIcon: Icon(icon, color: const Color(0xFFFFFAF0)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFFFFAF0)),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
      ),
      validator: validator,
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _savePayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                widget.payment != null ? 'Update Payment' : 'Save Payment',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFFFAF0),
              onPrimary: Colors.white,
              surface: Color(0xFF1A1F3A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedInvoice == null || _selectedInvoice!.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an invoice'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final payment = Payment(
        id: widget.payment?.id,  // null for new payments, existing id for updates
        invoiceId: _selectedInvoice!.id,
        amount: double.parse(_amountController.text),
        paymentDate: _selectedDate,
        method: _selectedMethod,
        status: _selectedStatus,
        reference: _referenceController.text.isNotEmpty ? _referenceController.text : null,
        referenceNumber: _referenceController.text.isNotEmpty ? _referenceController.text : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        createdAt: widget.payment?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      int result;
      if (widget.payment != null) {
        result = await _paymentService.updatePayment(payment);
        if (result <= 0) {
          throw Exception('Failed to update payment');
        }
      } else {
        result = await _paymentService.createPayment(payment);
        if (result <= 0) {
          throw Exception('Failed to create payment - invalid ID returned');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.payment != null ? 'Payment updated successfully' : 'Payment created successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e, stackTrace) {
      debugPrint('Error saving payment: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving payment: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.check:
        return Icons.check;
      case PaymentMethod.bank_transfer:
        return Icons.account_balance;
      case PaymentMethod.credit_card:
        return Icons.credit_card;
      case PaymentMethod.mobile_money:
        return Icons.phone_android;
      case PaymentMethod.cheque:
        return Icons.receipt;
      case PaymentMethod.debitCard:
        return Icons.credit_card;
      case PaymentMethod.paypal:
        return Icons.payment;
      case PaymentMethod.other:
        return Icons.more_horiz;
    }
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toStringAsFixed(0);
    }
  }
}