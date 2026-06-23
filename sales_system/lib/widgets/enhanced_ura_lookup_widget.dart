import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/enhanced_ura_lookup_service.dart';
import '../models/ura_vehicle.dart';
import 'glass_liquid_theme.dart';

class EnhancedUraLookupWidget extends StatefulWidget {
  final Function(String make, String model, int year, int engineCC, double cifUSD, String? serialNumber) onVehicleSelected;
  final Function(UraVehicleValidationResult validationResult)? onValidationResult;

  const EnhancedUraLookupWidget({
    Key? key,
    required this.onVehicleSelected,
    this.onValidationResult,
  }) : super(key: key);

  @override
  State<EnhancedUraLookupWidget> createState() => _EnhancedUraLookupWidgetState();
}

class _EnhancedUraLookupWidgetState extends State<EnhancedUraLookupWidget> {
  final _enhancedService = EnhancedUraLookupService();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _engineController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _cifController = TextEditingController();

  List<String> _availableMakes = [];
  List<String> _availableModels = [];
  List<UraVehicle> _searchResults = [];
  UraVehicleValidationResult? _validationResult;
  bool _isLoading = false;
  bool _showValidationDetails = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableMakes();
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _engineController.dispose();
    _serialNumberController.dispose();
    _cifController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableMakes() async {
    // Load available makes from database
    setState(() {
      _availableMakes = [
        'Toyota', 'Honda', 'Nissan', 'Mazda', 'Subaru', 'Mitsubishi', 'Suzuki',
        'BMW', 'Mercedes', 'Audi', 'Volkswagen', 'Ford', 'Chevrolet', 'Hyundai',
        'Kia', 'Isuzu', 'Hino', 'Volvo', 'Scania', 'MAN', 'Iveco', 'Land Rover',
        'Lexus', 'Porsche', 'Renault', 'Ssangyong', 'Jaguar', 'Jeep', 'Infiniti',
        'Caterpillar', 'Komatsu', 'JCB', 'DAF', 'Foden', 'ERF', 'Benford',
        'Cardillac', 'Chrysler', 'Dodge', 'Lamborghini', 'D&W', 'SDC', 'Super Doll',
        'Howo', 'Trail King', 'A35', 'Benford'
      ];
    });
  }

  Future<void> _validateVehicleData() async {
    if (_makeController.text.isEmpty || 
        _modelController.text.isEmpty || 
        _yearController.text.isEmpty || 
        _engineController.text.isEmpty || 
        _cifController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all vehicle details before validation'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _validationResult = null;
      _showValidationDetails = false;
    });

    try {
      final result = await _enhancedService.validateVehicleData(
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        year: int.tryParse(_yearController.text.trim()) ?? 2020,
        engineCC: int.tryParse(_engineController.text.trim()) ?? 0,
        cifUSD: double.tryParse(_cifController.text.trim()) ?? 0.0,
        serialNumber: _serialNumberController.text.trim().isNotEmpty 
            ? _serialNumberController.text.trim() 
            : null,
      );

      setState(() {
        _validationResult = result;
        _showValidationDetails = true;
        _isLoading = false;
      });

      if (widget.onValidationResult != null) {
        widget.onValidationResult!(result);
      }

      // Auto-select corrected data if validation suggests corrections
      if (result.correctedVehicle != null && result.confidence > 0.8) {
        _applyCorrections(result.correctedVehicle!);
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Validation error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _applyCorrections(UraVehicle correctedVehicle) {
    _makeController.text = correctedVehicle.make;
    _modelController.text = correctedVehicle.model;
    _yearController.text = correctedVehicle.year.toString();
    _engineController.text = correctedVehicle.engineCC.toString();
    _cifController.text = correctedVehicle.cifUsd.toStringAsFixed(2);
    if (correctedVehicle.serialNumber != null) {
      _serialNumberController.text = correctedVehicle.serialNumber!;
    }
  }

  Future<void> _searchBySerialNumber() async {
    final serialNumber = _serialNumberController.text.trim();
    if (serialNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a serial number to search'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final vehicle = await _enhancedService.findVehicleBySerialNumber(serialNumber);
      
      if (vehicle != null) {
        _applyCorrections(vehicle);
        
        setState(() {
          _isLoading = false;
        });

        widget.onVehicleSelected(
          vehicle.make,
          vehicle.model,
          vehicle.year,
          vehicle.engineCC,
          vehicle.cifUsd,
          vehicle.serialNumber,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vehicle found! S/N: ${vehicle.serialNumber}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No vehicle found with S/N: $serialNumber'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GlassLiquidTheme.accentBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, color: GlassLiquidTheme.accentBlue, size: 24),
              const SizedBox(width: 8),
              Text(
                'Enhanced URA Lookup with S/N Validation',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Serial Number Search Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: GlassLiquidTheme.accentBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: GlassLiquidTheme.accentBlue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🔍 Search by Serial Number (S/N)',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: GlassLiquidTheme.accentBlue,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _serialNumberController,
                        decoration: InputDecoration(
                          hintText: 'Enter S/N (e.g., 1.0, 2.0, 149)',
                          hintStyle: GoogleFonts.poppins(color: Colors.white70),
                          prefixIcon: Icon(Icons.tag, color: GlassLiquidTheme.accentBlue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: GlassLiquidTheme.accentBlue.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: GlassLiquidTheme.accentBlue.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: GlassLiquidTheme.accentBlue),
                          ),
                        ),
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _searchBySerialNumber,
                      icon: _isLoading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      label: Text(
                        'Find',
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
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Vehicle Details Section
          Text(
            'Vehicle Details',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _makeController,
                  decoration: InputDecoration(
                    labelText: 'Make',
                    prefixIcon: Icon(Icons.directions_car, color: GlassLiquidTheme.accentBlue),
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
                      borderSide: BorderSide(color: GlassLiquidTheme.accentBlue),
                    ),
                    labelStyle: GoogleFonts.poppins(color: Colors.white70),
                  ),
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _modelController,
                  decoration: InputDecoration(
                    labelText: 'Model',
                    prefixIcon: Icon(Icons.category, color: GlassLiquidTheme.accentBlue),
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
                      borderSide: BorderSide(color: GlassLiquidTheme.accentBlue),
                    ),
                    labelStyle: GoogleFonts.poppins(color: Colors.white70),
                  ),
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _yearController,
                  decoration: InputDecoration(
                    labelText: 'Year',
                    prefixIcon: Icon(Icons.calendar_today, color: GlassLiquidTheme.accentBlue),
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
                      borderSide: BorderSide(color: GlassLiquidTheme.accentBlue),
                    ),
                    labelStyle: GoogleFonts.poppins(color: Colors.white70),
                  ),
                  style: GoogleFonts.poppins(color: Colors.white),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _engineController,
                  decoration: InputDecoration(
                    labelText: 'Engine (CC)',
                    prefixIcon: Icon(Icons.settings, color: GlassLiquidTheme.accentBlue),
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
                      borderSide: BorderSide(color: GlassLiquidTheme.accentBlue),
                    ),
                    labelStyle: GoogleFonts.poppins(color: Colors.white70),
                  ),
                  style: GoogleFonts.poppins(color: Colors.white),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          TextField(
            controller: _cifController,
            decoration: InputDecoration(
              labelText: 'CIF Value (USD)',
              prefixIcon: Icon(Icons.attach_money, color: GlassLiquidTheme.accentBlue),
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
                borderSide: BorderSide(color: GlassLiquidTheme.accentBlue),
              ),
              labelStyle: GoogleFonts.poppins(color: Colors.white70),
            ),
            style: GoogleFonts.poppins(color: Colors.white),
            keyboardType: TextInputType.number,
          ),
          
          const SizedBox(height: 16),
          
          // Validation Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _validateVehicleData,
              icon: _isLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.verified),
              label: Text(
                'Validate Data with S/N',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          
          // Validation Results
          if (_validationResult != null) ...[
            const SizedBox(height: 16),
            _buildValidationResults(),
          ],
        ],
      ),
    );
  }

  Widget _buildValidationResults() {
    final result = _validationResult!;
    
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
      padding: const EdgeInsets.all(16),
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
              Icon(statusIcon, color: statusColor, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.getValidationMessage(),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                    fontSize: 14,
                  ),
                ),
              ),
              if (result.serialNumber != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: GlassLiquidTheme.accentBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'S/N: ${result.serialNumber}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: GlassLiquidTheme.accentBlue,
                    ),
                  ),
                ),
              ],
            ],
          ),
          
          if (result.issues.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Issues Found:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ...result.issues.map((issue) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      issue,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
          
          if (result.correctedVehicle != null) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _applyCorrections(result.correctedVehicle!),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Apply Suggested Corrections',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
          
          if (result.isValid && result.serialNumber != null) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                widget.onVehicleSelected(
                  _makeController.text.trim(),
                  _modelController.text.trim(),
                  int.tryParse(_yearController.text.trim()) ?? 2020,
                  int.tryParse(_engineController.text.trim()) ?? 0,
                  double.tryParse(_cifController.text.trim()) ?? 0.0,
                  result.serialNumber,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Use Validated Data',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

