import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/payment_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/demand_letter_provider.dart';
import '../providers/payment_reminder_provider.dart';
import '../models/payment.dart';
import '../models/invoice.dart';
import '../models/customer.dart';
import '../models/demand_letter.dart';
import '../models/payment_reminder.dart';
import '../utils/uganda_formatters.dart';
import '../widgets/glass_container.dart';
import 'payment_form_screen.dart';
import 'payment_detail_screen.dart';
import 'invoices_screen.dart';
import 'demand_letters_screen.dart';
import 'payment_reminders_screen.dart';
import '../providers/theme_provider.dart';
import '../widgets/glass_liquid_theme.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  int? _hoveredPaymentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPayments();
    });
  }

  void _loadPayments() {
    Provider.of<PaymentProvider>(context, listen: false).loadPayments();
    Provider.of<InvoiceProvider>(context, listen: false).loadInvoices();
    Provider.of<DemandLetterProvider>(context, listen: false).loadDemandLetters();
    Provider.of<PaymentReminderProvider>(context, listen: false).loadReminders();
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
                _buildSearchAndFilters(),
                const SizedBox(height: 24),
                _buildStatsCards(),
                const SizedBox(height: 24),
                _buildLogicalRelationships(),
                const SizedBox(height: 24),
                Expanded(
                  child: _buildPaymentsList(),
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
              builder: (context) => PaymentFormScreen(),
            ),
          ).then((_) => _loadPayments());
        },
        backgroundColor: Colors.green,
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
    return Row(
      children: [
        Icon(
          FontAwesomeIcons.creditCard,
          size: 32,
          color: Colors.white,
        ),
        const SizedBox(width: 12),
        Text(
          'Payments',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        Consumer<PaymentProvider>(
          builder: (context, provider, child) {
            return Text(
              '${provider.payments.length} Payments',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Consumer<PaymentProvider>(
      builder: (context, provider, child) {
        return Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  onChanged: provider.searchPayments,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search payments...',
                    hintStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.6)),
                    prefixIcon: const FaIcon(
                      FontAwesomeIcons.magnifyingGlass,
                      color: Colors.white,
                      size: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _buildFilterButton(provider),
          ],
        );
      },
    );
  }

  Widget _buildFilterButton(PaymentProvider provider) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const FaIcon(
          FontAwesomeIcons.filter,
          color: Colors.white,
          size: 16,
        ),
      ),
      onSelected: (value) {
        if (value == 'all') {
          provider.clearFilters();
        } else {
          provider.filterByStatus(PaymentStatus.values.firstWhere(
            (status) => status.name == value,
          ));
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'all',
          child: Text('All Status'),
        ),
        const PopupMenuItem(
          value: 'pending',
          child: Text('Pending'),
        ),
        const PopupMenuItem(
          value: 'completed',
          child: Text('Completed'),
        ),
        const PopupMenuItem(
          value: 'failed',
          child: Text('Failed'),
        ),
        const PopupMenuItem(
          value: 'cancelled',
          child: Text('Cancelled'),
        ),
        const PopupMenuItem(
          value: 'refunded',
          child: Text('Refunded'),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Consumer<PaymentProvider>(
      builder: (context, provider, child) {
        final payments = provider.payments;
        final totalAmount = payments.fold<double>(0, (sum, payment) => sum + payment.amount);
        final completedPayments = payments.where((p) => p.status == PaymentStatus.completed).length;
        final pendingPayments = payments.where((p) => p.status == PaymentStatus.pending).length;
        final failedPayments = payments.where((p) => p.status == PaymentStatus.failed).length;

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Amount',
                UgandaFormatters.formatCurrency(totalAmount),
                FontAwesomeIcons.dollarSign,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Completed',
                completedPayments.toString(),
                FontAwesomeIcons.check,
                GlassLiquidTheme.accentBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Pending',
                pendingPayments.toString(),
                FontAwesomeIcons.clock,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Failed',
                failedPayments.toString(),
                FontAwesomeIcons.times,
                Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            FaIcon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogicalRelationships() {
    return Consumer4<PaymentProvider, InvoiceProvider, DemandLetterProvider, PaymentReminderProvider>(
      builder: (context, paymentProvider, invoiceProvider, demandLetterProvider, reminderProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Dependencies',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildRelationshipCard(
                    'Unpaid Invoices',
                    invoiceProvider.invoices.where((invoice) => invoice.status != InvoiceStatus.paid).length,
                    Icons.receipt_long,
                    Colors.orange,
                    () => _navigateToInvoices(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildRelationshipCard(
                    'Active Demand Letters',
                    demandLetterProvider.demandLetters.where((letter) => letter.status == DemandLetterStatus.sent).length,
                    Icons.mail,
                    Colors.red,
                    () => _navigateToDemandLetters(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildRelationshipCard(
                    'Pending Reminders',
                    reminderProvider.reminders.where((reminder) => reminder.status == ReminderStatus.scheduled).length,
                    Icons.schedule,
                    GlassLiquidTheme.accentBlue,
                    () => _navigateToReminders(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPaymentFlowCard(),
          ],
        );
      },
    );
  }

  Widget _buildRelationshipCard(String title, int count, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            FaIcon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentFlowCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.diagramProject,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Payment Flow Logic',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFlowStep(
            '1. Invoice Created',
            'Customer receives invoice for vehicle purchase',
            Icons.receipt,
            GlassLiquidTheme.accentBlue,
          ),
          _buildFlowStep(
            '2. Payment Reminder',
            'System sends payment reminders if invoice is overdue',
            Icons.schedule,
            Colors.orange,
          ),
          _buildFlowStep(
            '3. Demand Letter',
            'Legal demand letter sent if payment is significantly overdue',
            Icons.mail,
            Colors.red,
          ),
          _buildFlowStep(
            '4. Payment Received',
            'Payment updates invoice status and customer balance',
            Icons.payment,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildFlowStep(String title, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToInvoices() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InvoicesScreen(),
      ),
    );
  }

  void _navigateToDemandLetters() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DemandLettersScreen(),
      ),
    );
  }

  void _navigateToReminders() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PaymentRemindersScreen(),
      ),
    );
  }

  Widget _buildPaymentsList() {
    return Consumer<PaymentProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        }

        if (provider.payments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FontAwesomeIcons.creditCard,
                  size: 80,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Payments',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Record your first payment',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: provider.payments.length,
          itemBuilder: (context, index) {
            final payment = provider.payments[index];
            return _buildPaymentCard(payment);
          },
        );
      },
    );
  }

  Widget _buildPaymentCard(Payment payment) {
    final isHovering = _hoveredPaymentId == payment.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: MouseRegion(
        onEnter: (_) {
          setState(() {
            _hoveredPaymentId = payment.id;
          });
        },
        onExit: (_) {
          setState(() {
            _hoveredPaymentId = null;
          });
        },
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentDetailScreen(payment: payment),
              ),
            ).then((_) => _loadPayments());
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isHovering 
                  ? const Color(0xFFFFF1E6) 
                  : Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
              border: isHovering 
                  ? Border.all(color: const Color(0xFFFFE4C7), width: 1)
                  : Border.all(color: Colors.white.withOpacity(0.4), width: 1),
              boxShadow: isHovering
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFE4C7).withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment #${payment.id}',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isHovering ? Colors.black : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Invoice #${payment.invoiceId}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: isHovering 
                                  ? Colors.black.withOpacity(0.7) 
                                  : Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(payment.status, isHovering),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        FontAwesomeIcons.dollarSign,
                        'Amount',
                        UgandaFormatters.formatCurrency(payment.amount),
                        isHovering,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        _getMethodIcon(payment.method),
                        'Method',
                        payment.methodText,
                        isHovering,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        FontAwesomeIcons.calendar,
                        'Date',
                        UgandaFormatters.formatDate(payment.paymentDate),
                        isHovering,
                      ),
                    ),
                  ],
                ),
                if (payment.referenceNumber != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.hashtag,
                        size: 12,
                        color: isHovering 
                            ? Colors.black.withOpacity(0.6) 
                            : Colors.white.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Reference: ${payment.referenceNumber}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isHovering 
                              ? Colors.black.withOpacity(0.7) 
                              : Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                _buildPaymentRelationships(payment, isHovering),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentRelationships(Payment payment, bool isHovering) {
    return Consumer3<InvoiceProvider, DemandLetterProvider, PaymentReminderProvider>(
      builder: (context, invoiceProvider, demandLetterProvider, reminderProvider, child) {
        // Find related invoice
        final invoice = invoiceProvider.invoices.firstWhere(
          (inv) => inv.id == payment.invoiceId,
          orElse: () => Invoice(
            id: payment.invoiceId,
            customerId: 0,
            invoiceNumber: 'Unknown',
            customer: Customer(id: 0, name: 'Unknown', email: '', phone: ''),
            invoiceDate: DateTime.now(),
            dueDate: DateTime.now(),
            subtotal: 0,
            taxAmount: 0,
            discountAmount: 0,
            totalAmount: 0,
            paidAmount: 0,
            balanceAmount: 0,
            status: InvoiceStatus.draft,
            notes: '',
            terms: '',
            carAmount: 0,
            downPayment: 0,
            remainingAmount: 0,
            images: [],
            items: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Find related demand letters
        final relatedDemandLetters = demandLetterProvider.demandLetters
            .where((letter) => letter.invoiceId == payment.invoiceId)
            .toList();

        // Find related reminders
        final relatedReminders = reminderProvider.reminders
            .where((reminder) => reminder.invoiceId == payment.invoiceId)
            .toList();

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isHovering ? const Color(0xFFFFE4C7).withOpacity(0.3) : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isHovering ? const Color(0xFFFFE4C7).withOpacity(0.5) : Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Related Information',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isHovering ? Colors.black.withOpacity(0.8) : Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildRelationshipItem(
                      'Invoice Status',
                      invoice.statusText,
                      _getInvoiceStatusColor(invoice.status),
                      isHovering,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildRelationshipItem(
                      'Demand Letters',
                      relatedDemandLetters.length.toString(),
                      relatedDemandLetters.isNotEmpty ? Colors.red : Colors.green,
                      isHovering,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildRelationshipItem(
                      'Reminders',
                      relatedReminders.length.toString(),
                      relatedReminders.isNotEmpty ? Colors.orange : Colors.green,
                      isHovering,
                    ),
                  ),
                ],
              ),
              if (relatedDemandLetters.isNotEmpty || relatedReminders.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Active Actions: ${relatedDemandLetters.length} demand letters, ${relatedReminders.length} reminders',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: isHovering ? Colors.black.withOpacity(0.6) : Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildRelationshipItem(String label, String value, Color color, bool isHovering) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: isHovering ? Colors.black.withOpacity(0.6) : Colors.white.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getInvoiceStatusColor(InvoiceStatus status) {
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
        return Colors.orange;
    }
  }

  Widget _buildInfoItem(IconData icon, String label, String value, bool isHovering) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FaIcon(
              icon,
              size: 12,
              color: isHovering ? Colors.black.withOpacity(0.6) : Colors.white.withOpacity(0.6),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isHovering ? Colors.black.withOpacity(0.6) : Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isHovering ? Colors.black : Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(PaymentStatus status, bool isHovering) {
    Color statusColor;
    switch (status) {
      case PaymentStatus.pending:
        statusColor = Colors.orange;
        break;
      case PaymentStatus.completed:
        statusColor = Colors.green;
        break;
      case PaymentStatus.failed:
        statusColor = Colors.red;
        break;
      case PaymentStatus.cancelled:
        statusColor = Colors.grey;
        break;
      case PaymentStatus.refunded:
        statusColor = GlassLiquidTheme.accentBlue;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isHovering ? statusColor.withOpacity(0.3) : statusColor.withOpacity(0.2),
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
}