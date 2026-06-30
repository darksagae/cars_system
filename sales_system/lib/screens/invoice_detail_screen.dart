import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:io';
import '../widgets/glass_container.dart';
import '../widgets/glass_liquid_theme.dart';
import '../models/invoice.dart';
import '../utils/uganda_formatters.dart';
import '../utils/email_display.dart';
import '../services/whatsapp_service.dart';
import '../services/whatsapp_auto_service.dart';
import '../services/email_service.dart';
import 'whatsapp_setup_screen.dart';
import '../services/pdf/pdf_service.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';
import '../providers/invoice_provider.dart';
import '../services/invoice_service.dart';
import '../services/invoice_pdf_sync.dart';
import 'invoice_form_screen.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final Invoice invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  late Invoice _invoice;
  bool _isLoading = false;
  bool _isSendingWhatsApp = false;
  bool _isGeneratingPDF = false;
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _modelSuffixController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice;
    _modelController.text = _invoice.vehicleModel;
    _modelSuffixController.text = _invoice.vehicleModelSuffix;
    // Always refresh from DB to avoid showing stale totals/items (e.g. after migrations or recalculations).
    // This also ensures customer + items are fully loaded.
    if (_invoice.id != null) {
      _loadInvoiceWithCustomer();
    }
  }

  @override
  void dispose() {
    _modelController.dispose();
    _modelSuffixController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoiceWithCustomer() async {
    if (_invoice.id == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final invoiceService = InvoiceService();
      final loadedInvoice = await invoiceService.getInvoiceById(_invoice.id!);
      if (loadedInvoice != null && mounted) {
        setState(() {
          _invoice = loadedInvoice;
          _modelController.text = loadedInvoice.vehicleModel;
          _modelSuffixController.text = loadedInvoice.vehicleModelSuffix;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
              child: Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                _buildSummaryBadges(),
                                const SizedBox(height: 24),
                                _buildCustomerInfo(),
                                const SizedBox(height: 24),
                                _buildVehicleSummary(),
                                const SizedBox(height: 24),
                                _buildCifAndRates(),
                                const SizedBox(height: 24),
                                _buildPhaseOneSection(),
                                const SizedBox(height: 24),
                                _buildTaxBreakdownSection(),
                                const SizedBox(height: 24),
                                _buildPhaseTwoSettlementSection(),
                                const SizedBox(height: 24),
                                if (_invoice.images.isNotEmpty) ...[
                                  _buildDocumentsSection(),
                                  const SizedBox(height: 24),
                                ],
                                _buildItemsList(),
                                const SizedBox(height: 24),
                                _buildTotals(),
                                const SizedBox(height: 24),
                                _buildQuickActions(context),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(12),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
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
                  'Invoice Details',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Invoice NSBmotors_${_invoice.invoiceNumber}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _statusBadgeBackgroundColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _statusBadgeBackgroundColor().withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Text(
              _statusBadgeLabel(),
              style: GoogleFonts.poppins(
                color: _statusBadgeForegroundColor(),
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBadges() {
    // Align with line-item total: stored first/second installment columns can drift after edits;
    // totalAmount is recalculated from items on load.
    final bool looksLikeCarImport =
        (_invoice.carPriceUSD > 0 && _invoice.exchangeRate > 0) ||
            _invoice.firstInstallmentUGX > 0 ||
            _invoice.taxesURA > 0 ||
            _invoice.vehicleMake.isNotEmpty;

    late final double regProcess;
    late final double grandTotal;

    if (looksLikeCarImport) {
      final ura = _ensureUraTaxes();
      final extras =
          _invoice.numberPlatesFee + _invoice.thirdPartyInsurance + _invoice.agencyFees;
      final phase2 = ura + extras;
      regProcess = phase2;
      grandTotal = _invoice.totalAmount > 0 ? _invoice.totalAmount : (_invoice.firstInstallmentUGX + phase2);
    } else {
      final phase1 = _invoice.firstInstallmentUGX;
      final phase2 = _ensureSecondInstallment();
      regProcess = phase2;
      grandTotal = phase1 + phase2;
    }

    return Row(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Registration Process (Total)', style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  UgandaFormatters.formatCurrency(regProcess),
                  style: GoogleFonts.poppins(color: Colors.purpleAccent, fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Grand Total (Phase 1 + Phase 2)', style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  UgandaFormatters.formatCurrency(grandTotal),
                  style: GoogleFonts.poppins(color: Colors.orangeAccent, fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerInfo() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Information',
              style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          // Customer profile picture and name
          if (_invoice.customer != null) ...[
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  radius: 32,
                  backgroundImage: _invoice.customer!.profileImage.isNotEmpty
                      ? FileImage(File(_invoice.customer!.profileImage))
                      : null,
                  child: _invoice.customer!.profileImage.isEmpty
                      ? Text(
                          _invoice.customer!.name.isNotEmpty
                              ? _invoice.customer!.name[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _invoice.customer!.displayName.isNotEmpty ? _invoice.customer!.displayName : 'N/A',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        displayEmailOrNa(_invoice.customer!.email),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('Name', (_invoice.customer?.name?.isNotEmpty == true) ? _invoice.customer!.name : 'N/A'),
              ),
              Expanded(
                child: _buildInfoItem('Email', displayEmailOrNa(_invoice.customer?.email)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
            Expanded(
                child: _buildInfoItem('Phone', (_invoice.customer?.phone?.isNotEmpty == true) ? _invoice.customer!.phone : 'N/A'),
              ),
              Expanded(
                child: _buildInfoItem('Company', (_invoice.customer?.company?.isNotEmpty == true) ? _invoice.customer!.company : 'N/A'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoItem('Address', (_invoice.customer?.address?.isNotEmpty == true) ? _invoice.customer!.address! : 'N/A'),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invoice Items',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          ..._invoice.items.map((item) => _buildItemRow(item)),
        ],
      ),
    );
  }

  Widget _buildItemRow(dynamic item) {
              return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
          width: 1,
                  ),
                ),
      child: Row(
                      children: [
                        Expanded(
            flex: 3,
                          child: Text(
              item.productName,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
            flex: 1,
                          child: Text(
              '${item.quantity}',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
            flex: 1,
                          child: Text(
              UgandaFormatters.formatCurrency(item.price),
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
            flex: 1,
                          child: Text(
              UgandaFormatters.formatCurrency(item.quantity * item.price),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotals() {
    // For car import invoices we want a business-meaningful breakdown:
    // Phase 1 (upfront) + URA Taxes (always) + Phase 2 extras (plates/insurance/agent) = Total.
    // The generic Subtotal/VAT/Discount model is still used for custom invoices.
    final bool looksLikeCarImportInvoice =
        (_invoice.carPriceUSD > 0 && _invoice.exchangeRate > 0) ||
        _invoice.firstInstallmentUGX > 0 ||
        _invoice.taxesURA > 0 ||
        _invoice.vehicleMake.isNotEmpty;

    final double uraTaxes = _ensureUraTaxes();
    final double phase2Extras = _invoice.numberPlatesFee + _invoice.thirdPartyInsurance + _invoice.agencyFees;
    final double secondPhaseCombined = uraTaxes + phase2Extras;
    // Prefer totals derived from totalAmount (line items) so updates reflect saved items.
    final double phase1Total = looksLikeCarImportInvoice
        ? ((_invoice.totalAmount - secondPhaseCombined).clamp(0.0, double.infinity))
        : (_invoice.firstInstallmentUGX > 0
            ? _invoice.firstInstallmentUGX
            : (_invoice.totalAmount - uraTaxes - phase2Extras));
    final double computedTotal = looksLikeCarImportInvoice
        ? _invoice.totalAmount
        : (phase1Total + uraTaxes + phase2Extras);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invoice Totals',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          if (looksLikeCarImportInvoice) ...[
            _buildTotalRow('Phase 1 (Upfront)', phase1Total, false),
            _buildTotalRow('URA Taxes', uraTaxes, false),
            _buildTotalRow('Phase 2 Extras', phase2Extras, false),
          ] else ...[
            _buildTotalRow('Subtotal', _invoice.subtotal, false),
            _buildTotalRow('VAT (${UgandaFormatters.formatVatRate()})', _invoice.taxAmount, false),
            _buildTotalRow('Discount', -_invoice.discountAmount, false),
          ],
          const SizedBox(height: 8),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          // Use computed total for car-import invoices to avoid stale/incorrect stored totals.
          _buildTotalRow('Total', looksLikeCarImportInvoice ? computedTotal : _invoice.totalAmount, true),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, bool isTotal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.8),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            UgandaFormatters.formatCurrency(amount),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxBreakdownSection() {
    final cifUsd = _invoice.carPriceUSD;
    final rate = _invoice.exchangeRate;
    final year = _invoice.vehicleYear;

    if (cifUsd == 0 || rate == 0 || year == 0) {
      return const SizedBox.shrink();
    }

    final cv = cifUsd * rate;
    final idf = cv * 0.01;
    final importDuty = cv * 0.25;
    final vat = (cv + importDuty) * 0.18;
    final wht = cv * 0.06;
    final infra = cv * 0.015;
    final envLevy = _isEnvironmentalLevyApplicable(year) ? cv * 0.50 : 0.0;
    const regFee = 1500000.0;
    const stamp = 18000.0;
    const regForm = 35000.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '=== TAX BREAKDOWN ===',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          _buildBreakdownRow('Import Duty', importDuty),
          _buildBreakdownRow('VAT', vat),
          _buildBreakdownRow('Withholding Tax', wht),
          _buildBreakdownRow('Environmental Levy', envLevy),
          _buildBreakdownRow('Infrastructure Levy', infra),
          _buildBreakdownRow('IDF (1%)', idf),
          _buildBreakdownRow('Registration Fee', regFee),
          _buildBreakdownRow('Stamp Duty', stamp),
          _buildBreakdownRow('Registration Form', regForm),
          const SizedBox(height: 6),
          _buildLabelText('Vehicle Category', _invoice.engineSize.isNotEmpty ? 'Car' : 'Car'),
          _buildLabelText('Sheet Used', _getSheetUsed(envLevy)),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double value, {bool isCurrency = true, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label, 
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            isCurrency ? UgandaFormatters.formatCurrency(value) : value.toStringAsFixed(2),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text('$label: ', style: GoogleFonts.poppins(color: Colors.white)),
          Text(value, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final fin = _invoice.isFinalized;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          if (fin) ...[
            const SizedBox(height: 8),
            Text(
              'This invoice is finalized (shared or printed). Editing is disabled.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              if (!fin) ...[
                Expanded(
                  child: _buildActionButton(
                    'Edit',
                    FontAwesomeIcons.pencil,
                    Colors.teal,
                    () => _openInvoiceForEdit(context),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: _buildActionButton(
                  'Generate PDF',
                  FontAwesomeIcons.filePdf,
                  Colors.red,
                  () => _generatePDF(context, _invoice),
                  isLoading: _isGeneratingPDF,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Send Email',
                  FontAwesomeIcons.envelope,
                  Colors.blue,
                  () => _sendEmailInvoice(context, _invoice),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Send WhatsApp',
                  FontAwesomeIcons.whatsapp,
                  Colors.green,
                  () => _sendWhatsAppInvoice(context, _invoice),
                  isLoading: _isSendingWhatsApp,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Print PDF',
                  FontAwesomeIcons.print,
                  Colors.purple,
                  () => _printPDF(context, _invoice),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openInvoiceForEdit(BuildContext context) {
    if (_invoice.isFinalized) return;
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => InvoiceFormScreen(
          customer: _invoice.customer,
          invoice: _invoice,
          type: _invoice.invoiceType,
        ),
      ),
    ).then((_) {
      if (mounted) _loadInvoiceWithCustomer();
    });
  }

  Future<void> _markInvoiceFinalizedIfNeeded() async {
    if (_invoice.isFinalized || _invoice.id == null) return;
    try {
      await InvoiceService().setInvoiceFinalized(_invoice.id!);
      if (!mounted) return;
      setState(() {
        _invoice = _invoice.copyWith(isFinalized: true, status: InvoiceStatus.sent);
      });
      try {
        Provider.of<InvoiceProvider>(context, listen: false).loadInvoices();
      } catch (_) {}
    } catch (e) {
      debugPrint('Failed to persist finalized state: $e');
    }
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap, {bool isLoading = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    )
                  : FaIcon(
                      icon,
                      color: color,
                      size: 24,
                    ),
              const SizedBox(height: 8),
              Text(
                isLoading ? 'Processing...' : title,
                style: GoogleFonts.poppins(
                  color: isLoading ? Colors.white70 : Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusBadgeLabel() {
    if (_invoice.isFinalized) return 'FINAL';
    return _invoice.status.name.toUpperCase();
  }

  Color _statusBadgeBackgroundColor() {
    if (_invoice.isFinalized) return Colors.teal;
    return _getStatusColor(_invoice.status);
  }

  Color _statusBadgeForegroundColor() {
    if (_invoice.isFinalized) return Colors.tealAccent;
    return _getStatusColor(_invoice.status);
  }

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return Colors.grey;
      case InvoiceStatus.sent:
        return Colors.blue;
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _sendWhatsAppInvoice(BuildContext context, Invoice invoice) async {
    // Prevent multiple simultaneous sends
    if (_isSendingWhatsApp) {
      return;
    }

    try {
      if (invoice.customer?.phone == null || invoice.customer!.phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Customer phone number is required for WhatsApp',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Set loading state
      setState(() {
        _isSendingWhatsApp = true;
      });

      // Show processing dialog
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false, // Prevent closing during processing
          child: AlertDialog(
            backgroundColor: const Color(0xFF1A1F3A),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
                const SizedBox(height: 20),
                Text(
                  'Processing WhatsApp message...',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait while we queue your message',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );

      // Use Supabase queue system (works from anywhere - no WiFi required)
      try {
        var pdfPath = await InvoicePdfSync.resolveCanonicalPath(invoice);
        pdfPath ??= await InvoicePdfSync.saveAndRecord(invoice);

        // Send via queue service (automatic - mobile app processes it)
        final autoService = WhatsAppAutoService();
        final success = await autoService.sendInvoiceMessage(
        phoneNumber: invoice.customer!.phone,
        invoiceNumber: invoice.invoiceNumber,
        invoiceDate: UgandaFormatters.formatDate(invoice.invoiceDate),
        totalAmount: invoice.totalAmount,
        customerName: invoice.customer!.name,
          pdfPath: pdfPath,
          messageType: 'invoice',
      );

      if (success) {
        await InvoicePdfSync.uploadForInvoice(invoice, path: pdfPath);
      }

      // Close processing dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                  ? '✅ Invoice queued for WhatsApp! Mobile app will send it automatically.\n\n📱 Make sure mobile app is running.'
                  : 'Failed to queue WhatsApp message',
              style: GoogleFonts.poppins(),
            ),
              backgroundColor: success ? Colors.green : Colors.red,
              duration: Duration(seconds: 5),
          ),
        );
      }
      if (success) await _markInvoiceFinalizedIfNeeded();
    } catch (e) {
      // Close processing dialog if still open
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error: ${e.toString()}',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } finally {
      // Reset loading state
      if (mounted) {
        setState(() {
          _isSendingWhatsApp = false;
        });
      }
    }
  }

  Future<void> _generatePDF(BuildContext context, Invoice invoice) async {
    if (_isGeneratingPDF) return;
    setState(() => _isGeneratingPDF = true);
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploading PDF to cloud...'),
            backgroundColor: Colors.blue,
          ),
        );
      }

      var filePath = await InvoicePdfSync.resolveCanonicalPath(invoice);
      final usedExisting = filePath != null;
      filePath ??= await InvoicePdfSync.saveAndRecord(invoice);

      final uploadError = await InvoicePdfSync.uploadForInvoice(
        invoice,
        path: filePath,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              uploadError == null
                  ? usedExisting
                      ? 'Uploaded existing PDF from Downloads:\n$filePath'
                      : 'PDF saved and uploaded to cloud:\n$filePath'
                  : 'Cloud upload failed:\n$uploadError',
            ),
            backgroundColor: uploadError == null ? Colors.green : Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
      if (uploadError == null) await _markInvoiceFinalizedIfNeeded();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPDF = false);
    }
  }

  Future<void> _printPDF(BuildContext context, Invoice invoice) async {
    try {
      final pdfService = PDFService();
      
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening print dialog...'),
          backgroundColor: Colors.blue,
        ),
      );
      
      // Print PDF
      await pdfService.printPDF(invoice);
      await _markInvoiceFinalizedIfNeeded();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendEmailInvoice(BuildContext context, Invoice invoice) async {
    try {
      if (!isRealCustomerEmail(invoice.customer?.email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Customer email is required for sending invoice',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final emailService = EmailService();
      
      // Note: Email queue system doesn't require SMTP configuration
      // The check is skipped when using queue (useQueue: true by default)

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Generating PDF and sending email...',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );

      // Attach the same PDF file used locally (Downloads), not a separate regeneration
      final pdfBytes = await InvoicePdfSync.readCanonicalBytes(invoice);

      // Send email with PDF attachment
      final success = await emailService.sendInvoiceEmail(
        recipientEmail: invoice.customer!.email,
        recipientName: invoice.customer!.name,
        invoiceNumber: invoice.invoiceNumber,
        invoiceDate: UgandaFormatters.formatDate(invoice.invoiceDate),
        totalAmount: invoice.totalAmount,
        companyName: 'NSB Motors Ug',
        pdfBytes: pdfBytes,
      );

      if (success) {
        await InvoicePdfSync.uploadForInvoice(invoice);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Invoice email sent successfully with PDF attachment!' : 'Failed to send invoice email',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
      if (success) await _markInvoiceFinalizedIfNeeded();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error sending invoice email: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDocumentsSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.fileImage,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Customer Documents',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Documents uploaded for this customer:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: _invoice.images.length,
            itemBuilder: (context, index) {
              final imagePath = _invoice.images[index];
              return GestureDetector(
                onTap: () => _showImagePreview(context, imagePath),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[800],
                          child: const Center(
                            child: FaIcon(
                              FontAwesomeIcons.fileImage,
                              color: Colors.white54,
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showImagePreview(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.black.withOpacity(0.9),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Document Preview',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const FaIcon(
                        FontAwesomeIcons.xmark,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: InteractiveViewer(
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.fileImage,
                              color: Colors.white54,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load image',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModelWithSuffixField() {
    final inputDecoration = InputDecoration(
      hintText: 'Model',
      hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.white38),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        borderSide: const BorderSide(color: Colors.white54),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Model',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _modelController,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                  decoration: inputDecoration.copyWith(hintText: 'e.g. 120i'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  ' / ',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _modelSuffixController,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                  decoration: inputDecoration.copyWith(hintText: 'Optional'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.save_outlined, color: Colors.white70, size: 20),
                onPressed: _invoice.id == null
                    ? null
                    : () async {
                        final model = _modelController.text.trim();
                        final suffix = _modelSuffixController.text.trim();
                        final updated = _invoice.copyWith(
                          vehicleModel: model,
                          vehicleModelSuffix: suffix,
                        );
                        final provider = context.read<InvoiceProvider>();
                        final ok = await provider.updateInvoice(updated);
                        if (mounted && ok) {
                          await _loadInvoiceWithCustomer();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Model saved', style: GoogleFonts.poppins()),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSummary() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle Details',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildInfoItem('Make', _invoice.vehicleMake.isNotEmpty ? _invoice.vehicleMake : 'N/A')),
              Expanded(child: _buildModelWithSuffixField()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildInfoItem('Year', _invoice.vehicleYear > 0 ? _invoice.vehicleYear.toString() : 'N/A')),
              Expanded(child: _buildInfoItem('Chassis No.', _invoice.chassisNo.isNotEmpty ? _invoice.chassisNo : 'N/A')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildInfoItem('Engine Size', _invoice.engineSize.isNotEmpty ? _invoice.engineSize : 'N/A')),
              Expanded(child: _buildInfoItem('Fuel', _invoice.fuelType.isNotEmpty ? _invoice.fuelType : 'N/A')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildInfoItem('Transmission', _invoice.transmission.isNotEmpty ? _invoice.transmission : 'N/A')),
              Expanded(child: _buildInfoItem('Color', _invoice.color.isNotEmpty ? _invoice.color : 'N/A')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCifAndRates() {
    final cifUsd = _invoice.carPriceUSD;
    final rate = _invoice.exchangeRate;
    final cifUgx = cifUsd * rate;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CIF & Exchange Rate',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildInfoItem('CIF (USD)', cifUsd > 0 ? cifUsd.toStringAsFixed(2) : '—')),
              Expanded(child: _buildInfoItem('Exchange Rate', rate > 0 ? rate.toStringAsFixed(2) : '—')),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem('CIF (UGX)', cifUsd > 0 && rate > 0 ? UgandaFormatters.formatCurrency(cifUgx) : '—'),
        ],
      ),
    );
  }

  Widget _buildPhaseOneSection() {
    // Parse all Phase 1 data from notes in one pass
    final notes = _invoice.notes;
    String? selectedMode;
    double phase1Rate = _invoice.exchangeRate;
    double ttUsd = 40.0;
    double cfMombasaUSD = 0.0;
    double cfKampalaUSD = 0.0;
    double clearanceUSD = 0.0;
    bool isCfMombasaSelected = false;
    bool isCfKampalaSelected = false;
    bool isClearanceSelected = false;
    
    if (notes.isNotEmpty) {
      final lines = notes.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        
        // Parse Phase 1 Mode (most reliable)
        if (trimmed.startsWith('Phase 1 Mode:')) {
          final mode = trimmed.substring(14).trim();
          if (mode.isNotEmpty) {
            selectedMode = mode;
          }
        }
        
        // Parse Phase 1 Rate
        if (trimmed.startsWith('Phase 1 Rate:')) {
          final rateStr = trimmed.substring(14).trim(); // "Phase 1 Rate:" is 14 characters
          // Remove any commas or formatting characters
          final cleanRateStr = rateStr.replaceAll(',', '').replaceAll(' ', '');
          final rate = double.tryParse(cleanRateStr);
          if (rate != null && rate > 0) {
            phase1Rate = rate;
          }
        }
        
        // Parse TT Charges
        if (trimmed.startsWith('TT Charges:')) {
          final ttStr = trimmed.substring(11).trim();
          if (ttStr.isNotEmpty && ttStr != '0') {
            final tt = double.tryParse(ttStr);
            if (tt != null && tt > 0) {
              ttUsd = tt;
            }
          }
        }
        
        // Parse C&F Mombasa
        if (trimmed.startsWith('C&F Mombasa:')) {
          final valueStr = trimmed.substring(13).trim();
          if (valueStr != 'Not selected' && valueStr.isNotEmpty) {
            isCfMombasaSelected = true;
            final value = double.tryParse(valueStr);
            if (value != null) {
              cfMombasaUSD = value;
            }
            // Use as fallback if mode not set
            if (selectedMode == null || selectedMode.isEmpty) {
              selectedMode = 'C&F Mombasa';
            }
          }
        }
        
        // Parse C&F Kampala
        if (trimmed.startsWith('C&F Kampala:')) {
          final valueStr = trimmed.substring(13).trim();
          if (valueStr != 'Not selected' && valueStr.isNotEmpty) {
            isCfKampalaSelected = true;
            final value = double.tryParse(valueStr);
            if (value != null) {
              cfKampalaUSD = value;
            }
            // Use as fallback if mode not set
            if (selectedMode == null || selectedMode.isEmpty) {
              selectedMode = 'C&F Kampala';
            }
          }
        }
        
        // Parse Clearance Msa→Kla
        if (trimmed.startsWith('Clearance Msa→Kla:')) {
          final valueStr = trimmed.substring(19).trim();
          if (valueStr != 'Not selected' && valueStr.isNotEmpty) {
            isClearanceSelected = true;
            final value = double.tryParse(valueStr);
            if (value != null) {
              clearanceUSD = value;
            }
            // Use as fallback if mode not set
            if (selectedMode == null || selectedMode.isEmpty) {
              selectedMode = 'Clearance';
            }
          }
        }
      }
    }
    
    // Check for "Phase 1 Selected Options:" line (new format supporting multiple selections)
    String? selectedOptionsStr;
    if (notes.isNotEmpty) {
      final lines = notes.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('Phase 1 Selected Options:')) {
          selectedOptionsStr = trimmed.substring(26).trim();
          break;
        }
      }
    }
    
    // Determine which options are selected (can be 1 or 2)
    final isMombasaSelected = isCfMombasaSelected || 
        (selectedOptionsStr != null && selectedOptionsStr.contains('C&F Mombasa'));
    final isKampalaSelected = isCfKampalaSelected || 
        (selectedOptionsStr != null && selectedOptionsStr.contains('C&F Kampala'));
    final isClearanceSelectedDisplay = isClearanceSelected || 
        (selectedOptionsStr != null && selectedOptionsStr.contains('Clearance'));
    
    // Calculate UGX values
    final ttUgx = ttUsd * phase1Rate;
    final cfMombasaUGX = cfMombasaUSD * phase1Rate;
    final cfKampalaUGX = cfKampalaUSD * phase1Rate;
    final clearanceUGX = clearanceUSD * phase1Rate;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phase 1 — Upfront Costs',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          // Phase 1 Exchange Rate
          _buildBreakdownRow('Phase 1 Exchange Rate', phase1Rate, isCurrency: false),
          
          const SizedBox(height: 16),
          
          // Selected Options Label
          Text(
            'Selected Options:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 12),
          
          // C&F Mombasa Option
          _buildCFOptionRow(
            'C&F Mombasa',
            isMombasaSelected,
            isMombasaSelected ? cfMombasaUSD : 0.0,
          ),
          
          const SizedBox(height: 8),
          
          // Clearance Msa→Kla Option
          _buildCFOptionRow(
            'Clearance Msa→Kla',
            isClearanceSelectedDisplay,
            isClearanceSelectedDisplay ? clearanceUSD : 0.0,
          ),
          
          const SizedBox(height: 8),
          
          // C&F Kampala Option
          _buildCFOptionRow(
            'C&F Kampala',
            isKampalaSelected,
            isKampalaSelected ? cfKampalaUSD : 0.0,
          ),
          
          // Breakdown Section
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          
          // C&F Mombasa (USD) - if selected
          if (isMombasaSelected && cfMombasaUSD > 0)
            _buildBreakdownRow('C&F Mombasa (USD)', cfMombasaUSD, isCurrency: false),
          
          // Clearance Msa→Kla (USD) - if selected
          if (isClearanceSelectedDisplay && clearanceUSD > 0)
            _buildBreakdownRow('Clearance Msa→Kla (USD)', clearanceUSD, isCurrency: false),
          
          // C&F Kampala (USD) - if selected
          if (isKampalaSelected && cfKampalaUSD > 0)
            _buildBreakdownRow('C&F Kampala (USD)', cfKampalaUSD, isCurrency: false),
          
          // TT Charges (USD)
          _buildBreakdownRow('TT Charges (USD)', ttUsd, isCurrency: false),
          
          // C&F Mombasa (UGX) - if selected
          if (isMombasaSelected && cfMombasaUSD > 0)
            _buildBreakdownRow('C&F Mombasa (UGX)', cfMombasaUGX),
          
          // Clearance Msa→Kla (UGX) - if selected
          if (isClearanceSelectedDisplay && clearanceUSD > 0)
            _buildBreakdownRow('Clearance Msa→Kla (UGX)', clearanceUGX),
          
          // C&F Kampala (UGX) - if selected
          if (isKampalaSelected && cfKampalaUSD > 0)
            _buildBreakdownRow('C&F Kampala (UGX)', cfKampalaUGX),
          
          // TT Charges (UGX)
          _buildBreakdownRow('TT Charges (UGX)', ttUgx),
          
          const SizedBox(height: 8),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          
          // Total First Installment
          _buildBreakdownRow(
            'First Installment Total (UGX)',
            _invoice.firstInstallmentUGX,
            isBold: true,
          ),
        ],
      ),
    );
  }
  
  // Helper widget to build C&F option row
  Widget _buildCFOptionRow(String label, bool isSelected, double usdValue) {
    return Row(
      children: [
        Icon(
          isSelected ? Icons.check_circle : Icons.circle_outlined,
          color: isSelected ? Colors.green : Colors.white.withOpacity(0.3),
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        if (isSelected && usdValue > 0)
          Text(
            '${usdValue.toStringAsFixed(2)} USD',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
  
  // Helper methods to parse Phase 1 details from notes
  String? _parsePhase1Mode() {
    final notes = _invoice.notes;
    if (notes.isEmpty) return null;
    
    final lines = notes.split('\n');
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.startsWith('Phase 1 Mode:')) {
        final mode = trimmedLine.substring(14).trim();
        if (mode.isNotEmpty) {
          return mode;
        }
      }
    }
    return null;
  }
  
  double _parsePhase1Rate() {
    final notes = _invoice.notes;
    if (notes.isEmpty) return 0.0;
    
    final lines = notes.split('\n');
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.startsWith('Phase 1 Rate:')) {
        final valueStr = trimmedLine.substring(14).trim(); // "Phase 1 Rate:" is 14 characters
        // Remove any commas or formatting characters
        final cleanRateStr = valueStr.replaceAll(',', '').replaceAll(' ', '');
        final rate = double.tryParse(cleanRateStr);
        if (rate != null && rate > 0) {
          return rate;
        }
      }
    }
    return 0.0;
  }
  
  double _parseTTCharges() {
    final notes = _invoice.notes;
    if (notes.isEmpty) return 0.0;
    
    final lines = notes.split('\n');
    for (final line in lines) {
      if (line.startsWith('TT Charges:')) {
        final valueStr = line.substring(11).trim();
        if (valueStr.isEmpty || valueStr == '0') return 40.0; // Default
        return double.tryParse(valueStr) ?? 40.0;
      }
    }
    return 40.0; // Default to 40 if not found
  }
  
  double _parseCFValue(String label) {
    final notes = _invoice.notes;
    if (notes.isEmpty) return 0.0;
    
    final lines = notes.split('\n');
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.startsWith('$label:')) {
        final valueStr = trimmedLine.substring(label.length + 1).trim();
        if (valueStr == 'Not selected' || valueStr.isEmpty) return 0.0;
        // Parse the value - it might be a number
        final parsed = double.tryParse(valueStr);
        return parsed ?? 0.0;
      }
    }
    return 0.0;
  }
  
  // Helper to check if a C&F option is selected (not "Not selected")
  bool _isCFOptionSelected(String label) {
    final notes = _invoice.notes;
    if (notes.isEmpty) return false;
    
    final lines = notes.split('\n');
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.startsWith('$label:')) {
        final valueStr = trimmedLine.substring(label.length + 1).trim();
        return valueStr != 'Not selected' && valueStr.isNotEmpty;
      }
    }
    return false;
  }

  Widget _buildPhaseTwoSettlementSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phase 2 — Settlement & Registration',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildBreakdownRow('Taxes payable to URA', _ensureUraTaxes()),
          _buildBreakdownRow('Number Plates', _invoice.numberPlatesFee),
          _buildBreakdownRow('3rd Party Insurance', _invoice.thirdPartyInsurance),
          _buildBreakdownRow('Agency Fees', _invoice.agencyFees),
          const SizedBox(height: 8),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          _buildBreakdownRow('Second Installment (UGX)', _ensureSecondInstallment()),
        ],
      ),
    );
  }

  double _ensureUraTaxes() {
    if (_invoice.taxesURA > 0) return _invoice.taxesURA;
    // Fallback to the same logic used in the form
    final cv = _invoice.carPriceUSD * _invoice.exchangeRate;
    final idf = cv * 0.01;
    final importDuty = cv * 0.25;
    final vat = (cv + importDuty) * 0.18;
    final wht = cv * 0.06;
    final infra = cv * 0.015;
    final envLevy = _isEnvironmentalLevyApplicable(_invoice.vehicleYear) ? cv * 0.50 : 0.0;
    const regFee = 1500000.0;
    const stamp = 18000.0;
    const regForm = 35000.0;
    return importDuty + vat + wht + envLevy + idf + infra + regFee + stamp + regForm;
  }

  double _ensureSecondInstallment() {
    if (_invoice.secondInstallmentUGX > 0) return _invoice.secondInstallmentUGX;
    return _ensureUraTaxes() + _invoice.numberPlatesFee + _invoice.thirdPartyInsurance + _invoice.agencyFees;
  }

  int _environmentalCutoffYear() {
    return _invoice.invoiceDate.year - 10;
  }

  bool _isEnvironmentalLevyApplicable(int vehicleYear) {
    if (vehicleYear <= 0) return false;
    return vehicleYear <= _environmentalCutoffYear();
  }

  String _getSheetUsed(double envLevy) {
    // First, try to parse "Sheet Used" from notes
    final notes = _invoice.notes;
    if (notes.isNotEmpty) {
      final lines = notes.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.toLowerCase().startsWith('sheet used:')) {
          final sheetUsed = trimmed.substring(11).trim();
          if (sheetUsed.isNotEmpty) {
            return sheetUsed;
          }
        }
      }
    }
    
    // If not found in notes, determine based on environmental levy
    // If environmental levy > 0, it's "with surcharge", otherwise "without surcharge"
    return envLevy > 0 ? 'with surcharge' : 'without surcharge';
  }

}