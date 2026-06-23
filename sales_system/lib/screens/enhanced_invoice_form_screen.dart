import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/customer_provider.dart';
import '../providers/invoice_provider.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/invoice_type.dart';
import '../utils/uganda_formatters.dart';
import '../services/tax_calculator_service.dart';
import '../widgets/ura_lookup_widget.dart';
import '../widgets/glass_container.dart';
import 'ura_search_screen.dart';
import '../providers/theme_provider.dart';
import '../widgets/glass_liquid_theme.dart';

/// Enhanced Invoice Form with Integrated Tax Calculator
/// This form integrates all 5 Excel sheet tax calculations
/// for accurate vehicle tax quotations
class EnhancedInvoiceFormScreen extends StatefulWidget {
  const EnhancedInvoiceFormScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedInvoiceFormScreen> createState() => _EnhancedInvoiceFormScreenState();
}

class _EnhancedInvoiceFormScreenState extends State<EnhancedInvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _vehicleMakeController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleYearController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _cifController = TextEditingController();
  
  Customer? _selectedCustomer;
  InvoiceType _selectedInvoiceType = InvoiceType.quotation;
  TaxCalculationResult? _taxResult;
  String _selectedTaxSheet = '';

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerEmailController.dispose();
    _customerPhoneController.dispose();
    _vehicleMakeController.dispose();
    _vehicleModelController.dispose();
    _vehicleYearController.dispose();
    _vehicleTypeController.dispose();
    _cifController.dispose();
    super.dispose();
  }

  void _calculateTax() {
    final cifText = _cifController.text.trim();
    if (cifText.isEmpty) return;

    final cif = double.tryParse(cifText);
    if (cif == null || cif <= 0) return;

    final year = int.tryParse(_vehicleYearController.text.trim()) ?? 2020;
    final vehicleType = _vehicleTypeController.text.trim().isNotEmpty 
        ? _vehicleTypeController.text.trim() 
        : 'Car';

    final result = TaxCalculatorService.calculateVehicleTax(
      vehicleType: vehicleType,
      year: year,
      cifUSD: cif,
      exchangeRate: 3834.56, // Current exchange rate USD to UGX
    );

    setState(() {
      _taxResult = result;
      if (result != null) {
        _selectedTaxSheet = result.sheetUsed;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              'Invoice & Quotes',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.transparent,
        elevation: 0,
      ),
          body: Container(
            decoration: BoxDecoration(
              gradient: themeProvider.backgroundGradient,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Create Invoice or Quotation',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Integrated with URA tax calculations for accurate pricing',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 32),

            // Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Customer Information
                  _buildSectionHeader('Customer Information', FontAwesomeIcons.user),
                  const SizedBox(height: 16),
                  _buildCustomerSection(),
                  
                  const SizedBox(height: 32),
                  
                  // Vehicle Information
                  _buildSectionHeader('Vehicle Information', FontAwesomeIcons.car),
                  const SizedBox(height: 16),
                  _buildVehicleSection(),
                  
                  const SizedBox(height: 32),
                  
                  // Tax Calculation
                  _buildSectionHeader('Tax Calculation', FontAwesomeIcons.calculator),
                  const SizedBox(height: 16),
                  _buildTaxCalculationSection(),
                  
                  const SizedBox(height: 32),
                  
                  // Action Buttons
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        FaIcon(icon, color: Colors.orange, size: 20),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerSection() {
    return GlassContainer(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _customerNameController,
                  decoration: InputDecoration(
                    labelText: 'Customer Name',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter customer name';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _customerEmailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _customerPhoneController,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSection() {
    return GlassContainer(
      child: Column(
        children: [
          // URA Lookup Widget
          UraLookupWidget(
            onVehicleSelected: (make, model, year, engineCC, cifUSD) {
              _vehicleMakeController.text = make;
              _vehicleModelController.text = model;
              _vehicleYearController.text = year.toString();
              _cifController.text = cifUSD.toString();
              _calculateTax();
            },
          ),
          
          const SizedBox(height: 16),
          
          // Manual Entry Fields
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _vehicleMakeController,
                  decoration: InputDecoration(
                    labelText: 'Make',
                    prefixIcon: const Icon(Icons.directions_car),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _vehicleModelController,
                  decoration: InputDecoration(
                    labelText: 'Model',
                    prefixIcon: const Icon(Icons.directions_car),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _vehicleYearController,
                  decoration: InputDecoration(
                    labelText: 'Year',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _vehicleTypeController,
                  decoration: InputDecoration(
                    labelText: 'Vehicle Type (Car/Truck)',
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cifController,
            decoration: InputDecoration(
              labelText: 'CIF Value (USD)',
              prefixIcon: const Icon(Icons.attach_money),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) => _calculateTax(),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxCalculationSection() {
    return GlassContainer(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _calculateTax,
                  icon: const FaIcon(FontAwesomeIcons.calculator),
                  label: const Text('Calculate Tax'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
          
          if (_taxResult != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tax Calculation Result',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sheet Used: ${_taxResult!.sheetUsed}',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  Text(
                    'Vehicle Category: ${_taxResult!.vehicleCategory}',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  Text(
                    'Total Tax: ${UgandaFormatters.formatCurrency(_taxResult!.totalTaxUGX)}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Save as quotation
            },
            icon: const FaIcon(FontAwesomeIcons.fileInvoice),
            label: const Text('Save as Quotation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFFFAF0),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Save as invoice
            },
            icon: const FaIcon(FontAwesomeIcons.fileInvoiceDollar),
            label: const Text('Save as Invoice'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
            ),
          ),
        );
      },
    );
  }
}

