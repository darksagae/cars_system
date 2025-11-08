import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/ura_lookup_service.dart';
import '../models/ura_vehicle.dart';
import 'glass_liquid_theme.dart';

class UraLookupWidget extends StatefulWidget {
  final Function(String make, String model, int year, int engineCC, double cifUSD, String? serialNumber) onVehicleSelected;
  final String? initialMake;
  final String? initialModel;
  final int? initialYear;
  final int? initialEngineCC;
  final double? initialCifUSD;

  const UraLookupWidget({
    Key? key,
    required this.onVehicleSelected,
    this.initialMake,
    this.initialModel,
    this.initialYear,
    this.initialEngineCC,
    this.initialCifUSD,
  }) : super(key: key);

  @override
  State<UraLookupWidget> createState() => _UraLookupWidgetState();
}

class _UraLookupWidgetState extends State<UraLookupWidget> {
  final UraLookupService _uraService = UraLookupService();
  
  // Controllers for search/filter
  final TextEditingController _makeSearchController = TextEditingController();
  final TextEditingController _modelSearchController = TextEditingController();
  
  // State variables
  List<String> _availableMakes = [];
  List<String> _availableModels = [];
  List<int> _availableYears = [];
  List<int> _availableEngineSizes = [];
  
  String? _selectedMake;
  String? _selectedModel;
  int? _selectedYear;
  int? _selectedEngineSize;
  double? _selectedCifUSD;
  
  bool _isLoading = false;
  bool _showMakeDropdown = false;
  bool _showModelDropdown = false;
  bool _showYearDropdown = false;
  bool _showEngineDropdown = false;

  @override
  void initState() {
    super.initState();
    _initializeFromExisting();
    _loadAvailableMakes();
  }

  void _initializeFromExisting() {
    if (widget.initialMake != null) {
      _selectedMake = widget.initialMake;
      _makeSearchController.text = widget.initialMake!;
    }
    if (widget.initialModel != null) {
      _selectedModel = widget.initialModel;
      _modelSearchController.text = widget.initialModel!;
    }
    if (widget.initialYear != null) {
      _selectedYear = widget.initialYear;
    }
    if (widget.initialEngineCC != null) {
      _selectedEngineSize = widget.initialEngineCC;
    }
    if (widget.initialCifUSD != null) {
      _selectedCifUSD = widget.initialCifUSD;
    }
  }

  @override
  void dispose() {
    _makeSearchController.dispose();
    _modelSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableMakes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final makes = await _uraService.getAvailableMakes();
      setState(() {
        _availableMakes = makes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading makes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadModelsForMake(String make) async {
    setState(() {
      _isLoading = true;
      _availableModels.clear();
      _availableYears.clear();
      _availableEngineSizes.clear();
      _selectedModel = null;
      _selectedYear = null;
      _selectedEngineSize = null;
      _selectedCifUSD = null;
      _modelSearchController.clear();
    });

    try {
      final models = await _uraService.getModelsForMake(make);
      setState(() {
        _availableModels = models;
        _isLoading = false;
        _showModelDropdown = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading models: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadYearsForModel(String make, String model) async {
    setState(() {
      _isLoading = true;
      _availableYears.clear();
      _availableEngineSizes.clear();
      _selectedYear = null;
      _selectedEngineSize = null;
      _selectedCifUSD = null;
    });

    try {
      final years = await _uraService.getYearsForModel(make, model);
      setState(() {
        _availableYears = years;
        _isLoading = false;
        _showYearDropdown = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading years: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadEngineSizesForModel(String make, String model, int year) async {
    setState(() {
      _isLoading = true;
      _availableEngineSizes.clear();
      _selectedEngineSize = null;
      _selectedCifUSD = null;
    });

    try {
      final engineSizes = await _uraService.getEngineSizesForModel(make, model, year);
      setState(() {
        _availableEngineSizes = engineSizes;
        _isLoading = false;
        _showEngineDropdown = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading engine sizes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadCifValue(String make, String model, int year, int engineSize) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final vehicles = await _uraService.searchVehiclesAsObjects(
        make: make,
        model: model,
        year: year,
        engineCC: engineSize,
      );

      if (vehicles.isNotEmpty) {
        final vehicle = vehicles.first;
        setState(() {
          _selectedCifUSD = vehicle.cifUsd;
          _isLoading = false;
        });
        
        // Notify parent widget (including S/N)
        widget.onVehicleSelected(make, model, year, engineSize, vehicle.cifUsd, vehicle.serialNumber);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('CIF Value: \$${vehicle.cifUsd.toStringAsFixed(2)} USD'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No CIF value found for this vehicle'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading CIF value: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<String> _getFilteredMakes() {
    if (_makeSearchController.text.isEmpty) {
      return _availableMakes;
    }
    return _availableMakes
        .where((make) => make.toLowerCase().contains(_makeSearchController.text.toLowerCase()))
        .toList();
  }

  List<String> _getFilteredModels() {
    if (_modelSearchController.text.isEmpty) {
      return _availableModels;
    }
    return _availableModels
        .where((model) => model.toLowerCase().contains(_modelSearchController.text.toLowerCase()))
        .toList();
  }

  void _resetFromMake() {
    setState(() {
      _selectedMake = null;
      _selectedModel = null;
      _selectedYear = null;
      _selectedEngineSize = null;
      _selectedCifUSD = null;
      _availableModels.clear();
      _availableYears.clear();
      _availableEngineSizes.clear();
      _modelSearchController.clear();
      _showModelDropdown = false;
      _showYearDropdown = false;
      _showEngineDropdown = false;
    });
  }

  void _resetFromModel() {
    setState(() {
      _selectedModel = null;
      _selectedYear = null;
      _selectedEngineSize = null;
      _selectedCifUSD = null;
      _availableYears.clear();
      _availableEngineSizes.clear();
      _showYearDropdown = false;
      _showEngineDropdown = false;
    });
  }

  void _resetFromYear() {
    setState(() {
      _selectedYear = null;
      _selectedEngineSize = null;
      _selectedCifUSD = null;
      _availableEngineSizes.clear();
      _showEngineDropdown = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.database,
                color: GlassLiquidTheme.accentBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'URA Database Lookup',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (_selectedCifUSD != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'CIF: \$${_selectedCifUSD!.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Make Selection
          _buildMakeSelector(),
          const SizedBox(height: 12),

          // Model Selection (only if make is selected)
          if (_selectedMake != null) _buildModelSelector(),
          if (_selectedMake != null) const SizedBox(height: 12),

          // Year Selection (only if model is selected)
          if (_selectedModel != null) _buildYearSelector(),
          if (_selectedModel != null) const SizedBox(height: 12),

          // Engine Size Selection (only if year is selected)
          if (_selectedYear != null) _buildEngineSizeSelector(),
          if (_selectedYear != null) const SizedBox(height: 12),

          // Loading indicator
          if (_isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(GlassLiquidTheme.accentBlue),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMakeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicle Make',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _makeSearchController,
          onChanged: (value) {
            setState(() {
              _showMakeDropdown = value.isNotEmpty;
            });
          },
          onTap: () {
            setState(() {
              _showMakeDropdown = true;
            });
          },
          style: GoogleFonts.poppins(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Type to search makes...',
            hintStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.6)),
            prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
            suffixIcon: _selectedMake != null
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.7)),
                    onPressed: _resetFromMake,
                  )
                : null,
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
          ),
        ),
        if (_showMakeDropdown && _getFilteredMakes().isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _getFilteredMakes().length,
              itemBuilder: (context, index) {
                final make = _getFilteredMakes()[index];
                return ListTile(
                  title: Text(
                    make,
                    style: GoogleFonts.poppins(color: Colors.black87),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedMake = make;
                      _makeSearchController.text = make;
                      _showMakeDropdown = false;
                    });
                    _loadModelsForMake(make);
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildModelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicle Model',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _modelSearchController,
          onChanged: (value) {
            setState(() {
              _showModelDropdown = value.isNotEmpty;
            });
          },
          onTap: () {
            setState(() {
              _showModelDropdown = true;
            });
          },
          style: GoogleFonts.poppins(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Type to search models...',
            hintStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.6)),
            prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
            suffixIcon: _selectedModel != null
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.7)),
                    onPressed: _resetFromModel,
                  )
                : null,
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
          ),
        ),
        if (_showModelDropdown && _getFilteredModels().isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _getFilteredModels().length,
              itemBuilder: (context, index) {
                final model = _getFilteredModels()[index];
                return ListTile(
                  title: Text(
                    model,
                    style: GoogleFonts.poppins(color: Colors.black87),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedModel = model;
                      _modelSearchController.text = model;
                      _showModelDropdown = false;
                    });
                    _loadYearsForModel(_selectedMake!, model);
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildYearSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicle Year',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedYear,
          onChanged: (year) {
            setState(() {
              _selectedYear = year;
            });
            _loadEngineSizesForModel(_selectedMake!, _selectedModel!, year!);
          },
          style: GoogleFonts.poppins(color: Colors.white),
          dropdownColor: Colors.grey[800],
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
              borderSide: BorderSide(color: GlassLiquidTheme.accentBlue),
            ),
          ),
          items: _availableYears.map((year) {
            return DropdownMenuItem<int>(
              value: year,
              child: Text(
                year.toString(),
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEngineSizeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Engine Size (CC)',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedEngineSize,
          onChanged: (engineSize) {
            setState(() {
              _selectedEngineSize = engineSize;
            });
            _loadCifValue(_selectedMake!, _selectedModel!, _selectedYear!, engineSize!);
          },
          style: GoogleFonts.poppins(color: Colors.white),
          dropdownColor: Colors.grey[800],
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
              borderSide: BorderSide(color: GlassLiquidTheme.accentBlue),
            ),
          ),
          items: _availableEngineSizes.map((engineSize) {
            return DropdownMenuItem<int>(
              value: engineSize,
              child: Text(
                '${engineSize} CC',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

