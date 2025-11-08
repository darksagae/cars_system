
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:io';
import '../../models/payment.dart';
import '../../models/invoice.dart';
import '../../models/customer.dart';
import '../../providers/payment_provider.dart';
import '../../providers/invoice_provider.dart';
import '../../services/invoice_service.dart';
import '../../widgets/glass_container.dart';
import 'payment_form_screen.dart';
import 'payment_detail_screen.dart';
import '../../services/auth_service.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  PaymentStatus? _filterStatus;
  PaymentMethod? _filterMethod;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentProvider>().loadPayments();
      context.read<InvoiceProvider>().loadInvoices();
    });
    // determine admin for UI gating
    AuthService().isCurrentUserAdmin().then((v){
      if (mounted) setState(()=> _isAdmin = v); 
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSearchAndFilters(),
          const SizedBox(height: 24),
          _buildPaymentsList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payments',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Consumer<PaymentProvider>(
              builder: (context, provider, child) {
                return Text(
                  '${provider.payments.length} payments',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                );
              },
            ),
          ],
        ),
        GlassContainer(
          padding: const EdgeInsets.all(12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showCreatePaymentDialog(),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FaIcon(
                    FontAwesomeIcons.plus,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Record Payment',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Row(
      children: [
        Expanded(
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                context.read<PaymentProvider>().searchPayments(value);
              },
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search payments...',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.6),
                ),
                border: InputBorder.none,
                prefixIcon: FaIcon(
                  FontAwesomeIcons.magnifyingGlass,
                  color: Colors.white.withOpacity(0.6),
                  size: 16,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        GlassContainer(
          padding: const EdgeInsets.all(12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showStatusFilterDialog(),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(
                    FontAwesomeIcons.filter,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _filterStatus?.name.toUpperCase() ?? 'ALL',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GlassContainer(
          padding: const EdgeInsets.all(12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showMethodFilterDialog(),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(
                    FontAwesomeIcons.creditCard,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _filterMethod?.name.toUpperCase() ?? 'ALL',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentsList() {
    return Expanded(
      child: Consumer<PaymentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (provider.payments.isEmpty) {
            return GlassContainer(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.creditCard,
                      color: Colors.white.withOpacity(0.4),
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No payments found',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Record your first payment to get started',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.payments.length,
            itemBuilder: (context, index) {
              final payment = provider.payments[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: _buildPaymentCard(payment),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPaymentCard(Payment payment) {
    return Consumer<InvoiceProvider>(
      builder: (context, invoiceProvider, child) {
        // Find the invoice for this payment
        Invoice? invoice;
        try {
          invoice = invoiceProvider.invoices.firstWhere(
            (inv) => inv.id == payment.invoiceId,
          );
        } catch (e) {
          invoice = null;
        }
        
        // If invoice not found in provider, try to load it directly from service
        if (invoice == null && payment.invoiceId != null) {
          // Use FutureBuilder to load invoice on demand
          return FutureBuilder<Invoice?>(
            future: _loadInvoiceById(payment.invoiceId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Show loading state or fallback
                return _buildPaymentCardContent(payment, null, null);
              }
              
              final loadedInvoice = snapshot.data;
              final customer = loadedInvoice?.customer;
              return _buildPaymentCardContent(payment, loadedInvoice, customer);
            },
          );
        }
        
        // Get customer from invoice
        final customer = invoice?.customer;
        return _buildPaymentCardContent(payment, invoice, customer);
      },
    );
  }
  
  Future<Invoice?> _loadInvoiceById(int invoiceId) async {
    try {
      final invoiceService = InvoiceService();
      return await invoiceService.getInvoiceById(invoiceId);
    } catch (e) {
      return null;
    }
  }
  
  Widget _buildPaymentCardContent(Payment payment, Invoice? invoice, Customer? customer) {
    return GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigateToPaymentDetail(payment),
              borderRadius: BorderRadius.circular(20),
              child: Row(
                children: [
                  // Customer profile picture or payment method icon
                  customer != null && customer.profileImage.isNotEmpty
                      ? Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _getStatusColor(payment.status).withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.file(
                              File(customer.profileImage),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(payment.status).withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      customer.name.isNotEmpty
                                          ? customer.name[0].toUpperCase()
                                          : '?',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        )
                      : customer != null && customer.name.isNotEmpty
                          ? Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _getStatusColor(payment.status).withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  customer.name[0].toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _getStatusColor(payment.status).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: FaIcon(
                                _getMethodIcon(payment.method),
                                color: _getStatusColor(payment.status),
                                size: 20,
                              ),
                            ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer != null && customer.name.isNotEmpty
                              ? customer.displayName
                              : 'Invoice #${payment.invoiceId}',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customer != null && customer.name.isNotEmpty && invoice != null
                              ? 'Invoice #${invoice.invoiceNumber} • ${payment.method.name.toUpperCase()}'
                              : '${payment.method.name.toUpperCase()} • ${_formatDate(payment.paymentDate)}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          payment.referenceNumber != null && payment.referenceNumber!.isNotEmpty
                              ? 'Ref: ${payment.referenceNumber}'
                              : _formatDate(payment.paymentDate),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${payment.amount.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(payment.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      payment.statusText,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _getStatusColor(payment.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {}, // Required for tap area
                  borderRadius: BorderRadius.circular(8),
                  child: PopupMenuButton<String>(
                    icon: FaIcon(
                      FontAwesomeIcons.ellipsisVertical,
                      color: Colors.white.withOpacity(0.8),
                      size: 18,
                    ),
                    color: Colors.grey[900],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    onSelected: (value) => _handleMenuAction(value, payment),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            FaIcon(FontAwesomeIcons.eye, size: 14),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
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
                      if (_isAdmin)
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.cancelled:
        return Colors.grey;
      case PaymentStatus.refunded:
        return Colors.blue;
    }
  }

  IconData _getMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return FontAwesomeIcons.moneyBill;
      case PaymentMethod.check:
        return FontAwesomeIcons.check;
      case PaymentMethod.bank_transfer:
        return FontAwesomeIcons.buildingColumns;
      case PaymentMethod.credit_card:
        return FontAwesomeIcons.creditCard;
      case PaymentMethod.debitCard:
        return FontAwesomeIcons.creditCard;
      case PaymentMethod.paypal:
        return FontAwesomeIcons.paypal;
      case PaymentMethod.mobile_money:
        return FontAwesomeIcons.mobile;
      case PaymentMethod.cheque:
        return FontAwesomeIcons.check;
      case PaymentMethod.other:
        return FontAwesomeIcons.question;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleMenuAction(String action, Payment payment) {
    switch (action) {
      case 'view':
        _navigateToPaymentDetail(payment);
        break;
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentFormScreen(payment: payment),
          ),
        ).then((_) {
          context.read<PaymentProvider>().loadPayments();
        });
        break;
      case 'delete':
        _confirmDeletePayment(payment);
        break;
    }
  }

  void _confirmDeletePayment(Payment payment) {
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
                'Delete Payment',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete this payment? This action cannot be undone.',
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
                      onPressed: () async {
                        Navigator.pop(context);
                        if (payment.id == null) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Cannot delete payment: Payment ID is missing',
                                  style: GoogleFonts.poppins(),
                                ),
                                backgroundColor: Colors.red.withOpacity(0.8),
                              ),
                            );
                          }
                          return;
                        }
                        
                        final provider = context.read<PaymentProvider>();
                        final success = await provider.deletePayment(payment.id!);
                        if (mounted) {
                          if (success) {
                            // Reload payments to refresh the UI
                            await provider.loadPayments();
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Payment deleted successfully!'
                                    : 'Failed to delete payment',
                                style: GoogleFonts.poppins(),
                              ),
                              backgroundColor: success
                                  ? Colors.green.withOpacity(0.8)
                                  : Colors.red.withOpacity(0.8),
                            ),
                          );
                        }
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

  void _navigateToPaymentDetail(Payment payment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentDetailScreen(payment: payment),
      ),
    ).then((_) {
      context.read<PaymentProvider>().loadPayments();
    });
  }

  void _showCreatePaymentDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PaymentFormScreen(),
      ),
    ).then((_) {
      context.read<PaymentProvider>().loadPayments();
    });
  }

  void _showStatusFilterDialog() {
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
                'Filter by Status',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ...[
                ListTile(
                  title: Text(
                    'All',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  onTap: () {
                    setState(() {
                      _filterStatus = null;
                    });
                    context.read<PaymentProvider>().clearStatusFilter();
                    Navigator.pop(context);
                  },
                ),
                ...PaymentStatus.values.map((status) => ListTile(
                      title: Text(
                        status.name.toUpperCase(),
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                      onTap: () {
                        setState(() {
                          _filterStatus = status;
                        });
                        context.read<PaymentProvider>().filterByStatus(status);
                        Navigator.pop(context);
                      },
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showMethodFilterDialog() {
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
                'Filter by Method',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ...[
                ListTile(
                  title: Text(
                    'All',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  onTap: () {
                    setState(() {
                      _filterMethod = null;
                    });
                    context.read<PaymentProvider>().clearMethodFilter();
                    Navigator.pop(context);
                  },
                ),
                ...PaymentMethod.values.map((method) => ListTile(
                      title: Text(
                        method.name.toUpperCase(),
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                      onTap: () {
                        setState(() {
                          _filterMethod = method;
                        });
                        context.read<PaymentProvider>().filterByMethod(method);
                        Navigator.pop(context);
                      },
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
