import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ura_vehicle.dart';
import '../services/ura_lookup_service.dart';
import 'glass_liquid_theme.dart';

class MagicLookupWizard extends StatefulWidget {
  final Function(String make, String model, int year, int engineCC, double cifUSD, String? serialNumber) onVehicleSelected;

  const MagicLookupWizard({
    Key? key,
    required this.onVehicleSelected,
  }) : super(key: key);

  @override
  State<MagicLookupWizard> createState() => _MagicLookupWizardState();
}

class _MagicLookupWizardState extends State<MagicLookupWizard> {
  final UraLookupService _uraService = UraLookupService();
  final TextEditingController _searchController = TextEditingController();
  
  List<UraVehicle> _searchResults = [];
  List<String> _availableMakes = [];
  List<String> _availableModels = [];
  List<int> _availableYears = [];
  List<int> _availableEngineSizes = [];
  
  bool _isLoading = false;
  bool _cascadingMode = true; // New: Toggle between cascading and magic search
  String? _selectedMake;
  String? _selectedModel;
  int? _selectedYear;
  int? _selectedEngineSize;
  UraVehicle? _finalVehicle;
  double? _minPrice;
  double? _maxPrice;
  String? _selectedCountry;

  @override
  void initState() {
    super.initState();
    _loadAvailableOptions();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableOptions() async {
    try {
      // Get available makes
      final makes = await _uraService.getAllMakes();
      final models = await _uraService.getAllModels();
      final years = await _uraService.getAllYears();
      
      setState(() {
        _availableMakes = makes;
        _availableModels = models;
        _availableYears = years;
      });
    } catch (e) {
      print('Error loading available options: $e');
    }
  }

  // Cascading search methods
  Future<void> _onMakeSelected(String make) async {
    setState(() {
      _selectedMake = make;
      _selectedModel = null;
      _selectedYear = null;
      _selectedEngineSize = null;
      _finalVehicle = null;
      _availableModels = [];
      _availableYears = [];
      _availableEngineSizes = [];
    });

    try {
      final models = await _uraService.getModelsForMake(make);
      setState(() {
        _availableModels = models;
      });
    } catch (e) {
      print('Error loading models: $e');
    }
  }

  Future<void> _onModelSelected(String model) async {
    setState(() {
      _selectedModel = model;
      _selectedYear = null;
      _selectedEngineSize = null;
      _finalVehicle = null;
      _availableYears = [];
      _availableEngineSizes = [];
    });

    try {
      final years = await _uraService.getYearsForModel(_selectedMake!, model);
      setState(() {
        _availableYears = years;
      });
    } catch (e) {
      print('Error loading years: $e');
    }
  }

  Future<void> _onYearSelected(int year) async {
    setState(() {
      _selectedYear = year;
      _selectedEngineSize = null;
      _finalVehicle = null;
      _availableEngineSizes = [];
    });

    try {
      final engineSizes = await _uraService.getEngineSizesForModel(
        _selectedMake!, 
        _selectedModel!, 
        year
      );
      setState(() {
        _availableEngineSizes = engineSizes;
      });
    } catch (e) {
      print('Error loading engine sizes: $e');
    }
  }

  Future<void> _onEngineSizeSelected(int engineSize) async {
    setState(() {
      _selectedEngineSize = engineSize;
    });

    try {
      final vehicles = await _uraService.searchVehiclesAsObjects(
        make: _selectedMake,
        model: _selectedModel,
        year: _selectedYear,
        engineCC: engineSize,
      );

      if (vehicles.isNotEmpty) {
        final vehicle = vehicles.first; // Take the first match
        setState(() {
          _finalVehicle = vehicle;
        });

        // Auto-fill the vehicle details
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
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✅ Vehicle Auto-Filled Successfully!',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${vehicle.make} ${vehicle.model} (${vehicle.year})',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'CIF: \$${vehicle.cifUsd.toStringAsFixed(2)}${vehicle.serialNumber != null ? ' | S/N: ${vehicle.serialNumber}' : ''}',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error loading final vehicle: $e');
    }
  }

  void _resetCascadingSearch() {
    setState(() {
      _selectedMake = null;
      _selectedModel = null;
      _selectedYear = null;
      _selectedEngineSize = null;
      _finalVehicle = null;
      _availableModels = [];
      _availableYears = [];
      _availableEngineSizes = [];
      _searchController.clear();
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty && query.length >= 2) {
      _performSearch();
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  Future<void> _performSearch() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final query = _searchController.text.trim();
      
      // Perform intelligent search
      List<UraVehicle> results;
      
      if (_selectedMake != null || _selectedModel != null || _selectedYear != null) {
        // Filtered search
        results = await _uraService.searchVehiclesAsObjects(
          make: _selectedMake,
          model: _selectedModel,
          year: _selectedYear,
        );
        
        // Filter by search query
        if (query.isNotEmpty) {
          results = results.where((vehicle) {
            return vehicle.description.toLowerCase().contains(query.toLowerCase()) ||
                   vehicle.make.toLowerCase().contains(query.toLowerCase()) ||
                   vehicle.model.toLowerCase().contains(query.toLowerCase()) ||
                   (vehicle.serialNumber != null && vehicle.serialNumber!.contains(query));
          }).toList();
        }
      } else {
        // Global search
        results = await _uraService.searchVehiclesAsObjects(
          make: query,
        );
        
        // Also search in descriptions
        final descriptionResults = await _uraService.searchVehiclesAsObjects(
          make: null,
        );
        
        final filteredResults = descriptionResults.where((vehicle) {
          return vehicle.description.toLowerCase().contains(query.toLowerCase()) ||
                 (vehicle.serialNumber != null && vehicle.serialNumber!.contains(query));
        }).toList();
        
        // Combine and deduplicate
        final combinedResults = [...results, ...filteredResults];
        results = combinedResults.toSet().toList();
      }
      
      // Apply price filter
      if (_minPrice != null || _maxPrice != null) {
        results = results.where((vehicle) {
          if (_minPrice != null && vehicle.cifUsd < _minPrice!) return false;
          if (_maxPrice != null && vehicle.cifUsd > _maxPrice!) return false;
          return true;
        }).toList();
      }
      
      // Apply country filter
      if (_selectedCountry != null) {
        results = results.where((vehicle) {
          return vehicle.countryOrigin.toLowerCase().contains(_selectedCountry!.toLowerCase());
        }).toList();
      }
      
      // Sort by relevance
      results.sort((a, b) {
        // Prioritize exact matches
        final aExact = a.make.toLowerCase() == query.toLowerCase();
        final bExact = b.make.toLowerCase() == query.toLowerCase();
        if (aExact && !bExact) return -1;
        if (!aExact && bExact) return 1;
        
        // Then by CIF value (descending)
        return b.cifUsd.compareTo(a.cifUsd);
      });
      
      setState(() {
        _searchResults = results.take(50).toList(); // Limit to 50 results
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Search error: $e');
    }
  }

  void _clearFilters() {
    if (_cascadingMode) {
      _resetCascadingSearch();
    } else {
      setState(() {
        _selectedMake = null;
        _selectedModel = null;
        _selectedYear = null;
        _minPrice = null;
        _maxPrice = null;
        _selectedCountry = null;
        _searchController.clear();
        _searchResults = [];
      });
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
          // Header
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              Text(
                _cascadingMode ? 'Cascading Search' : 'Magic Lookup Wizard',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              // Mode toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _cascadingMode = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _cascadingMode ? GlassLiquidTheme.accentBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Cascading',
                          style: GoogleFonts.poppins(
                            color: _cascadingMode ? Colors.white : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _cascadingMode = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: !_cascadingMode ? GlassLiquidTheme.accentBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Magic',
                          style: GoogleFonts.poppins(
                            color: !_cascadingMode ? Colors.white : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all, color: Colors.orange),
                tooltip: 'Clear all filters',
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Content based on mode
          if (_cascadingMode) ...[
            // Cascading Search Interface
            _buildCascadingInterface(),
          ] else ...[
            // Magic Search Interface
            _buildSearchBar(),
            
            const SizedBox(height: 16),
            
            _buildFilters(),
            
            const SizedBox(height: 16),
            
            _buildResults(),
          ],
        ],
      ),
    );
  }

  Widget _buildCascadingInterface() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          _buildProgressIndicator(),
          
          const SizedBox(height: 20),
          
          // Step 1: Make Selection
          _buildMakeSelection(),
          
          if (_selectedMake != null) ...[
            const SizedBox(height: 16),
            _buildModelSelection(),
          ],
          
          if (_selectedModel != null) ...[
            const SizedBox(height: 16),
            _buildYearSelection(),
          ],
          
          if (_selectedYear != null) ...[
            const SizedBox(height: 16),
            _buildEngineSizeSelection(),
          ],
          
          if (_finalVehicle != null) ...[
            const SizedBox(height: 16),
            _buildFinalVehicleDisplay(),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final currentStep = _getCurrentStep();
    return Column(
      children: [
        Row(
          children: [
            _buildProgressStep('Make', 1, currentStep >= 1),
            Expanded(child: _buildProgressLine(currentStep > 1)),
            _buildProgressStep('Model', 2, currentStep >= 2),
            Expanded(child: _buildProgressLine(currentStep > 2)),
            _buildProgressStep('Year', 3, currentStep >= 3),
            Expanded(child: _buildProgressLine(currentStep > 3)),
            _buildProgressStep('Engine', 4, currentStep >= 4),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _getStepDescription(),
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressStep(String label, int step, bool isActive) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? GlassLiquidTheme.accentBlue : Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? GlassLiquidTheme.accentBlue : Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          step.toString(),
          style: GoogleFonts.poppins(
            color: isActive ? Colors.white : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Container(
      height: 2,
      color: isActive ? GlassLiquidTheme.accentBlue : Colors.white.withOpacity(0.2),
    );
  }

  int _getCurrentStep() {
    if (_finalVehicle != null) return 5;
    if (_selectedEngineSize != null) return 4;
    if (_selectedYear != null) return 3;
    if (_selectedModel != null) return 2;
    if (_selectedMake != null) return 1;
    return 0;
  }

  String _getStepDescription() {
    if (_finalVehicle != null) return 'Vehicle selected and auto-filled!';
    if (_selectedEngineSize != null) return 'Selecting final vehicle...';
    if (_selectedYear != null) return 'Select engine size to narrow down';
    if (_selectedModel != null) return 'Select year to continue';
    if (_selectedMake != null) return 'Select model to continue';
    return 'Start by typing and selecting a vehicle make';
  }

  Widget _buildMakeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1. Select Make',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        _buildSearchableDropdown(
          hintText: 'Type make (e.g., "a" for Audi, A35...)',
          items: _availableMakes,
          selectedItem: _selectedMake,
          onChanged: _onMakeSelected,
        ),
      ],
    );
  }

  Widget _buildModelSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '2. Select Model',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedModel,
            hint: Text(
              _availableModels.isEmpty 
                ? 'No models available for $_selectedMake'
                : 'Select model for $_selectedMake',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            dropdownColor: const Color(0xFF2A2A3E),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: _availableModels.map((model) {
              return DropdownMenuItem<String>(
                value: model,
                child: Text(
                  model,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
            onChanged: _availableModels.isEmpty ? null : (model) {
              if (model != null) {
                _onModelSelected(model);
              }
            },
          ),
        ),
        if (_availableModels.isEmpty && _selectedMake != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'No models found for $_selectedMake in the database',
              style: GoogleFonts.poppins(
                color: Colors.orange,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildYearSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '3. Select Year',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: DropdownButtonFormField<int>(
            value: _selectedYear,
            hint: Text(
              _availableYears.isEmpty 
                ? 'No years available for $_selectedMake $_selectedModel'
                : 'Select year for $_selectedMake $_selectedModel',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            dropdownColor: const Color(0xFF2A2A3E),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: _availableYears.map((year) {
              return DropdownMenuItem<int>(
                value: year,
                child: Text(
                  year.toString(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
            onChanged: _availableYears.isEmpty ? null : (year) {
              if (year != null) {
                _onYearSelected(year);
              }
            },
          ),
        ),
        if (_availableYears.isEmpty && _selectedMake != null && _selectedModel != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'No years found for $_selectedMake $_selectedModel in the database',
              style: GoogleFonts.poppins(
                color: Colors.orange,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEngineSizeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '4. Select Engine Size',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: DropdownButtonFormField<int>(
            value: _selectedEngineSize,
            hint: Text(
              _availableEngineSizes.isEmpty 
                ? 'No engine sizes available for $_selectedMake $_selectedModel ($_selectedYear)'
                : 'Select engine size for $_selectedMake $_selectedModel ($_selectedYear)',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            dropdownColor: const Color(0xFF2A2A3E),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: _availableEngineSizes.map((engineSize) {
              return DropdownMenuItem<int>(
                value: engineSize,
                child: Text(
                  '${engineSize}cc',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
            onChanged: _availableEngineSizes.isEmpty ? null : (engineSize) {
              if (engineSize != null) {
                _onEngineSizeSelected(engineSize);
              }
            },
          ),
        ),
        if (_availableEngineSizes.isEmpty && _selectedMake != null && _selectedModel != null && _selectedYear != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'No engine sizes found for $_selectedMake $_selectedModel ($_selectedYear) in the database',
              style: GoogleFonts.poppins(
                color: Colors.orange,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFinalVehicleDisplay() {
    if (_finalVehicle == null) return const SizedBox.shrink();

    final vehicle = _finalVehicle!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            GlassLiquidTheme.accentBlue.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Vehicle Selected & Auto-Filled',
                  style: GoogleFonts.poppins(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Ready to Use',
                  style: GoogleFonts.poppins(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildVehicleInfoRow('Make', vehicle.make),
          _buildVehicleInfoRow('Model', vehicle.model),
          _buildVehicleInfoRow('Year', vehicle.year.toString()),
          _buildVehicleInfoRow('Engine', '${vehicle.engineCC}cc'),
          _buildVehicleInfoRow('Country', vehicle.countryOrigin),
          _buildVehicleInfoRow('HSC Code', vehicle.hscCode),
          _buildVehicleInfoRow('CIF', '\$${vehicle.cifUsd.toStringAsFixed(2)}'),
          if (vehicle.serialNumber != null && vehicle.serialNumber!.isNotEmpty)
            _buildVehicleInfoRow('S/N', vehicle.serialNumber!),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'All fields have been automatically populated in the invoice form.',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchableDropdown({
    required String hintText,
    required List<String> items,
    String? selectedItem,
    required Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GlassLiquidTheme.accentBlue.withOpacity(0.3)),
      ),
      child: DropdownButtonFormField<String>(
        value: selectedItem,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(color: Colors.white70),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        style: GoogleFonts.poppins(color: Colors.white),
        dropdownColor: const Color(0xFF2D2D44),
        items: items.map((item) => DropdownMenuItem<String>(
          value: item,
          child: Text(item, style: GoogleFonts.poppins(color: Colors.white)),
        )).toList(),
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GlassLiquidTheme.accentBlue.withOpacity(0.3)),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.poppins(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search by make, model, description, or S/N...',
          hintStyle: GoogleFonts.poppins(color: Colors.white70),
          prefixIcon: Icon(Icons.search, color: GlassLiquidTheme.accentBlue),
          suffixIcon: _isLoading 
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                        });
                      },
                    )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      children: [
        // Filter Row 1
        Row(
          children: [
            Expanded(
              child: _buildDropdownFilter(
                'Make',
                _selectedMake,
                _availableMakes,
                (value) => setState(() {
                  _selectedMake = value;
                  _selectedModel = null; // Reset model when make changes
                  _performSearch();
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDropdownFilter(
                'Model',
                _selectedModel,
                _availableModels,
                (value) => setState(() {
                  _selectedModel = value;
                  _performSearch();
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDropdownFilter(
                'Year',
                _selectedYear?.toString(),
                _availableYears.map((y) => y.toString()).toList(),
                (value) => setState(() {
                  _selectedYear = value != null ? int.tryParse(value) : null;
                  _performSearch();
                }),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Filter Row 2
        Row(
          children: [
            Expanded(
              child: _buildPriceFilter('Min Price', _minPrice, (value) {
                setState(() {
                  _minPrice = value;
                  _performSearch();
                });
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPriceFilter('Max Price', _maxPrice, (value) {
                setState(() {
                  _maxPrice = value;
                  _performSearch();
                });
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownFilter(
    String label,
    String? value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GlassLiquidTheme.accentBlue.withOpacity(0.3)),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.white70),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        style: GoogleFonts.poppins(color: Colors.white),
        dropdownColor: const Color(0xFF2D2D44),
        items: [
          DropdownMenuItem<String>(
            value: null,
            child: Text('All', style: GoogleFonts.poppins(color: Colors.white70)),
          ),
          ...options.map((option) => DropdownMenuItem<String>(
            value: option,
            child: Text(option, style: GoogleFonts.poppins(color: Colors.white)),
          )),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildPriceFilter(String label, double? value, Function(double?) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GlassLiquidTheme.accentBlue.withOpacity(0.3)),
      ),
      child: TextField(
        keyboardType: TextInputType.number,
        style: GoogleFonts.poppins(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.white70),
          hintText: '\$0.00',
          hintStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.5)),
          prefixText: '\$',
          prefixStyle: GoogleFonts.poppins(color: Colors.white),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        onChanged: (text) {
          final price = double.tryParse(text);
          onChanged(price);
        },
      ),
    );
  }

  Widget _buildResults() {
    if (_searchResults.isEmpty && !_isLoading) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 16),
              Text(
                'Start typing to search vehicles...',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 400,
      child: ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final vehicle = _searchResults[index];
          return _buildVehicleCard(vehicle);
        },
      ),
    );
  }

  Widget _buildVehicleCard(UraVehicle vehicle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GlassLiquidTheme.accentBlue.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: GlassLiquidTheme.accentBlue.withOpacity(0.2),
          child: Text(
            vehicle.make.isNotEmpty ? vehicle.make[0].toUpperCase() : '?',
            style: GoogleFonts.poppins(
              color: GlassLiquidTheme.accentBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          '${vehicle.make} ${vehicle.model} (${vehicle.year})',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vehicle.description,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (vehicle.serialNumber != null && vehicle.serialNumber!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'S/N: ${vehicle.serialNumber}',
                      style: GoogleFonts.poppins(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'CIF: \$${vehicle.cifUsd.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      color: Colors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: GlassLiquidTheme.accentBlue.withOpacity(0.7),
          size: 16,
        ),
        onTap: () {
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
              content: Text('✅ ${vehicle.make} ${vehicle.model} selected'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }
}
