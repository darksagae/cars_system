import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/invoice_provider.dart';
import '../models/invoice.dart';
import '../models/customer.dart';
import '../utils/uganda_formatters.dart';
import '../widgets/glass_container.dart';
import 'invoice_form_screen.dart';
import 'invoice_detail_screen.dart';
import '../providers/theme_provider.dart';
import '../widgets/glass_liquid_theme.dart';

class InvoicesScreen extends StatefulWidget {
  final Customer? customerFilter;
  
  const InvoicesScreen({super.key, this.customerFilter});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  int? _hoveredIndex;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInvoices();
    });
  }

  void _loadInvoices() {
    Provider.of<InvoiceProvider>(context, listen: false).loadInvoices();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: themeProvider.backgroundGradient,
            ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
        child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildSearchBar(),
                const SizedBox(height: 24),
                Expanded(
                  child: _buildInvoicesList(),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const InvoiceFormScreen(),
            ),
          ).then((_) => _loadInvoices());
        },
        backgroundColor: Colors.orange,
        child: const FaIcon(
          FontAwesomeIcons.plus,
          color: Colors.white,
        ),
      ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(
              Icons.receipt,
              size: 28,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(
              widget.customerFilter != null 
                  ? 'Invoices & Quotes - ${widget.customerFilter!.name}'
                  : 'Invoices & Quotes',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Consumer<InvoiceProvider>(
              builder: (context, invoiceProvider, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Text(
                    '${invoiceProvider.invoices.length} invoices',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Consumer<InvoiceProvider>(
      builder: (context, invoiceProvider, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              child: TextField(
                onChanged: (value) => invoiceProvider.searchInvoices(value),
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search invoices & quotes...',
                  hintStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF667EEA)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: Color(0xFF667EEA)),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInvoicesList() {
    return Consumer<InvoiceProvider>(
      builder: (context, invoiceProvider, child) {
        if (invoiceProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        }

        if (invoiceProvider.invoices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  FontAwesomeIcons.fileInvoice,
                  size: 64,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No invoices found',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first invoice to get started',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }

        // Filter invoices by customer if filter is provided
        final filteredInvoices = widget.customerFilter != null
            ? invoiceProvider.invoices.where((invoice) => invoice.customerId == widget.customerFilter!.id).toList()
            : invoiceProvider.invoices;

        if (widget.customerFilter != null && filteredInvoices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  FontAwesomeIcons.fileInvoice,
                  size: 64,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No invoices found for ${widget.customerFilter!.name}',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
            Text(
                  'Create an invoice for this customer',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredInvoices.length,
          itemBuilder: (context, index) {
            final invoice = filteredInvoices[index];
            return _buildInvoiceCard(invoice);
          },
        );
      },
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    final provider = Provider.of<InvoiceProvider>(context, listen: false);
    final index = provider.invoices.indexOf(invoice);
    final isHover = _hoveredIndex == index;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isHover ? const Color(0xFFFFFAF0) : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHover ? const Color(0xFFFFF1E6) : Colors.white.withOpacity(0.25),
          ),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InvoiceDetailScreen(invoice: invoice),
              ),
            ).then((_) => _loadInvoices());
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                GlassContainer(
                  width: 50,
                  height: 50,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isHover ? Colors.black.withOpacity(0.08) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: FaIcon(
                        FontAwesomeIcons.fileInvoice,
                        color: isHover ? Colors.black : Colors.orange,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invoice NSBmotors_${invoice.invoiceNumber}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isHover ? Colors.black : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (invoice.customer?.name?.isNotEmpty == true) ? invoice.customer!.name : 'N/A',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isHover ? Colors.black87 : Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Due: ${UgandaFormatters.formatDate(invoice.dueDate)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isHover ? Colors.black54 : Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isHover ? Colors.black : _getStatusColor(invoice.status)).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Text(
                            _getStatusText(invoice.status),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isHover ? Colors.black : _getStatusColor(invoice.status),
                            ),
                          ),
                        ),
                        if (!invoice.isFinalized) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _confirmDeleteInvoice(context, invoice),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.withOpacity(0.3)),
                              ),
                              child: FaIcon(
                                FontAwesomeIcons.trash,
                                size: 14,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      UgandaFormatters.formatCurrency(invoice.totalAmount),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isHover ? Colors.black : Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Paid: ${UgandaFormatters.formatCurrency(invoice.paidAmount)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isHover ? Colors.black87 : Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return Colors.grey;
      case InvoiceStatus.sent:
        return GlassLiquidTheme.accentBlue;
      case InvoiceStatus.pending:
        return Colors.orange;
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.overdue:
        return Colors.red;
      case InvoiceStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return 'DRAFT';
      case InvoiceStatus.sent:
        return 'SENT';
      case InvoiceStatus.pending:
        return 'PENDING';
      case InvoiceStatus.paid:
        return 'PAID';
      case InvoiceStatus.overdue:
        return 'OVERDUE';
      case InvoiceStatus.cancelled:
        return 'CANCELLED';
    }
  }

  // Confirm and delete invoice
  Future<void> _confirmDeleteInvoice(BuildContext context, Invoice invoice) async {
    if (invoice.isFinalized) return;

    // Stop event propagation to prevent navigation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: Text(
          'Delete Invoice',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Text(
          'Are you sure you want to delete invoice NSBmotors_${invoice.invoiceNumber}?\n\nThis action cannot be undone.',
          style: GoogleFonts.poppins(
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.white70,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final provider = Provider.of<InvoiceProvider>(context, listen: false);
      final id = invoice.id;
      
      if (id != null) {
        // Show loading indicator
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Deleting invoice...',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 1),
            ),
          );
        }

        final success = await provider.deleteInvoice(id);
        
        if (context.mounted) {
          if (success) {
            // Reload invoices to refresh the list
            _loadInvoices();
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ Invoice NSBmotors_${invoice.invoiceNumber} deleted successfully',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '❌ Failed to delete invoice',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '❌ Invalid invoice ID',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Error deleting invoice: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}