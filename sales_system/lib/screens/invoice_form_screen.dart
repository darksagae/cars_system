import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ura_vehicle.dart';
import 'pdf_management_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/invoice_type.dart';
import '../services/tax_calculator_service.dart';
import '../widgets/ura_lookup_widget.dart';
import '../services/enhanced_ura_lookup_service.dart';
// duplicate imports removed
import '../providers/theme_provider.dart';
import '../widgets/glass_liquid_theme.dart';
import '../widgets/glass_container.dart';
import '../providers/invoice_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/payment_provider.dart';
import '../services/pdf/pdf_service.dart';
import '../services/invoice_service.dart';
import '../services/date_service.dart';
import 'invoice_detail_screen.dart';

import '../services/customer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class InvoiceFormScreen extends StatefulWidget {
  final Customer? customer;
  final Invoice? invoice;
  final InvoiceType type;

  const InvoiceFormScreen({
    Key? key,
    this.customer,
    this.invoice,
    this.type = InvoiceType.invoice,
  }) : super(key: key);

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Form controllers
  final _customerNameController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _vehicleDescriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _unitPriceController = TextEditingController();
  final _exchangeRateController = TextEditingController(text: '3834.56');
  final _notesController = TextEditingController();
  final _snVerificationController = TextEditingController();
  final _chassisNoController = TextEditingController();

  // Phase 1 (Upfront) fee inputs
  final _cfMombasaController = TextEditingController(text: '0');
  final _clearanceMsaToKlaController = TextEditingController(text: '0');
  final _cfKampalaController = TextEditingController(text: '0');
  // TT is computed: 40 × CIF(USD) as per NSB; still editable via override if needed
  final _ttOverrideController = TextEditingController(text: '');
  final _exchangeRatePhase1Controller = TextEditingController(text: '3834.56');
  final _taxReasonController = TextEditingController(text: '');

  // Phase 2 (Settlement) fee inputs
  final _numberPlateController = TextEditingController(text: '714300');
  final _thirdPartyInsuranceController = TextEditingController(text: '70000');
  final _agentFeesController = TextEditingController(text: '400000');
  final _registrationProcessController = TextEditingController(text: '2667300');
  final _registrationFeeController = TextEditingController(text: '1500000');
  // Optional Kenya IDF / Infrastructure / Stamp / Reg Form (technical pane)
  final _idfController = TextEditingController(text: '0');
  final _infrastructureLevyController = TextEditingController(text: '0');
  final _stampDutyController = TextEditingController(text: '18000');
  final _regFormController = TextEditingController(text: '35000');

  // Date controllers with auto-fill functionality
  final _invoiceDateController = TextEditingController();
  final _dueDateController = TextEditingController();
  DateTime? _currentInternetDate;
  bool _isLoadingDate = false;

  // Vehicle details
  String? _selectedMake;
  String? _selectedModel;
  int? _selectedYear;
  int? _selectedEngineCC;
  double? _selectedCifUSD;
  String? _selectedSerialNumber;
  String _selectedFuelType = 'Petrol'; // Default fuel type
  String _selectedTransmission = 'Auto'; // Default transmission
  String _selectedColor = 'White'; // Default color
  bool _isCustomColor = false;
  final TextEditingController _customColorController = TextEditingController();
  String _selectedCountryCode = 'JP'; // Default Japan
  
  // Fuel type options
  static const List<String> _fuelTypeOptions = [
    'Petrol',
    'Diesel',
    'Hybrid Petrol',
    'Hybrid Diesel',
    'Electric (EV)',
  ];
  
  // Transmission options
  static const List<String> _transmissionOptions = [
    'Auto',
    'Manual',
    'Auto/Manual',
    'CVT',
    'DCT',
    'Semi-Auto',
    'Sport AT',
    'Unspecified',
  ];

  // Vehicle type options (four categories)
  static const List<String> _vehicleTypeOptions = [
    'Car',
    'Trucks & Cabins',
    '7 Tonne Trucks',
    'Tractor Heads and 20>'
  ];

  // Common car colors (basic set)
  static const List<String> _colorOptions = [
    'White', 'Black', 'Silver', 'Gray', 'Blue', 'Red', 'Green', 'Brown', 'Gold', 'Orange', 'Yellow'
  ];

  // Country of origin options (code -> label)
  static const List<Map<String, String>> _countryOptions = [
    {'code': 'JP', 'label': 'Japan (JP)'},
    {'code': 'AU', 'label': 'Australia (AU)'},
    {'code': 'TH', 'label': 'Thailand (TH)'},
    {'code': 'IN', 'label': 'India (IN)'},
    {'code': 'DE', 'label': 'Germany (DE)'},
    {'code': 'IT', 'label': 'Italy (IT)'},
    {'code': 'US', 'label': 'United States (US)'},
    {'code': 'GB', 'label': 'United Kingdom (GB/UK)'},
    {'code': 'NL', 'label': 'Netherlands (NL)'},
    {'code': 'SE', 'label': 'Sweden (SE)'},
    {'code': 'CN', 'label': 'China (CN)'},
    {'code': 'ZA', 'label': 'South Africa (ZA)'},
    {'code': 'KE', 'label': 'Kenya (KE)'},
    {'code': 'CA', 'label': 'Canada (CA)'},
    {'code': 'FR', 'label': 'France (FR)'},
    {'code': 'AE', 'label': 'United Arab Emirates (AE)'},
    {'code': 'KR', 'label': 'South Korea (KR)'},
    {'code': 'ES', 'label': 'Spain (ES)'},
    {'code': 'AT', 'label': 'Austria (AT)'},
    {'code': 'CH', 'label': 'Switzerland (CH)'},
    {'code': 'BE', 'label': 'Belgium (BE)'},
    {'code': 'BR', 'label': 'Brazil (BR)'},
    {'code': 'MX', 'label': 'Mexico (MX)'},
    {'code': 'RU', 'label': 'Russia (RU)'},
    {'code': 'SG', 'label': 'Singapore (SG)'},
  ];
  
  // Customer-choice controls for tax logic
  String _selectedVehicleClass = 'Car'; // Car, Light Truck, Medium Truck, Heavy Truck, Tractor Head
  double? _selectedTonnage; // for trucks

  // Tax calculation
  TaxCalculationResult? _taxResult;
  bool _isCalculatingTax = false;
  
  // Quick actions loading states
  bool _isPreviewing = false;
  // Computed statutory values (from CV) for totals
  double _computedCv = 0.0;
  double _computedIdf = 0.0;
  double _computedImportDuty = 0.0;
  double _computedVatBase = 0.0;
  double _computedVat = 0.0;
  double _computedWht = 0.0;
  double _computedInfra = 0.0;
  double _computedEnvLevy = 0.0;
  // Customizable percentage inputs for non-Car selections
  final _importDutyPctController = TextEditingController(text: '25');
  final _envLevyPctController = TextEditingController(text: '50');

  // Phase 1 toggles
  bool _tickCfMombasa = true;
  bool _tickClearance = false;
  bool _tickCfKampala = false;
  
  // S/N Verification
  final _enhancedService = EnhancedUraLookupService();
  UraVehicleValidationResult? _snVerificationResult;
  bool _isVerifyingSN = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _setupDynamicConversion();
    _setupExchangeRateListener();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Start periodic refresh of exchange rates (every 5 seconds to catch updates quickly)
    _exchangeRateRefreshTimer?.cancel();
    _exchangeRateRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _loadExchangeRates();
      }
    });
    // Also load immediately
    _loadExchangeRates();
  }
  
  @override
  void didUpdateWidget(InvoiceFormScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload exchange rates when widget is updated
    _loadExchangeRates(forceUpdate: true);
  }

  void _setupDynamicConversion() {
    // Add listeners for dynamic USD to UGX conversion
    _cfMombasaController.addListener(_updateCfMombasaConversion);
    _cfKampalaController.addListener(_updateCfKampalaConversion);
    _clearanceMsaToKlaController.addListener(_updateClearanceConversion);
    _exchangeRatePhase1Controller.addListener(_updateAllConversions);
  }

  void _setupExchangeRateListener() {
    // Add listener for exchange rate changes to update UI
    _exchangeRateController.addListener(() {
      setState(() {
        // This will trigger a rebuild and update the exchange rate display
      });
    });
  }

  void _updateCfMombasaConversion() {
    if (_tickCfMombasa) {
      setState(() {
        // Trigger rebuild to update UGX display
      });
    }
  }

  void _updateCfKampalaConversion() {
    if (_tickCfKampala) {
      setState(() {
        // Trigger rebuild to update UGX display
      });
    }
  }

  void _updateClearanceConversion() {
    if (_tickClearance) {
      setState(() {
        // Trigger rebuild to update UGX display
      });
    }
  }

  void _updateAllConversions() {
    setState(() {
      // Trigger rebuild to update all UGX displays
    });
  }

  List<InvoiceItem> _buildInvoiceItems() {
    final List<InvoiceItem> items = [];
    final rateTax = double.tryParse(_exchangeRateController.text) ?? 0.0;
    final ratePhase1 = double.tryParse(_exchangeRatePhase1Controller.text) ?? rateTax;

    // CIF item (USD/UGX reference)
    if ((_selectedCifUSD ?? 0) > 0) {
      items.add(InvoiceItem(
        productName: 'CIF (${_selectedMake ?? ''} ${_selectedModel ?? ''} ${_selectedYear ?? ''})',
        description: 'Customs value reference',
        price: (_selectedCifUSD ?? 0) * rateTax,
        quantity: 1,
        taxRate: 0,
        discount: 0,
      ));
    }

    // Phase 1 items - include all selected options
    if (_tickCfMombasa) {
      final cfMsaUsd = double.tryParse(_cfMombasaController.text) ?? 0.0;
      if (cfMsaUsd > 0) {
        items.add(InvoiceItem(
          productName: 'C&F Mombasa',
          description: 'C&F Mombasa (Japan → Mombasa)',
          price: cfMsaUsd * ratePhase1,
          quantity: 1,
          taxRate: 0,
          discount: 0,
        ));
      }
    }
    
    if (_tickClearance) {
      final clearanceUsd = double.tryParse(_clearanceMsaToKlaController.text) ?? 0.0;
      if (clearanceUsd > 0) {
        items.add(InvoiceItem(
          productName: 'Clearance Mombasa → Kampala',
          description: 'Clearance Mombasa to Kampala',
          price: clearanceUsd * ratePhase1,
          quantity: 1,
          taxRate: 0,
          discount: 0,
        ));
      }
    }
    
    if (_tickCfKampala) {
      final cfKlaUsd = double.tryParse(_cfKampalaController.text) ?? 0.0;
      if (cfKlaUsd > 0) {
        items.add(InvoiceItem(
          productName: 'C&F Kampala',
          description: 'C&F Kampala (Japan → Kampala)',
          price: cfKlaUsd * ratePhase1,
          quantity: 1,
          taxRate: 0,
          discount: 0,
        ));
      }
    }
    
    // TT Charges (always included)
    final ttUsdFixed = 40.0;
    final ttUsdOverride = double.tryParse(_ttOverrideController.text) ?? 0.0;
    final ttUsd = ttUsdOverride > 0 ? ttUsdOverride : ttUsdFixed;
    if (ttUsd > 0) {
      items.add(InvoiceItem(
        productName: 'TT Charges',
        description: 'TT Charges',
        price: ttUsd * ratePhase1,
        quantity: 1,
        taxRate: 0,
        discount: 0,
      ));
    }

    // URA Taxes breakdown stored as consolidated line
    final ura = _phaseTwoUraTaxesTotal();
    if (ura > 0) {
      items.add(InvoiceItem(
        productName: 'Taxes payable to URA',
        description: 'Import Duty, VAT, WHT, Environmental & Infrastructure Levy, IDF, Stamp, Reg Form',
        price: ura,
        quantity: 1,
        taxRate: 0,
        discount: 0,
      ));
    }

    // Registration fees (Phase 2, converted with Phase 1 rate for USD reference)
    const plates = 714300.0;
    const agent = 400000.0;
    const regProcess = 2667300.0;

    items.add(InvoiceItem(
      productName: 'Number Plates',
      description: 'Registration plates fee',
      price: plates,
      quantity: 1,
      taxRate: 0,
      discount: 0,
    ));
    items.add(InvoiceItem(
      productName: 'Agent Fees (Registration)',
      description: 'Registration agent fees',
      price: agent,
      quantity: 1,
      taxRate: 0,
      discount: 0,
    ));
    items.add(InvoiceItem(
      productName: 'Registration Process',
      description: 'Registration processing fee',
      price: regProcess,
      quantity: 1,
      taxRate: 0,
      discount: 0,
    ));

    return items;
  }

  void _initializeForm() {
    if (widget.customer != null) {
      _customerNameController.text = widget.customer!.name;
      _customerEmailController.text = widget.customer!.email ?? '';
      _customerPhoneController.text = widget.customer!.phone ?? '';
      _customerAddressController.text = widget.customer!.address ?? '';
    }

    if (widget.invoice != null) {
      // Pre-fill invoice data if editing
      _vehicleDescriptionController.text = '${widget.invoice!.vehicleMake} ${widget.invoice!.vehicleModel} (${widget.invoice!.vehicleYear})';
      _quantityController.text = '1';
      _unitPriceController.text = widget.invoice!.carPriceUSD.toString();
      _notesController.text = widget.invoice!.notes;
      _chassisNoController.text = widget.invoice!.chassisNo;
      
      // Pre-fill dates from existing invoice
      _invoiceDateController.text = DateFormat('yyyy-MM-dd').format(widget.invoice!.invoiceDate);
      _dueDateController.text = DateFormat('yyyy-MM-dd').format(widget.invoice!.dueDate);
    } else {
      // Auto-fill dates for new invoice
      _autoFillDates();
    }

    // Ensure default fees are set (survive hot reloads)
    // If empty or zero, force defaults
    final regFeeInit = double.tryParse(_registrationFeeController.text.trim()) ?? 0.0;
    final stampInit = double.tryParse(_stampDutyController.text.trim()) ?? 0.0;
    final regFormInit = double.tryParse(_regFormController.text.trim()) ?? 0.0;
    
    if (regFeeInit <= 0) _registrationFeeController.text = '1500000';
    if (stampInit <= 0) _stampDutyController.text = '18000';
    if (regFormInit <= 0) _regFormController.text = '35000';
    
    // Load exchange rates from SharedPreferences
    _loadExchangeRates();
  }

  Timer? _exchangeRateRefreshTimer;
  
  /// Load exchange rates from SharedPreferences
  Future<void> _loadExchangeRates({bool forceUpdate = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Debug: Check what's in SharedPreferences
      final savedTaxRate = prefs.getDouble('exchange_rate_tax');
      final savedPhase1Rate = prefs.getDouble('exchange_rate_phase1');
      final savedGenericRate = prefs.getDouble('exchange_rate');
      final lastUpdateStr = prefs.getString('exchange_rate_updated');
      
      print('💰 [Invoice Form] Checking exchange rates from SharedPreferences:');
      print('   exchange_rate_tax: $savedTaxRate');
      print('   exchange_rate_phase1: $savedPhase1Rate');
      print('   exchange_rate: $savedGenericRate');
      print('   last_updated: $lastUpdateStr');
      
      // Load tax rate
      final taxRate = savedTaxRate ?? savedGenericRate ?? 3834.56;
      
      // Load phase 1 rate
      final phase1Rate = savedPhase1Rate ?? taxRate;
      
      final currentTaxStr = _exchangeRateController.text.trim();
      final currentPhase1Str = _exchangeRatePhase1Controller.text.trim();
      
      print('   Current form values - Tax: $currentTaxStr, Phase1: $currentPhase1Str');
      
      // Get the last update time to detect remote updates
      bool ratesWereRecentlyUpdated = false;
      
      if (lastUpdateStr != null) {
        try {
          final lastUpdate = DateTime.parse(lastUpdateStr);
          final now = DateTime.now();
          final diffMinutes = now.difference(lastUpdate).inMinutes;
          final diffSeconds = now.difference(lastUpdate).inSeconds;
          // If updated within last 5 minutes, it's likely from remote command - always apply
          if (diffMinutes < 5) {
            ratesWereRecentlyUpdated = true;
            print('💰 Exchange rates were recently updated ($diffSeconds seconds ago), applying defaults...');
          } else {
            print('   Last update was $diffMinutes minutes ago (not recent)');
          }
        } catch (e) {
          print('⚠️ Error parsing update timestamp: $e');
        }
      } else {
        print('   No update timestamp found');
      }
      
      final taxRateStr = taxRate.toStringAsFixed(2);
      final phase1RateStr = phase1Rate.toStringAsFixed(2);
      
      // Always apply saved rates if:
      // 1. Force update requested
      // 2. Rates were recently updated (within 5 minutes) - always apply admin defaults
      // 3. Current values are the hardcoded defaults
      // 4. Saved rates exist and are different from current
      bool shouldUpdateTax = forceUpdate || 
                             ratesWereRecentlyUpdated || 
                             currentTaxStr.isEmpty ||
                             currentTaxStr == '3834.56' ||
                             (prefs.containsKey('exchange_rate_tax') && taxRateStr != currentTaxStr);
      
      bool shouldUpdatePhase1 = forceUpdate || 
                                ratesWereRecentlyUpdated || 
                                currentPhase1Str.isEmpty ||
                                currentPhase1Str == '3834.56' ||
                                (prefs.containsKey('exchange_rate_phase1') && phase1RateStr != currentPhase1Str);
      
      print('   Should update Tax: $shouldUpdateTax, Phase1: $shouldUpdatePhase1');
      
      if (shouldUpdateTax) {
        _exchangeRateController.text = taxRateStr;
        print('✅ Applied default Tax Exchange Rate: $taxRateStr (was: $currentTaxStr)');
      } else {
        print('   Skipping Tax rate update (current: $currentTaxStr, saved: $taxRateStr)');
      }
      
      if (shouldUpdatePhase1) {
        _exchangeRatePhase1Controller.text = phase1RateStr;
        print('✅ Applied default Phase 1 Exchange Rate: $phase1RateStr (was: $currentPhase1Str)');
      } else {
        print('   Skipping Phase1 rate update (current: $currentPhase1Str, saved: $phase1RateStr)');
      }
      
      // Trigger UI update
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('⚠️ Error loading exchange rates: $e');
      print('⚠️ Stack trace: ${StackTrace.current}');
      // Keep default values if loading fails
    }
  }

  /// Auto-fill dates using internet date service with fallback to local date
  Future<void> _autoFillDates() async {
    setState(() {
      _isLoadingDate = true;
    });

    try {
      // Try to get internet date first
      _currentInternetDate = await DateService.getCurrentDate();
      
      // Set invoice date to current internet date
      _invoiceDateController.text = DateFormat('yyyy-MM-dd').format(_currentInternetDate!);
      
      // Set due date to 30 days from invoice date (adjustable)
      final dueDate = _currentInternetDate!.add(const Duration(days: 30));
      _dueDateController.text = DateFormat('yyyy-MM-dd').format(dueDate);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Dates auto-filled with internet date (both dates are adjustable)'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

    } catch (e) {
      // Fallback to local date
      final localDate = DateTime.now();
      _currentInternetDate = localDate;
      
      _invoiceDateController.text = DateFormat('yyyy-MM-dd').format(localDate);
      final dueDate = localDate.add(const Duration(days: 30));
      _dueDateController.text = DateFormat('yyyy-MM-dd').format(dueDate);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Using local date (internet unavailable) - both dates are adjustable'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDate = false;
        });
      }
    }
  }

  /// Refresh dates with current internet date
  Future<void> _refreshDates() async {
    await _autoFillDates();
  }

  /// Select due date using date picker
  Future<void> _selectDueDate() async {
    final currentDueDate = _dueDateController.text.isNotEmpty 
        ? DateTime.tryParse(_dueDateController.text) 
        : DateTime.now().add(const Duration(days: 30));
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: currentDueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.orange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      _dueDateController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
    }
  }

  /// Select invoice date using date picker
  Future<void> _selectInvoiceDate() async {
    final currentInvoiceDate = _invoiceDateController.text.isNotEmpty 
        ? DateTime.tryParse(_invoiceDateController.text) 
        : DateTime.now();
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: currentInvoiceDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)), // Allow dates up to 30 days ago
      lastDate: DateTime.now().add(const Duration(days: 30)), // Allow dates up to 30 days in future
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.orange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      _invoiceDateController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
      
      // Show confirmation message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Invoice date updated to ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _exchangeRateRefreshTimer?.cancel();
    _customerNameController.dispose();
    _customerEmailController.dispose();
    _customerPhoneController.dispose();
    _customerAddressController.dispose();
    _vehicleDescriptionController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _notesController.dispose();
    _snVerificationController.dispose();
    _chassisNoController.dispose();
    _invoiceDateController.dispose();
    _dueDateController.dispose();
    _cfMombasaController.dispose();
    _clearanceMsaToKlaController.dispose();
    _cfKampalaController.dispose();
    _ttOverrideController.dispose();
    _exchangeRatePhase1Controller.dispose();
    _numberPlateController.dispose();
    _thirdPartyInsuranceController.dispose();
    _agentFeesController.dispose();
    _registrationProcessController.dispose();
    _registrationFeeController.dispose();
    _idfController.dispose();
    _infrastructureLevyController.dispose();
    _stampDutyController.dispose();
    _regFormController.dispose();
    _taxReasonController.dispose();
    _importDutyPctController.dispose();
    _envLevyPctController.dispose();
    _customColorController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onVehicleSelected(String make, String model, int year, int engineCC, double cifUSD) {
    setState(() {
      _selectedMake = make;
      _selectedModel = model;
      _selectedYear = year;
      _selectedEngineCC = engineCC;
      _selectedCifUSD = cifUSD;
      _vehicleDescriptionController.text = '$make $model ($year) - $_selectedFuelType, $_selectedTransmission';
      _unitPriceController.text = cifUSD.toStringAsFixed(2);
    });
    _calculateTax();
    _updateTTField();
  }

  void _onVehicleSelectedWithSN(String make, String model, int year, int engineCC, double cifUSD, String? serialNumber) {
    setState(() {
      _selectedMake = make;
      _selectedModel = model;
      _selectedYear = year;
      _selectedEngineCC = engineCC;
      _selectedCifUSD = cifUSD;
      _selectedSerialNumber = serialNumber;
      _vehicleDescriptionController.text = '$make $model ($year) - $_selectedFuelType, $_selectedTransmission${serialNumber != null ? ' [S/N: $serialNumber]' : ''}';
      _unitPriceController.text = cifUSD.toStringAsFixed(2);
    });
    _calculateTax();
    _updateTTField();
  }

  // S/N Verification section
  Widget _buildSNVerificationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, color: GlassLiquidTheme.accentBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'S/N Verification (Optional)',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: GlassLiquidTheme.accentBlue,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the S/N from your physical document to verify the CIF calculation',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _snVerificationController,
                  decoration: InputDecoration(
                    hintText: 'Enter S/N (e.g., 1.0, 149, 688)',
                    hintStyle: GoogleFonts.poppins(color: Colors.white70),
                    prefixIcon: Icon(Icons.tag, color: Color(0xFFFFFAF0)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFFFFFAF0).withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFFFFFAF0).withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFFFFFAF0)),
                    ),
                  ),
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _verifyWithSN,
                icon: _isVerifyingSN 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.verified),
                label: Text(
                  'Verify',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlassLiquidTheme.accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          if (_snVerificationResult != null) ...[
            const SizedBox(height: 12),
            _buildSNVerificationResult(),
          ],
        ],
      ),
    );
  }

  Future<void> _verifyWithSN() async {
    final serialNumber = _snVerificationController.text.trim();
    if (serialNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a serial number to verify'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isVerifyingSN = true;
      _snVerificationResult = null;
    });

    try {
      final result = await _enhancedService.validateVehicleData(
        make: _selectedMake ?? '',
        model: _selectedModel ?? '',
        year: _selectedYear ?? 2020,
        engineCC: _selectedEngineCC ?? 0,
        cifUSD: _selectedCifUSD ?? 0.0,
        serialNumber: serialNumber,
      );

      setState(() {
        _snVerificationResult = result;
        _isVerifyingSN = false;
      });

      if (result.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ CIF verified with S/N $serialNumber'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (result.issues.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ S/N $serialNumber suggests data corrections needed'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }

    } catch (e) {
      setState(() {
        _isVerifyingSN = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSNVerificationResult() {
    final result = _snVerificationResult!;
    
    Color statusColor;
    IconData statusIcon;
    
    if (result.isValid) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (result.correctedVehicle != null) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.error;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.isValid 
                      ? 'CIF verified with S/N ${result.serialNumber}'
                      : 'S/N ${result.serialNumber} suggests corrections',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          
          if (result.issues.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Suggested corrections:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            ...result.issues.map((issue) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      issue,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            )),
            
            if (result.correctedVehicle != null) ...[
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _applySNCorrections(result.correctedVehicle!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Text(
                  'Apply Corrections',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _applySNCorrections(UraVehicle correctedVehicle) {
    setState(() {
      _selectedMake = correctedVehicle.make;
      _selectedModel = correctedVehicle.model;
      _selectedYear = correctedVehicle.year;
      _selectedEngineCC = correctedVehicle.engineCC;
      _selectedCifUSD = correctedVehicle.cifUsd;
      _selectedSerialNumber = correctedVehicle.serialNumber;
      _vehicleDescriptionController.text = '${correctedVehicle.make} ${correctedVehicle.model} (${correctedVehicle.year}) - $_selectedFuelType, $_selectedTransmission [S/N: ${correctedVehicle.serialNumber}]';
      _unitPriceController.text = correctedVehicle.cifUsd.toStringAsFixed(2);
    });
    _calculateTax();
    _updateTTField();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Vehicle data updated with S/N corrections'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _calculateTax() {
    if (_selectedMake == null || _selectedYear == null || _selectedCifUSD == null) {
      return;
    }

    setState(() {
      _isCalculatingTax = true;
    });

    try {
      final result = TaxCalculatorService.calculateVehicleTax(
        vehicleType: _selectedVehicleClass,
        year: _selectedYear!,
        cifUSD: _selectedCifUSD!,
        exchangeRate: double.tryParse(_exchangeRateController.text) ?? 3834.56,
        tonnage: _selectedVehicleClass == 'Car' ? null : _selectedTonnage,
      );

      setState(() {
        _taxResult = result;
        _isCalculatingTax = false;
      });
      
      // Update TT field with calculated value
      _updateTTField();
    } catch (e) {
      setState(() {
        _isCalculatingTax = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error calculating tax: $e')),
      );
    }
  }

  void _updateTTField() {
    final currentOverride = double.tryParse(_ttOverrideController.text) ?? 0.0;
    // Only update if no manual override is set - TT is fixed at 40
    if (currentOverride == 0.0) {
      _ttOverrideController.text = '40.00';
    }
  }

  String _determineVehicleType() {
    final description = _vehicleDescriptionController.text.toLowerCase();
    
    if (description.contains('truck') || description.contains('dumper') || 
        description.contains('tractor') || description.contains('trailer')) {
      return 'truck';
    } else if (description.contains('bus') || description.contains('minibus')) {
      return 'bus';
    } else if (description.contains('motorcycle') || description.contains('bike')) {
      return 'motorcycle';
    } else {
      return 'passenger_car';
    }
  }

  void _saveInvoice() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Update customer details if they were entered in the form
      Customer? updatedCustomer = widget.customer;
      if (_customerNameController.text.isNotEmpty) {
        if (widget.customer != null) {
          // Update existing customer (normalize email/phone to satisfy DB constraints)
          final rawName = _customerNameController.text.trim();
          String email = _customerEmailController.text.trim();
          String phone = _customerPhoneController.text.trim();
          final address = _customerAddressController.text.trim();

          if (phone.isEmpty) {
            phone = 'N/A';
          }

          final customerService = CustomerService();
          if (email.isEmpty) {
            final suffix = DateTime.now().millisecondsSinceEpoch;
            email = 'noemail+$suffix@customer.local';
          } else {
            final existing = await customerService.getCustomerByEmail(email);
            if (existing != null && existing.id != widget.customer!.id) {
              final suffix = DateTime.now().millisecondsSinceEpoch;
              email = email.replaceFirst('@', '+$suffix@');
            }
          }

          updatedCustomer = Customer(
            id: widget.customer!.id,
            name: rawName,
            email: email,
            phone: phone,
            address: address,
            company: widget.customer!.company,
            createdAt: widget.customer!.createdAt,
            updatedAt: DateTime.now(),
          );
          
          // Save updated customer details
          final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
          final ok = await customerProvider.updateCustomer(updatedCustomer);
          if (!ok) {
            // Close loading dialog and report clear failure
            Navigator.of(context).pop();
            _showErrorDialog('Could not update customer. Please adjust email/phone and try again.');
            return;
          }
        } else {
          // Validate minimal customer data
          if (_customerNameController.text.trim().isEmpty) {
            Navigator.of(context).pop();
            _showErrorDialog('Please enter the customer name.');
            return;
          }
          // Create new customer (ensure DB constraints are met)
          final rawName = _customerNameController.text.trim();
          String email = _customerEmailController.text.trim();
          String phone = _customerPhoneController.text.trim();
          final address = _customerAddressController.text.trim();

          // Ensure phone is non-empty (DB requires NOT NULL)
          if (phone.isEmpty) {
            phone = 'N/A';
          }

          // Ensure email is non-empty and unique (DB has NOT NULL UNIQUE)
          final customerService = CustomerService();
          if (email.isEmpty) {
            final suffix = DateTime.now().millisecondsSinceEpoch;
            email = 'noemail+$suffix@customer.local';
          } else {
            final existing = await customerService.getCustomerByEmail(email);
            if (existing != null) {
              final suffix = DateTime.now().millisecondsSinceEpoch;
              email = email.replaceFirst('@', '+$suffix@');
            }
          }

          final newCustomer = Customer(
            id: null, // Let database auto-assign
            name: rawName,
            email: email,
            phone: phone,
            address: address,
            company: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // Save new customer
          final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
          final createdCustomer = await customerProvider.addCustomer(newCustomer);
          if (createdCustomer != null) {
            updatedCustomer = createdCustomer;
          } else {
            // Failed to save customer
            Navigator.of(context).pop();
            _showErrorDialog('Could not save customer. Please check name and email, then try again.');
            return;
          }
        }
      }

      // Ensure we have a persisted customer linked before saving invoice
      if (updatedCustomer == null || (updatedCustomer.id ?? 0) <= 0) {
        // Close loading dialog
        Navigator.of(context).pop();
        _showErrorDialog('Please enter customer details and ensure they are saved before saving the invoice.');
        return;
      }

      // Generate invoice number if creating new invoice
      String invoiceNumber = widget.invoice?.invoiceNumber ?? '';
      if (invoiceNumber.isEmpty) {
        final invoiceService = InvoiceService();
        invoiceNumber = await invoiceService.generateInvoiceNumber();
      }

      // Build from preview so saved data matches exactly what you saw
      final previewBase = _createPreviewInvoice()
          .copyWith(
            // Ensure real invoice number and correct customer linkage
            invoiceNumber: invoiceNumber,
            customerId: updatedCustomer?.id ?? 0,
            customer: updatedCustomer,
            createdAt: widget.invoice?.createdAt ?? DateTime.now(),
            updatedAt: DateTime.now(),
          )
          // Recalculate totals from items for safety
          .calculateTotals();

      final invoice = previewBase;

    // Save invoice using InvoiceProvider
    final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
    
    // Check if this is an update or new invoice
    bool success;
    if (widget.invoice != null && widget.invoice!.id != null) {
      // Update existing invoice
      final updatedInvoice = invoice.copyWith(id: widget.invoice!.id);
      success = await invoiceProvider.updateInvoice(updatedInvoice);
    } else {
      // Create new invoice
      success = await invoiceProvider.addInvoice(invoice);
    }
    
    // Close loading dialog
    Navigator.of(context).pop();
    
    if (success) {
      // Refresh all providers to update dashboard
      Provider.of<CustomerProvider>(context, listen: false).loadCustomers();
      Provider.of<PaymentProvider>(context, listen: false).loadPayments();
      
      _showSuccessDialog();
    } else {
      _showErrorDialog('Failed to save invoice. Please try again.');
    }
    } catch (e) {
      // Close loading dialog if it's still open
      Navigator.of(context).pop();
      _showErrorDialog('Error saving invoice: ${e.toString()}');
    }
  }

  String _buildDetailedNotes(Customer? customer) {
    final buffer = StringBuffer();
    
    // Customer Details
    buffer.writeln('=== CUSTOMER DETAILS ===');
    buffer.writeln('Name: ${customer?.name ?? _customerNameController.text.trim()}');
    buffer.writeln('Email: ${customer?.email ?? _customerEmailController.text.trim()}');
    buffer.writeln('Phone: ${customer?.phone ?? _customerPhoneController.text.trim()}');
    buffer.writeln('Address: ${customer?.address ?? _customerAddressController.text.trim()}');
    buffer.writeln('');
    
    // Vehicle Details
    buffer.writeln('=== VEHICLE DETAILS ===');
    buffer.writeln('Description: ${_vehicleDescriptionController.text}');
    buffer.writeln('Make: ${_selectedMake ?? 'Unknown'}');
    buffer.writeln('Model: ${_selectedModel ?? 'Unknown'}');
    buffer.writeln('Year: ${_selectedYear ?? 2020}');
    buffer.writeln('Engine: ${_selectedEngineCC ?? 0} CC');
    buffer.writeln('Tonnage: ${_selectedTonnage ?? 0.0}');
    buffer.writeln('Quantity: ${_quantityController.text}');
    buffer.writeln('Serial Number: ${_snVerificationController.text}');
    buffer.writeln('');
    
    // Phase 1 Details
    buffer.writeln('=== PHASE 1 (UPFRONT COSTS) ===');
    buffer.writeln('C&F Mombasa: ${_tickCfMombasa ? _cfMombasaController.text : 'Not selected'}');
    buffer.writeln('C&F Kampala: ${_tickCfKampala ? _cfKampalaController.text : 'Not selected'}');
    buffer.writeln('Clearance Msa→Kla: ${_tickClearance ? _clearanceMsaToKlaController.text : 'Not selected'}');
    // Persist Phase 1 selections (can be 1 or 2 options)
    List<String> selectedOptions = [];
    if (_tickCfMombasa) selectedOptions.add('C&F Mombasa');
    if (_tickClearance) selectedOptions.add('Clearance');
    if (_tickCfKampala) selectedOptions.add('C&F Kampala');
    buffer.writeln('Phase 1 Selected Options: ${selectedOptions.join(', ') != '' ? selectedOptions.join(', ') : 'None'}');
    buffer.writeln('Phase 1 Rate: ${_exchangeRatePhase1Controller.text}');
    buffer.writeln('TT Charges: ${_ttOverrideController.text.isNotEmpty ? _ttOverrideController.text : '40'}');
    buffer.writeln('Phase 1 Total: ${_phaseOneTotal().toStringAsFixed(2)} UGX');
    buffer.writeln('');
    
    // Phase 2 Details
    buffer.writeln('=== PHASE 2 (SETTLEMENT) ===');
    final rateTax = double.tryParse(_exchangeRateController.text) ?? 0.0;
    final ratePhase1 = double.tryParse(_exchangeRatePhase1Controller.text) ?? rateTax;
    final uraUgx = _taxResult?.totalTaxUGX ?? 0.0;
    buffer.writeln('URA Taxes: UGX ${NumberFormat('#,##0.00').format(uraUgx)} (USD ${NumberFormat('#,##0.00').format(rateTax == 0 ? 0 : uraUgx / rateTax)})');
    buffer.writeln('Number Plates: UGX 714,300.00 (USD ${NumberFormat('#,##0.00').format(ratePhase1 == 0 ? 0 : 714300 / ratePhase1)})');
    buffer.writeln('Agency Fees: UGX 400,000.00 (USD ${NumberFormat('#,##0.00').format(ratePhase1 == 0 ? 0 : 400000 / ratePhase1)})');
    buffer.writeln('Registration Process: UGX 2,667,300.00 (USD ${NumberFormat('#,##0.00').format(ratePhase1 == 0 ? 0 : 2667300 / ratePhase1)})');
    buffer.writeln('');
    
    // Tax Breakdown
    if (_taxResult != null) {
      buffer.writeln('=== TAX BREAKDOWN ===');
      buffer.writeln('Import Duty: ${_taxResult!.importDuty.toStringAsFixed(2)} UGX');
      buffer.writeln('VAT: ${_taxResult!.vatAmount.toStringAsFixed(2)} UGX');
      buffer.writeln('Withholding Tax: ${_taxResult!.whtAmount.toStringAsFixed(2)} UGX');
      buffer.writeln('Environmental Levy: ${_taxResult!.environmentalLevy.toStringAsFixed(2)} UGX');
      buffer.writeln('Infrastructure Levy: ${_taxResult!.infrastructureLevy.toStringAsFixed(2)} UGX');
      buffer.writeln('Excise Duty: ${_taxResult!.exciseDuty.toStringAsFixed(2)} UGX');
      buffer.writeln('Vehicle Category: ${_taxResult!.vehicleCategory}');
      buffer.writeln('Sheet Used: ${_taxResult!.sheetUsed}');
      buffer.writeln('');
    }
    
    // Additional Notes
    if (_notesController.text.isNotEmpty) {
      buffer.writeln('=== ADDITIONAL NOTES ===');
      buffer.writeln(_notesController.text);
      buffer.writeln('');
    }
    
    return buffer.toString();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          widget.type == InvoiceType.quotation ? 'Quotation Created' : 'Invoice Created',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          widget.type == InvoiceType.quotation 
            ? 'Your quotation has been created successfully!'
            : 'Your invoice has been created successfully!',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(
              'OK',
              style: GoogleFonts.poppins(color: GlassLiquidTheme.accentBlue),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Error',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'OK',
              style: GoogleFonts.poppins(color: GlassLiquidTheme.accentBlue),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              widget.type == InvoiceType.quotation ? 'Create Quotation' : 'Create Invoice',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.save, color: Colors.white),
                onPressed: _saveInvoice,
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: themeProvider.backgroundGradient,
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInvoiceHeaderTable(),
                    const SizedBox(height: 24),
                    _buildCustomerInformationTable(),
                    const SizedBox(height: 24),
                    _buildVehicleDetailsTable(),
                    const SizedBox(height: 24),
                    _buildPhaseOneUpfrontCostsTable(),
                    const SizedBox(height: 24),
                    _buildTaxBreakdownTable(),
                    const SizedBox(height: 24),
                    _buildPhaseTwoSettlementTable(),
                    const SizedBox(height: 24),
                    _buildQuickActionsCard(),
                    const SizedBox(height: 100), // Space for floating button
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _saveInvoice,
            backgroundColor: Colors.white.withOpacity(0.14),
            icon: const Icon(Icons.save, color: Colors.white),
            label: Text(
              widget.type == InvoiceType.quotation ? 'Save Quotation' : 'Save Invoice',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhaseOneUpfrontCostsTable() {
    final cifUsd = _selectedCifUSD ?? 0.0;
    final ratePhase1 = double.tryParse(_exchangeRatePhase1Controller.text) ?? (double.tryParse(_exchangeRateController.text) ?? 0.0);
    
    // TT is fixed at 40 (no multiplication with CIF)
    final ttUsdFixed = 40.0;
    final ttUsdOverride = double.tryParse(_ttOverrideController.text) ?? 0.0;
    // Use override if provided, otherwise use fixed value of 40
    final ttUsd = ttUsdOverride > 0 ? ttUsdOverride : ttUsdFixed;
    final ttUgx = ttUsd * ratePhase1;

    // C&F calculation logic:
    // Use controller values when ticked, otherwise 0.0
    final cfMsaUsd = _tickCfMombasa ? (double.tryParse(_cfMombasaController.text) ?? 0.0) : 0.0;
    final cfKlaUsd = _tickCfKampala ? (double.tryParse(_cfKampalaController.text) ?? 0.0) : 0.0;
    final clearanceUsd = _tickClearance ? (double.tryParse(_clearanceMsaToKlaController.text) ?? 0.0) : 0.0;
    
    // Convert USD to UGX using Phase 1 exchange rate
    final cfMsaValue = cfMsaUsd * ratePhase1;
    final cfKlaValue = cfKlaUsd * ratePhase1;
    final clearanceValue = clearanceUsd * ratePhase1;
    
    // Use _phaseOneTotal() to correctly sum all selected options (can be 1 or 2)
    final firstInstallment = _phaseOneTotal();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.payments, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Phase 1 - Upfront Costs',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                if (_selectedMake != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.4)),
                    ),
                    child: Text(
                      '${_selectedMake} ${_selectedModel ?? ''} (${_selectedYear ?? ''})',
                      style: GoogleFonts.poppins(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Selection: C&F path (only one active at a time)
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                  },
                  children: [
                    TableRow(
                      children: [
                        _buildTableHeader('C&F Mombasa'),
                        _buildTableHeader('Clearance Msa→Kla'),
                        _buildTableHeader('C&F Kampala'),
                      ],
                    ),
                    TableRow(
                      children: [
                        _buildTableCell(
                          CheckboxListTile(
                            value: _tickCfMombasa,
                            onChanged: (v) {
                              setState(() {
                                final newValue = v ?? false;
                                // Count current selections
                                int currentSelections = 0;
                                if (_tickCfMombasa) currentSelections++;
                                if (_tickClearance) currentSelections++;
                                if (_tickCfKampala) currentSelections++;
                                
                                // If trying to select and already have 2 selected, prevent
                                if (newValue && !_tickCfMombasa && currentSelections >= 2) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('You can select maximum 2 options'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                                
                                _tickCfMombasa = newValue;
                                if (_tickCfMombasa) {
                                  // Set default value to 0 when ticked
                                  if (_cfMombasaController.text.trim().isEmpty) {
                                    _cfMombasaController.text = '0';
                                  }
                                } else {
                                  // Reset to 0 when unticked
                                  _cfMombasaController.text = '0';
                                }
                              });
                            },
                            title: Text('C&F Mombasa', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                        _buildTableCell(
                          CheckboxListTile(
                            value: _tickClearance,
                            onChanged: (v) {
                              setState(() {
                                final newValue = v ?? false;
                                // Count current selections
                                int currentSelections = 0;
                                if (_tickCfMombasa) currentSelections++;
                                if (_tickClearance) currentSelections++;
                                if (_tickCfKampala) currentSelections++;
                                
                                // If trying to select and already have 2 selected, prevent
                                if (newValue && !_tickClearance && currentSelections >= 2) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('You can select maximum 2 options'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                                
                                _tickClearance = newValue;
                                if (_tickClearance) {
                                  // Set default value to 0 when ticked
                                  if (_clearanceMsaToKlaController.text.trim().isEmpty) {
                                    _clearanceMsaToKlaController.text = '0';
                                  }
                                } else {
                                  // Reset to 0 when unticked
                                  _clearanceMsaToKlaController.text = '0';
                                }
                              });
                            },
                            title: Text('Clearance', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                        _buildTableCell(
                          CheckboxListTile(
                            value: _tickCfKampala,
                            onChanged: (v) {
                              setState(() {
                                final newValue = v ?? false;
                                // Count current selections
                                int currentSelections = 0;
                                if (_tickCfMombasa) currentSelections++;
                                if (_tickClearance) currentSelections++;
                                if (_tickCfKampala) currentSelections++;
                                
                                // If trying to select and already have 2 selected, prevent
                                if (newValue && !_tickCfKampala && currentSelections >= 2) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('You can select maximum 2 options'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                                
                                _tickCfKampala = newValue;
                                if (_tickCfKampala) {
                                  // Set default value to 0 when ticked
                                  if (_cfKampalaController.text.trim().isEmpty) {
                                    _cfKampalaController.text = '0';
                                  }
                                } else {
                                  // Reset to 0 when unticked
                                  _cfKampalaController.text = '0';
                                }
                              });
                            },
                            title: Text('C&F Kampala', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Cost breakdown table
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                  },
                  children: [
                    TableRow(
                      children: [
                        _buildTableHeader('Description'),
                        _buildTableHeader('USD'),
                        _buildTableHeader('UGX'),
                      ],
                    ),
                    TableRow(
                      children: [
                        _buildTableCell(Text('C&F Mombasa (Japan → Mombasa)', style: GoogleFonts.poppins(color: Colors.white70))),
                        _buildTableCell(
                          TextFormField(
                            controller: _cfMombasaController,
                            enabled: _tickCfMombasa,
                            style: GoogleFonts.poppins(color: Colors.white),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              if (_tickCfMombasa) {
                                setState(() {
                                  // Trigger rebuild to update UGX display
                                });
                              }
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ),
                        ),
                        _buildTableCell(Text('${NumberFormat('#,##0.00').format(cfMsaValue)}', style: GoogleFonts.poppins(color: Colors.white))),
                      ],
                    ),
                    TableRow(
                      children: [
                        _buildTableCell(Text('Clearance Mombasa → Kampala', style: GoogleFonts.poppins(color: Colors.white70))),
                        _buildTableCell(
                          TextFormField(
                            controller: _clearanceMsaToKlaController,
                            enabled: _tickClearance,
                            style: GoogleFonts.poppins(color: Colors.white),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              if (_tickClearance) {
                                setState(() {
                                  // Trigger rebuild to update UGX display
                                });
                              }
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ),
                        ),
                        _buildTableCell(Text('${NumberFormat('#,##0.00').format(clearanceValue)}', style: GoogleFonts.poppins(color: Colors.white))),
                      ],
                    ),
                    TableRow(
                      children: [
                        _buildTableCell(Text('C&F Kampala (Japan → Kampala)', style: GoogleFonts.poppins(color: Colors.white70))),
                        _buildTableCell(
                          TextFormField(
                            controller: _cfKampalaController,
                            enabled: _tickCfKampala,
                            style: GoogleFonts.poppins(color: Colors.white),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              if (_tickCfKampala) {
                                setState(() {
                                  // Trigger rebuild to update UGX display
                                });
                              }
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ),
                        ),
                        _buildTableCell(Text('${NumberFormat('#,##0.00').format(cfKlaValue)}', style: GoogleFonts.poppins(color: Colors.white))),
                      ],
                    ),
                    TableRow(
                      children: [
                        _buildTableCell(Text('TT Charges', style: GoogleFonts.poppins(color: Colors.white70))),
                        _buildTableCell(
                          TextFormField(
                            controller: _ttOverrideController,
                            style: GoogleFonts.poppins(color: Colors.white),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                // Trigger rebuild to update total
                              });
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ),
                        ),
                        _buildTableCell(Text('${NumberFormat('#,##0.00').format(ttUsd * ratePhase1)}', style: GoogleFonts.poppins(color: Colors.white))),
                      ],
                    ),
                    TableRow(
                      children: [
                        _buildTableCell(Text('Exchange Rate (UGX/USD)', style: GoogleFonts.poppins(color: Colors.white70))),
                        _buildTableCell(Text('1.00', style: GoogleFonts.poppins(color: Colors.white))),
                        _buildTableCell(
                          TextFormField(
                            controller: _exchangeRatePhase1Controller,
                            style: GoogleFonts.poppins(color: Colors.white),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                // Trigger rebuild to update all UGX displays
                              });
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Total
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('First Installment Total', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        'UGX ${NumberFormat('#,##0.00').format(firstInstallment)}',
                        style: GoogleFonts.poppins(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseTwoSettlementTable() {
    // Get values from controllers
    final plates = double.tryParse(_numberPlateController.text) ?? 714300.0;
    final insurance = double.tryParse(_thirdPartyInsuranceController.text) ?? 0.0;
    final agent = double.tryParse(_agentFeesController.text) ?? 400000.0;
    
    // Calculate taxes payable to URA using the tax breakdown rate

    final rateTax = double.tryParse(_exchangeRateController.text) ?? 0.0; // Tax breakdown rate
    final ratePhase1 = double.tryParse(_exchangeRatePhase1Controller.text) ?? rateTax; // Phase 1 conversion rate

    // Taxes payable to URA should equal Total (Taxes + Fees) from the tax card
    // Recompute here to ensure Phase 2 displays the same figure
    final cv = (_selectedCifUSD ?? 0.0) * rateTax;
    final idf = cv * 0.01;
    // Import Duty: 25% for Car; otherwise customizable via controller
    final importDutyPct = _selectedVehicleClass == 'Car'
        ? 25.0
        : (double.tryParse(_importDutyPctController.text) ?? 25.0);
    final importDuty = cv * (importDutyPct / 100.0);
    final vat = (cv + importDuty) * 0.18;
    final wht = cv * 0.06;
    final infra = cv * 0.015;
    // Environmental Levy (aka Surcharge): dependent on year; percentage is 50% for Car, customizable for others
    final isEnvYearApplicable = ((_selectedYear ?? 0) <= 2015);
    final envPct = _selectedVehicleClass == 'Car'
        ? 50.0
        : (double.tryParse(_envLevyPctController.text) ?? 50.0);
    final envLevy = isEnvYearApplicable ? cv * (envPct / 100.0) : 0.0;
    final regFee = 1500000.0;
    final stamp = 18000.0;
    final regForm = 35000.0;
    final uraTaxes = importDuty + vat + wht + envLevy + idf + infra + regFee + stamp + regForm;

    // Registration Process = URA Taxes + Number Plate + 3rd Party Insurance + Agent Fees
    final regProcess = uraTaxes + plates + insurance + agent;

    // Second installment equals Registration Process
    final secondInstallment = regProcess;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.assignment_turned_in, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Phase 2 - Settlement',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Settlement breakdown table
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(2),
                  },
                  children: [
                    TableRow(
                      children: [
                        _buildTableHeader('Settlement Component'),
                        _buildTableCellRight(Text('UGX', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white))),
                      ],
                    ),
                    TableRow(
                      children: [
                        _buildTableCell(Text('Taxes payable to URA', style: GoogleFonts.poppins(color: Colors.white70))),
                        _buildTableCellRight(Text('${NumberFormat('#,##0').format(uraTaxes)}', style: GoogleFonts.poppins(color: Colors.white))),
                      ],
                    ),
                    TableRow(
                      children: [
                        _buildTableCell(Text('Number Plate', style: GoogleFonts.poppins(color: Colors.white70))),
                        _buildTableCellRight(
                          TextFormField(
                            controller: _numberPlateController,
                            style: GoogleFonts.poppins(color: Colors.white),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
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
                                borderSide: BorderSide(color: Colors.orange),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onChanged: (value) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        _buildTableCell(Text('3rd Party Insurance', style: GoogleFonts.poppins(color: Colors.white70))),
                        _buildTableCellRight(
                          TextFormField(
                            controller: _thirdPartyInsuranceController,
                            style: GoogleFonts.poppins(color: Colors.white),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
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
                                borderSide: BorderSide(color: Colors.orange),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onChanged: (value) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        _buildTableCell(Text('Agent Fees (Registration Process)', style: GoogleFonts.poppins(color: Colors.white70))),
                        _buildTableCellRight(
                          TextFormField(
                            controller: _agentFeesController,
                            style: GoogleFonts.poppins(color: Colors.white),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
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
                                borderSide: BorderSide(color: Colors.orange),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onChanged: (value) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        _buildTableCell(Text('Registration Process', style: GoogleFonts.poppins(color: Colors.white70))),
                        _buildTableCellRight(Text('${NumberFormat('#,##0').format(regProcess)}', style: GoogleFonts.poppins(color: Colors.orange, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Totals
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Registration Process (Total)', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(
                            'UGX ${NumberFormat('#,##0').format(secondInstallment)}',
                            style: GoogleFonts.poppins(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Grand Total (Phase 1 + Phase 2)', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          Text(
                            'UGX ${NumberFormat('#,##0').format(secondInstallment + _phaseOneTotal())}',
                            style: GoogleFonts.poppins(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Technical Pane ----------
  Widget _buildTechnicalPane() {
    final cif = _selectedCifUSD ?? 0.0;
    final rate = double.tryParse(_exchangeRateController.text) ?? 0.0;
    final cv = cif * rate;
    final idf = double.tryParse(_idfController.text) ?? 0.0;
    final infra = double.tryParse(_infrastructureLevyController.text) ?? 0.0;
    final stamp = double.tryParse(_stampDutyController.text) ?? 0.0;
    final regForm = double.tryParse(_regFormController.text) ?? 0.0;

    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF667EEA)),
              const SizedBox(width: 12),
              Text('Technical Breakdown', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          _buildReadOnlyRow('CIF (USD)', cif, currency: ''),
          _buildReadOnlyRow('Rate (UGX/USD)', rate, currency: ''),
          _buildReadOnlyRow('Year', (_selectedYear ?? 0).toDouble(), currency: ''),
          _buildReadOnlyRow('Customs Value (CV)', cv),
          const Divider(color: Colors.white24),
          _buildAmountField('Import Declaration Fees (IDF)', _idfController),
          _buildAmountField('Stamp Duty', _stampDutyController),
          _buildAmountField('Reg Form', _regFormController),
          _buildAmountField('Infrastructure Levy', _infrastructureLevyController),
        ],
      ),
      ),
    );
  }

  // ---------- Helpers ----------
  double _phaseOneTotal() {
    // Sum all selected Phase 1 options (can be 1 or 2 selections)
    // TT charges are always included (independent)
    final ratePhase1 = double.tryParse(_exchangeRatePhase1Controller.text) ?? (double.tryParse(_exchangeRateController.text) ?? 0.0);
    final ttUsdFixed = 40.0;
    final ttUsdOverride = double.tryParse(_ttOverrideController.text) ?? 0.0;
    final ttUsd = ttUsdOverride > 0 ? ttUsdOverride : ttUsdFixed;
    final ttUgx = ttUsd * ratePhase1;

    double total = 0.0;
    
    // Add C&F Mombasa if selected
    if (_tickCfMombasa) {
      final cfMsaUsd = double.tryParse(_cfMombasaController.text) ?? 0.0;
      total += cfMsaUsd * ratePhase1;
    }
    
    // Add Clearance Mombasa→Kampala if selected
    if (_tickClearance) {
      final clearanceUsd = double.tryParse(_clearanceMsaToKlaController.text) ?? 0.0;
      total += clearanceUsd * ratePhase1;
    }
    
    // Add C&F Kampala if selected
    if (_tickCfKampala) {
      final cfKlaUsd = double.tryParse(_cfKampalaController.text) ?? 0.0;
      total += cfKlaUsd * ratePhase1;
    }

    // Always add TT charges
    return total + ttUgx;
  }

  double _phaseTwoUraTaxesTotal() {
    // Duplicate of Phase 2 UI computation to keep saved data identical
    final cv = (_selectedCifUSD ?? 0.0) * (double.tryParse(_exchangeRateController.text) ?? 0.0);
    final idf = cv * 0.01;
    final importDutyPct2 = _selectedVehicleClass == 'Car'
        ? 25.0
        : (double.tryParse(_importDutyPctController.text) ?? 25.0);
    final importDuty = cv * (importDutyPct2 / 100.0);
    final vat = (cv + importDuty) * 0.18;
    final wht = cv * 0.06;
    final infra = cv * 0.015;
    final isEnvYearApplicable2 = ((_selectedYear ?? 0) <= 2015);
    final envPct2 = _selectedVehicleClass == 'Car'
        ? 50.0
        : (double.tryParse(_envLevyPctController.text) ?? 50.0);
    final envLevy = isEnvYearApplicable2 ? cv * (envPct2 / 100.0) : 0.0;
    final regFee = 1500000.0;
    final stamp = 18000.0;
    final regForm = 35000.0;
    return importDuty + vat + wht + envLevy + idf + infra + regFee + stamp + regForm;
  }

  Widget _buildAmountField(String label, TextEditingController controller, {String? hint}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.poppins(color: Colors.white70),
        hintStyle: GoogleFonts.poppins(color: Colors.white38),
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
          borderSide: BorderSide(color: Color(0xFFFFFAF0)),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        prefixIcon: const Icon(Icons.attach_money, color: Color(0xFFFFFAF0), size: 18),
      ),
      style: GoogleFonts.poppins(color: Colors.white),
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildReadOnlyRow(String label, double amount, {String currency = 'UGX'}) {
    final NumberFormat moneyFmt = NumberFormat('#,##0.00');
    final NumberFormat intFmt = NumberFormat('#,##0');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(color: Colors.white70)),
        Text(
          () {
            if (label.toLowerCase().contains('year')) {
              return intFmt.format(amount);
            }
            final formatted = moneyFmt.format(amount);
            return currency.isEmpty ? formatted : '$currency $formatted';
          }(),
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

// class continues...

  Widget _buildInvoiceHeaderTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Invoice Information',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  children: [
                    _buildTableHeader('Invoice Number'),
                    _buildTableCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(8),
                          color: Colors.white.withOpacity(0.1),
                        ),
                        child: Text(
                          widget.invoice?.invoiceNumber ?? 'Auto-generated',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    _buildTableHeader('Invoice Date'),
                    _buildTableCell(
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _invoiceDateController,
                              style: GoogleFonts.poppins(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'YYYY-MM-DD (adjustable)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onTap: () => _selectInvoiceDate(),
                              readOnly: true, // Use date picker instead of manual input
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _isLoadingDate ? null : _refreshDates,
                            icon: _isLoadingDate 
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh, color: Colors.orange),
                            tooltip: 'Refresh with internet date',
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: _selectInvoiceDate,
                            icon: const Icon(Icons.calendar_today, color: Colors.orange),
                            tooltip: 'Select invoice date',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    _buildTableHeader('Due Date'),
                    _buildTableCell(
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _dueDateController,
                              style: GoogleFonts.poppins(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'YYYY-MM-DD (adjustable)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onTap: () => _selectDueDate(),
                              readOnly: true, // Use date picker instead of manual input
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _selectDueDate,
                            icon: const Icon(Icons.calendar_today, color: Colors.orange),
                            tooltip: 'Select due date',
                          ),
                        ],
                      ),
                    ),
                    _buildTableHeader('Status'),
                    _buildTableCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withOpacity(0.5)),
                        ),
                        child: Text(
                          'Draft',
                          style: GoogleFonts.poppins(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInformationTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Customer Information',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  children: [
                    _buildTableHeader('Customer Name'),
                    _buildTableCell(
                      TextFormField(
                        controller: _customerNameController,
                        style: GoogleFonts.poppins(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter customer name';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    _buildTableHeader('Email'),
                    _buildTableCell(
                      TextFormField(
                        controller: _customerEmailController,
                        style: GoogleFonts.poppins(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    _buildTableHeader('Phone'),
                    _buildTableCell(
                      TextFormField(
                        controller: _customerPhoneController,
                        style: GoogleFonts.poppins(color: Colors.white),
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    _buildTableHeader('Address'),
                    _buildTableCell(
                      TextFormField(
                        controller: _customerAddressController,
                        style: GoogleFonts.poppins(color: Colors.white),
                        maxLines: 2,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTableCell(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: child,
    );
  }

  Widget _buildTableCellRight(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: child,
      ),
    );
  }

  Widget _buildVehicleDetailsTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_car, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Vehicle Details',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // URA Vehicle Lookup Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0E21),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Search URA Database',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final selectedVehicle = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PdfManagementScreen(),
                                ),
                              );
                              if (selectedVehicle != null && selectedVehicle is UraVehicle) {
                                _onVehicleSelectedWithSN(
                                  selectedVehicle.make,
                                  selectedVehicle.model,
                                  selectedVehicle.year,
                                  selectedVehicle.engineCC,
                                  selectedVehicle.cifUsd,
                                  selectedVehicle.serialNumber,
                                );
                              }
                            },
                            icon: const Icon(Icons.picture_as_pdf, size: 16),
                            label: Text(
                              'PDF Search',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GlassLiquidTheme.accentBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select vehicle from the official URA database to auto-populate details and calculate accurate taxes.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 12),
                      UraLookupWidget(
                        onVehicleSelected: _onVehicleSelectedWithSN,
                        initialMake: _selectedMake,
                        initialModel: _selectedModel,
                        initialYear: _selectedYear,
                        initialEngineCC: _selectedEngineCC,
                        initialCifUSD: _selectedCifUSD,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Vehicle Details Table
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(2),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(2),
                  },
                  children: [
                    TableRow(
                      children: [
                        _buildTableHeader('Make'),
                        _buildTableCell(
                          TextFormField(
                            controller: TextEditingController(text: _selectedMake ?? ''),
                            style: GoogleFonts.poppins(color: Colors.white),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                        _buildTableHeader('Model'),
                        _buildTableCell(
                          TextFormField(
                            controller: TextEditingController(text: _selectedModel ?? ''),
                            style: GoogleFonts.poppins(color: Colors.white),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        _buildTableHeader('Year'),
                        _buildTableCell(
                          TextFormField(
                            controller: TextEditingController(text: _selectedYear?.toString() ?? ''),
                            style: GoogleFonts.poppins(color: Colors.white),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                        _buildTableHeader('Engine CC'),
                        _buildTableCell(
                          TextFormField(
                            controller: TextEditingController(text: _selectedEngineCC?.toString() ?? ''),
                            style: GoogleFonts.poppins(color: Colors.white),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        _buildTableHeader('CIF USD'),
                        _buildTableCell(
                          TextFormField(
                            controller: TextEditingController(text: _selectedCifUSD?.toString() ?? ''),
                            style: GoogleFonts.poppins(color: Colors.white),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                        _buildTableHeader('Serial Number'),
                        _buildTableCell(
                          TextFormField(
                            controller: _snVerificationController,
                            style: GoogleFonts.poppins(color: Colors.white),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        _buildTableHeader('Chassis No.'),
                        _buildTableCell(
                          TextFormField(
                            controller: _chassisNoController,
                            style: GoogleFonts.poppins(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Enter chassis/VIN',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                        _buildTableHeader(''),
                        const SizedBox.shrink(),
                      ],
                    ),
                    TableRow(
                      children: [
                        _buildTableHeader('Fuel Type'),
                        _buildTableCell(
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedFuelType,
                                isExpanded: true,
                                dropdownColor: Colors.grey[800],
                                style: GoogleFonts.poppins(color: Colors.white),
                                items: _fuelTypeOptions.map((String fuelType) {
                                  return DropdownMenuItem<String>(
                                    value: fuelType,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      child: Text(fuelType),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedFuelType = newValue;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        _buildTableHeader('Transmission'),
                        _buildTableCell(
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedTransmission,
                                isExpanded: true,
                                dropdownColor: Colors.grey[800],
                                style: GoogleFonts.poppins(color: Colors.white),
                                items: _transmissionOptions.map((String transmission) {
                                  return DropdownMenuItem<String>(
                                    value: transmission,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      child: Text(transmission),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedTransmission = newValue;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        _buildTableHeader('Vehicle Type'),
                        _buildTableCell(
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedVehicleClass,
                                isExpanded: true,
                                dropdownColor: Colors.grey[800],
                                style: GoogleFonts.poppins(color: Colors.white),
                                items: _vehicleTypeOptions.map((String vt) {
                                  return DropdownMenuItem<String>(
                                    value: vt,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      child: Text(vt),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedVehicleClass = newValue;
                                      // When switching class, set default Environmental (Surcharge) % by year
                                      final isYearApplicable = (_selectedYear ?? 0) <= 2015;
                                      _envLevyPctController.text = isYearApplicable ? '50' : '0';
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        _buildTableHeader(''),
                        const SizedBox.shrink(),
                      ],
                    ),
                    if (_selectedVehicleClass != 'Car')
                      TableRow(
                        children: [
                          _buildTableHeader('Custom Tax %'),
                          _buildTableCell(
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _importDutyPctController,
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.poppins(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'Import Duty %',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _envLevyPctController,
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.poppins(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'Environmental (Surcharge) %',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildTableHeader(''),
                          const SizedBox.shrink(),
                        ],
                      ),
                    TableRow(
                      children: [
                        _buildTableHeader('Color'),
                        _buildTableCell(
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _isCustomColor ? 'Custom...' : _selectedColor,
                                      isExpanded: true,
                                      dropdownColor: Colors.grey[800],
                                      style: GoogleFonts.poppins(color: Colors.white),
                                      items: [
                                        ..._colorOptions.map((c) => DropdownMenuItem<String>(
                                              value: c,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                child: Text(c),
                                              ),
                                            )),
                                        const DropdownMenuItem<String>(
                                          value: 'Custom...',
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            child: Text('Custom...'),
                                          ),
                                        ),
                                      ],
                                      onChanged: (String? newValue) {
                                        if (newValue == null) return;
                                        setState(() {
                                          if (newValue == 'Custom...') {
                                            _isCustomColor = true;
                                            if (_customColorController.text.isEmpty) {
                                              _customColorController.text = _selectedColor;
                                            }
                                          } else {
                                            _isCustomColor = false;
                                            _selectedColor = newValue;
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              if (_isCustomColor) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _customColorController,
                                    style: GoogleFonts.poppins(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'Enter custom color',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    onChanged: (v) {
                                      setState(() {});
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        _buildTableHeader('Country of Origin'),
                        _buildTableCell(
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCountryCode,
                                isExpanded: true,
                                dropdownColor: Colors.grey[800],
                                style: GoogleFonts.poppins(color: Colors.white),
                                items: _countryOptions.map((m) {
                                  return DropdownMenuItem<String>(
                                    value: m['code']!,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      child: Text(m['label']!),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedCountryCode = newValue;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Selected Vehicle Info Display
                if (_selectedMake != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Selected Vehicle',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Make: $_selectedMake', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white)),
                        Text('Model: $_selectedModel', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white)),
                        Text('Year: $_selectedYear', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white)),
                  if (_selectedEngineCC != null)
                    Text('Engine: ${_selectedEngineCC}cc', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white)),
                        Text('Fuel Type: $_selectedFuelType', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white)),
                        Text('Transmission: $_selectedTransmission', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white)),
                        if (_chassisNoController.text.trim().isNotEmpty)
                          Text('Chassis No.: ${_chassisNoController.text.trim()}', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white)),
                        Text('Vehicle Type: $_selectedVehicleClass', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white)),
                        Text('Color: ${_isCustomColor ? _customColorController.text : _selectedColor}', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white)),
                        Text('Country of Origin: ${_countryOptions.firstWhere((c) => c['code'] == _selectedCountryCode)['label']}', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white)),
                  if (_selectedSerialNumber != null)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: GlassLiquidTheme.accentBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: GlassLiquidTheme.accentBlue.withOpacity(0.5)),
                      ),
                      child: Text(
                        'S/N: $_selectedSerialNumber',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: GlassLiquidTheme.accentBlue,
                        ),
                      ),
                    ),
                  Text(
                    'CIF Value: \$${_selectedCifUSD?.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green),
                  ),
                ],
              ),
            ),
            
            // S/N Verification Section (appears after CIF is calculated)
            if (_selectedCifUSD != null) ...[
              const SizedBox(height: 16),
              _buildSNVerificationSection(),
            ],
            const SizedBox(height: 16),
            _buildTextField(
              controller: _vehicleDescriptionController,
              label: 'Vehicle Description',
              icon: Icons.description,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter vehicle description';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _quantityController,
                    label: 'Quantity',
                    icon: Icons.numbers,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter quantity';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _unitPriceController,
                    label: 'Unit Price (USD)',
                    icon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter unit price';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      ),
      ],
    ),
    );
  }

  Widget _buildVehicleClassSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Row(
            children: [
              const Icon(Icons.category, color: Color(0xFFFFFAF0)),
              const SizedBox(width: 12),
        Text(
                'Vehicle Classification',
          style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Select the vehicle class for accurate tax calculation:',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedVehicleClass,
            decoration: InputDecoration(
              labelText: 'Vehicle Class',
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
            items: const [
              DropdownMenuItem(value: 'Car', child: Text('Car')),
              DropdownMenuItem(value: 'Light Truck', child: Text('Light Truck')),
              DropdownMenuItem(value: 'Medium Truck', child: Text('Medium Truck')),
              DropdownMenuItem(value: 'Heavy Truck', child: Text('Heavy Truck')),
              DropdownMenuItem(value: 'Tractor Head', child: Text('Tractor Head')),
              DropdownMenuItem(value: 'Double/Single Cabin', child: Text('Double/Single Cabin')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedVehicleClass = value ?? 'Car';
                if (_selectedVehicleClass == 'Car') {
                  _selectedTonnage = null;
                }
                // Default Environmental (Surcharge) % based on year whenever class changes
                final isYearApplicable = (_selectedYear ?? 0) <= 2015;
                _envLevyPctController.text = isYearApplicable ? '50' : '0';
              });
              _calculateTax();
            },
          ),
          if (_selectedVehicleClass != 'Car') ...[
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _selectedTonnage?.toString() ?? '',
              decoration: InputDecoration(
                labelText: 'Tonnage (required for trucks)',
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
              style: GoogleFonts.poppins(color: Colors.white),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (_selectedVehicleClass != 'Car' && (value == null || value.isEmpty)) {
                  return 'Please enter tonnage for trucks';
                }
                return null;
              },
              onChanged: (value) {
                _selectedTonnage = double.tryParse(value);
                _calculateTax();
          },
        ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _importDutyPctController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Import Duty %',
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
                    style: GoogleFonts.poppins(color: Colors.white),
                    onChanged: (_) => setState(() => _calculateTax()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _envLevyPctController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Environmental (Surcharge) %',
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
                    style: GoogleFonts.poppins(color: Colors.white),
                    onChanged: (_) => setState(() => _calculateTax()),
                  ),
                ),
              ],
        ),
      ],
        ],
      ),
    );
  }

  Widget _buildTaxBreakdownTable() {
    final rate = double.tryParse(_exchangeRateController.text) ?? 0.0;
    final cv = (_selectedCifUSD ?? 0.0) * rate;
    final idf = cv * 0.01;
    final importDutyPct3 = _selectedVehicleClass == 'Car'
        ? 25.0
        : (double.tryParse(_importDutyPctController.text) ?? 25.0);
    final importDuty = cv * (importDutyPct3 / 100.0);
    final wht = cv * 0.06;
    final infra = cv * 0.015;
    final isEnvLevyApplicable = (_selectedYear ?? 0) <= 2015;
    final envPct3 = _selectedVehicleClass == 'Car'
        ? 50.0
        : (double.tryParse(_envLevyPctController.text) ?? 50.0);
    final envLevy = isEnvLevyApplicable ? cv * (envPct3 / 100.0) : 0.0;
    final vatBase = cv + importDuty;
    final vat = vatBase * 0.18;
    final regFee = 1500000.0;
    final stamp = 18000.0;
    final regForm = 35000.0;
    final totalTaxes = importDuty + vat + wht + envLevy + idf + infra + regFee + stamp + regForm;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calculate, color: Colors.white),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                  'Tax Breakdown',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                    ),
                    Text(
                      'Exchange Rate: ${NumberFormat('#,##0.00').format(double.tryParse(_exchangeRateController.text) ?? 3834.56)} UGX/USD',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (_isCalculatingTax)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Exchange Rate Input
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exchange Rate for Tax Calculation',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _exchangeRateController,
                              style: GoogleFonts.poppins(color: Colors.white),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'UGX per USD',
                                labelStyle: GoogleFonts.poppins(color: Colors.white70),
                                hintText: '3834.56',
                                hintStyle: GoogleFonts.poppins(color: Colors.white54),
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
                                  borderSide: BorderSide(color: Colors.orange),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                    onPressed: _calculateTax,
                    icon: const Icon(Icons.calculate),
                    label: Text('Calculate Tax', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Tax breakdown table
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(2),
                  },
                  children: [
                    TableRow(
                      children: [
                        _buildTableHeader('Tax Component'),
                        _buildTableCellRight(Text('UGX', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white))),
                      ],
                    ),
                    TableRow(
                      children: [
                        _buildTableCell(Text('CIF', style: GoogleFonts.poppins(color: Colors.white70))),
                        _buildTableCellRight(Text('${NumberFormat('#,##0.00').format(cv)}', style: GoogleFonts.poppins(color: Colors.white))),
                      ],
                    ),
                    TableRow(
                      children: [
                        _buildTableCell(Text('Import Declaration Fees (1%)', style: GoogleFonts.poppins(color: Colors.white70))),
                        _buildTableCellRight(Text('${NumberFormat('#,##0.00').format(idf)}', style: GoogleFonts.poppins(color: Colors.white))),
                      ],
                    ),
                    TableRow(
                      children: [
                        _buildTableCell(Text('Import Duty ('
                            '{${_selectedVehicleClass == 'Car' ? '25' : (_importDutyPctController.text.isEmpty ? '25' : _importDutyPctController.text)}%}'
                            ')', style: GoogleFonts.poppins(color: Colors.white70))),
                        _buildTableCellRight(Text('${NumberFormat('#,##0.00').format(importDuty)}', style: GoogleFonts.poppins(color: Colors.white))),
                      ],
                    ),
                    TableRow(
                      children: [
                        _buildTableCell(Text('VAT (18%)', style: GoogleFonts.poppins(color: Colors.white70))),
                        _buildTableCellRight(Text('${NumberFormat('#,##0.00').format(vat)}', style: GoogleFonts.poppins(color: Colors.white))),
                      ],
                    ),
                    TableRow(
                      children: [
                        _buildTableCell(Text('WHT (6%)', style: GoogleFonts.poppins(color: Colors.white70))),
                        _buildTableCellRight(Text('${NumberFormat('#,##0.00').format(wht)}', style: GoogleFonts.poppins(color: Colors.white))),
                      ],
                    ),
                    TableRow(
                      children: [
                        _buildTableCell(Text('Infrastructure Levy (1.5%)', style: GoogleFonts.poppins(color: Colors.white70))),
                        _buildTableCellRight(Text('${NumberFormat('#,##0.00').format(infra)}', style: GoogleFonts.poppins(color: Colors.white))),
                      ],
                    ),
                    if (isEnvLevyApplicable)
                      TableRow(
                        children: [
                          _buildTableCell(Text('Environmental Levy ('
                              '{${_selectedVehicleClass == 'Car' ? '50' : (_envLevyPctController.text.isEmpty ? '50' : _envLevyPctController.text)}%}'
                              ')', style: GoogleFonts.poppins(color: Colors.white70))),
                          _buildTableCellRight(Text('${NumberFormat('#,##0.00').format(envLevy)}', style: GoogleFonts.poppins(color: Colors.white))),
                        ],
                      ),
                    TableRow(
                      children: [
                        _buildTableCell(Text('Registration Fee', style: GoogleFonts.poppins(color: Colors.white70))),
                        _buildTableCellRight(Text('${NumberFormat('#,##0.00').format(regFee)}', style: GoogleFonts.poppins(color: Colors.white))),
                      ],
                    ),
                    TableRow(
                      children: [
                        _buildTableCell(Text('Stamp Duty', style: GoogleFonts.poppins(color: Colors.white70))),
                        _buildTableCellRight(Text('${NumberFormat('#,##0.00').format(stamp)}', style: GoogleFonts.poppins(color: Colors.white))),
                      ],
                    ),
                    TableRow(
                      children: [
                        _buildTableCell(Text('Registration Form', style: GoogleFonts.poppins(color: Colors.white70))),
                        _buildTableCellRight(Text('${NumberFormat('#,##0.00').format(regForm)}', style: GoogleFonts.poppins(color: Colors.white))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Total
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Taxes & Fees', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        'UGX ${NumberFormat('#,##0.00').format(totalTaxes)}',
                        style: GoogleFonts.poppins(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  

  Widget _buildTaxRow(String label, double amount, {bool isCurrency = true, String currencyLabel = 'UGX'}) {
    final NumberFormat moneyFmt = NumberFormat('#,##0.00');
    final NumberFormat intFmt = NumberFormat('#,##0');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
          ),
          Text(
            () {
              if (!isCurrency && label.toLowerCase().contains('year')) {
                return intFmt.format(amount);
              }
              final formatted = moneyFmt.format(amount);
              return isCurrency ? '$currencyLabel $formatted' : formatted;
            }(),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDualCurrencyRow({
    required String label,
    required double usd,
    required double ugx,
    bool showCurrencyPrefix = true,
  }) {
    final NumberFormat moneyFmt = NumberFormat('#,##0.00');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          // Label left
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
            ),
          ),
          // USD center
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                showCurrencyPrefix ? 'USD ${moneyFmt.format(usd)}' : moneyFmt.format(usd),
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
              ),
            ),
          ),
          // UGX right
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                showCurrencyPrefix ? 'UGX ${moneyFmt.format(ugx)}' : moneyFmt.format(ugx),
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on, color: Color(0xFFFFFAF0)),
              const SizedBox(width: 12),
              Text(
                'Quick Actions',
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
                child: ElevatedButton.icon(
                  onPressed: _isCalculatingTax ? null : _calculateTax,
                  icon: _isCalculatingTax 
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.calculate, size: 18),
                  label: Text(
                    _isCalculatingTax ? 'Calculating...' : 'Calculate Tax', 
                    style: GoogleFonts.poppins(fontSize: 12)
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Clear form action
                    setState(() {
                      _customerNameController.clear();
                      _customerEmailController.clear();
                      _customerPhoneController.clear();
                      _customerAddressController.clear();
                      _vehicleDescriptionController.clear();
                      _selectedMake = null;
                      _selectedModel = null;
                      _selectedYear = null;
                      _selectedEngineCC = null;
                      _selectedCifUSD = null;
                      _selectedSerialNumber = null;
                      _selectedFuelType = 'Petrol';
                      _selectedTransmission = 'Auto';
                      _selectedColor = 'White';
                      _isCustomColor = false;
                      _customColorController.clear();
                      _selectedCountryCode = 'JP';
                      _selectedVehicleClass = 'Car';
                      _chassisNoController.clear();
                      _taxResult = null;
                    });
                  },
                  icon: const Icon(Icons.clear, size: 18),
                  label: Text('Clear Form', style: GoogleFonts.poppins(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          // Preview button disabled - invoice is always shown when saved
          const SizedBox(height: 16),
          // Notes field
          _buildTextField(
            controller: _notesController,
            label: 'Additional Notes (Optional)',
            icon: Icons.note,
            maxLines: 2,
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
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.white70),
        prefixIcon: Icon(icon, color: const Color(0xFFFFFAF0)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFFFFAF0)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: const Color(0xFF0A0E21),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildPhoneNumberField() {
    return Row(
      children: [
        // Country code input field
        Container(
          width: 100,
          child: TextFormField(
            initialValue: '+256', // Uganda country code
            keyboardType: TextInputType.phone,
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Code',
              labelStyle: GoogleFonts.poppins(color: Colors.white70),
              prefixIcon: const Icon(Icons.flag, color: Color(0xFFFFFAF0)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFFFFAF0)),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red),
              ),
              filled: true,
              fillColor: const Color(0xFF0A0E21),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Phone number input
        Expanded(
          child: TextFormField(
            controller: _customerPhoneController,
            keyboardType: TextInputType.phone,
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Phone Number',
              labelStyle: GoogleFonts.poppins(color: Colors.white70),
              prefixIcon: const Icon(Icons.phone, color: Color(0xFFFFFAF0)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFFFFAF0)),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red),
              ),
              filled: true,
              fillColor: const Color(0xFF0A0E21),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  // Quick Actions Methods
  void _previewInvoice() async {
    if (_selectedMake == null || _selectedModel == null || _selectedYear == null || _selectedCifUSD == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a vehicle and calculate tax before previewing'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isPreviewing = true;
    });

    try {
      // Create a temporary invoice object for preview
      final previewInvoice = _createPreviewInvoice();
      
      // Navigate to invoice detail screen for preview
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InvoiceDetailScreen(invoice: previewInvoice),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating preview: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isPreviewing = false;
      });
    }
  }

  Invoice _createPreviewInvoice() {
    final customer = _getCurrentCustomer();
    
    // Generate preview invoice number if creating new invoice
    String previewInvoiceNumber = widget.invoice?.invoiceNumber ?? '';
    if (previewInvoiceNumber.isEmpty) {
      previewInvoiceNumber = 'PREVIEW-${DateTime.now().millisecondsSinceEpoch}';
    }
    
    // Gather phase two inputs
    final plates = double.tryParse(_numberPlateController.text) ?? 714300.0;
    final insurance = double.tryParse(_thirdPartyInsuranceController.text) ?? 0.0;
    final agent = double.tryParse(_agentFeesController.text) ?? 400000.0;
    final uraTaxes = _phaseTwoUraTaxesTotal();
    final secondInstallment = uraTaxes + plates + insurance + agent;

    // Build line items for a consistent preview list
    final items = _buildInvoiceItems();
    
    // Build detailed notes that include Phase 1 Rate and other details
    final detailedNotes = _buildDetailedNotes(customer);
    // Append user notes if any
    final finalNotes = _notesController.text.trim().isNotEmpty 
        ? '$detailedNotes\n\n=== USER NOTES ===\n${_notesController.text.trim()}'
        : detailedNotes;

    // Create a temporary invoice object with current form data
    return Invoice(
      id: widget.invoice?.id,
      invoiceNumber: previewInvoiceNumber,
      invoiceDate: DateTime.tryParse(_invoiceDateController.text) ?? DateTime.now(),
      dueDate: DateTime.tryParse(_dueDateController.text) ?? DateTime.now().add(const Duration(days: 30)),
      customerId: customer?.id ?? 0,
      customer: customer,
      vehicleMake: _selectedMake ?? '',
      vehicleModel: _selectedModel ?? '',
      vehicleYear: _selectedYear ?? 0,
      chassisNo: _chassisNoController.text.trim(),
      engineSize: _selectedEngineCC?.toString() ?? '',
      fuelType: _selectedFuelType,
      transmission: _selectedTransmission,
      color: _isCustomColor ? _customColorController.text.trim() : _selectedColor,
      countryOfOrigin: _selectedCountryCode,
      carPriceUSD: _selectedCifUSD ?? 0.0,
      exchangeRate: double.tryParse(_exchangeRateController.text) ?? 3834.56,
      taxesURA: uraTaxes,
      firstInstallmentUGX: _phaseOneTotal(),
      numberPlatesFee: plates,
      thirdPartyInsurance: insurance,
      agencyFees: agent,
      secondInstallmentUGX: secondInstallment,
      items: items,
      totalAmount: _calculateTotalAmount(),
      notes: finalNotes,
      invoiceType: widget.type == InvoiceType.quotation ? InvoiceType.carSale : InvoiceType.invoice,
    );
  }

  Customer? _getCurrentCustomer() {
    if (widget.customer != null) {
      return widget.customer;
    }
    
    // Create customer from form data
    final name = _customerNameController.text.trim();
    final email = _customerEmailController.text.trim();
    final phone = _customerPhoneController.text.trim();
    final address = _customerAddressController.text.trim();
    
    if (name.isEmpty) return null;
    
    return Customer(
      id: widget.customer?.id,
      name: name,
      email: email.isNotEmpty ? email : '',
      phone: phone.isNotEmpty ? phone : '',
      address: address.isNotEmpty ? address : '',
      createdAt: widget.customer?.createdAt ?? DateTime.now(),
    );
  }

  double _calculateTotalAmount() {
    if (_selectedCifUSD == null) return 0.0;
    
    final exchangeRate = double.tryParse(_exchangeRateController.text) ?? 3834.56;
    final cifUgx = _selectedCifUSD! * exchangeRate;
    
    // Add tax if calculated
    double totalTax = 0.0;
    if (_taxResult != null) {
      totalTax = _taxResult!.totalTaxUGX;
    }
    
    // Add fees
    final cfMombasa = double.tryParse(_cfMombasaController.text) ?? 0.0;
    final clearanceMsaToKla = double.tryParse(_clearanceMsaToKlaController.text) ?? 0.0;
    final cfKampala = double.tryParse(_cfKampalaController.text) ?? 0.0;
    final ttUgx = (_selectedCifUSD! * 40) * exchangeRate; // TT calculation
    final numberPlate = double.tryParse(_numberPlateController.text) ?? 714300.0;
    final thirdPartyInsurance = double.tryParse(_thirdPartyInsuranceController.text) ?? 0.0;
    final agentFees = double.tryParse(_agentFeesController.text) ?? 400000.0;
    final registrationProcess = double.tryParse(_registrationProcessController.text) ?? 2667300.0;
    final registrationFee = double.tryParse(_registrationFeeController.text) ?? 1500000.0;
    final idf = double.tryParse(_idfController.text) ?? 0.0;
    final infrastructureLevy = double.tryParse(_infrastructureLevyController.text) ?? 0.0;
    final stampDuty = double.tryParse(_stampDutyController.text) ?? 18000.0;
    final regForm = double.tryParse(_regFormController.text) ?? 35000.0;
    
    return cifUgx + totalTax + cfMombasa + clearanceMsaToKla + cfKampala + ttUgx + 
           numberPlate + thirdPartyInsurance + agentFees + registrationProcess + 
           registrationFee + idf + infrastructureLevy + stampDuty + regForm;
  }
}