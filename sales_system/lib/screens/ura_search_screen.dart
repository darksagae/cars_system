import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ura_lookup_service.dart';
import '../providers/theme_provider.dart';

class UraSearchScreen extends StatefulWidget {
  const UraSearchScreen({Key? key}) : super(key: key);

  @override
  State<UraSearchScreen> createState() => _UraSearchScreenState();
}

class _UraSearchScreenState extends State<UraSearchScreen> {
  final UraLookupService _uraService = UraLookupService();
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _engineController = TextEditingController();
  
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedVehicle;
  Map<String, dynamic>? _taxCalculation;
  bool _isLoading = false;
  Map<String, dynamic>? _databaseStats;

  @override
  void initState() {
    super.initState();
    _loadDatabaseStats();
  }

  Future<void> _loadDatabaseStats() async {
    final stats = await _uraService.getDatabaseStats();
    setState(() {
      _databaseStats = stats;
    });
  }

  Future<void> _searchVehicles() async {
    setState(() {
      _isLoading = true;
      _searchResults = [];
      _selectedVehicle = null;
      _taxCalculation = null;
    });

    try {
      final results = await _uraService.searchVehicles(
        make: _makeController.text.trim().isEmpty ? null : _makeController.text.trim(),
        model: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
        year: _yearController.text.trim().isEmpty ? null : int.tryParse(_yearController.text.trim()),
        engineCC: _engineController.text.trim().isEmpty ? null : int.tryParse(_engineController.text.trim()),
      );

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });

      if (results.isEmpty) {
        _showMessage('No vehicles found matching your search criteria.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage('Error searching vehicles: $e', isError: true);
    }
  }

  Future<void> _selectVehicle(Map<String, dynamic> vehicle) async {
    setState(() {
      _selectedVehicle = vehicle;
      _isLoading = true;
    });

    try {
      final exchangeRate = await _uraService.getCurrentExchangeRate();
      final taxCalc = await _uraService.calculateTax(
        cifUsd: vehicle['cif_usd'] as double,
        year: vehicle['year'] as int,
        engineCC: vehicle['engine_cc'] as int? ?? 0,
        exchangeRate: exchangeRate,
      );

      setState(() {
        _taxCalculation = taxCalc;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage('Error calculating tax: $e', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: Text(
          'URA Vehicle Lookup',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1A1F3A),
        elevation: 0,
      ),
      body: Row(
        children: [
          // Left Panel - Search Form
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsCard(),
                  const SizedBox(height: 24),
                  _buildSearchForm(),
                  const SizedBox(height: 24),
                  Expanded(child: _buildSearchResults()),
                ],
              ),
            ),
          ),
          
          // Right Panel - Selected Vehicle & Tax Calculation
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F3A),
                border: Border(
                  left: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              child: _selectedVehicle == null
                  ? _buildEmptyState()
                  : _buildVehicleDetails(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _seedSampleData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Note: UraDataSeeder functionality has been replaced by direct import scripts
      await _loadDatabaseStats();
      _showMessage('Database stats loaded successfully!');
    } catch (e) {
      _showMessage('Error seeding data: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildStatsCard() {
    if (_databaseStats == null) {
      return const SizedBox.shrink();
    }

    final hasData = _databaseStats!['total_vehicles'] > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF667EEA).withOpacity(0.1),
            const Color(0xFF764BA2).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Total Vehicles',
                _databaseStats!['total_vehicles'].toString(),
                Icons.directions_car,
              ),
              _buildStatItem(
                'Brands',
                _databaseStats!['unique_makes'].toString(),
                Icons.business,
              ),
              _buildStatItem(
                'Exchange Rate',
                'UGX ${_databaseStats!['current_exchange_rate'].toStringAsFixed(0)}',
                Icons.currency_exchange,
              ),
            ],
          ),
          if (!hasData) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white12),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _seedSampleData,
              icon: const Icon(Icons.download, size: 16),
              label: Text(
                'Load Sample Data',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF667EEA), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchForm() {
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
          Text(
            'Search Criteria',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(_makeController, 'Make', 'e.g., TOYOTA'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(_modelController, 'Model', 'e.g., LAND CRUISER'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(_yearController, 'Year', 'e.g., 2020', isNumber: true),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(_engineController, 'Engine CC', 'e.g., 4500', isNumber: true),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _searchVehicles,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(
                _isLoading ? 'Searching...' : 'Search',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.poppins(color: Colors.white70),
        hintStyle: GoogleFonts.poppins(color: Colors.white30, fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF0A0E21),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF667EEA)),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty && !_isLoading) {
      return Center(
        child: Text(
          'Enter search criteria and click Search',
          style: GoogleFonts.poppins(color: Colors.white54),
        ),
      );
    }

    if (_searchResults.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Results (${_searchResults.length})',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final vehicle = _searchResults[index];
                final isSelected = _selectedVehicle?['id'] == vehicle['id'];
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF667EEA).withOpacity(0.2)
                        : const Color(0xFF0A0E21),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF667EEA)
                          : Colors.white.withOpacity(0.05),
                    ),
                  ),
                  child: ListTile(
                    onTap: () => _selectVehicle(vehicle),
                    title: Text(
                      '${vehicle['make']} ${vehicle['model']} (${vehicle['year']})',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '${vehicle['engine_cc']} CC • CIF: \$${vehicle['cif_usd']}',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF667EEA),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Select a vehicle from the search results',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tax calculations will appear here',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleDetails() {
    if (_selectedVehicle == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVehicleInfoCard(),
          const SizedBox(height: 24),
          if (_taxCalculation != null) _buildTaxBreakdownCard(),
        ],
      ),
    );
  }

  Widget _buildVehicleInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF667EEA),
            const Color(0xFF764BA2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedVehicle!['make']} ${_selectedVehicle!['model']}',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Year: ${_selectedVehicle!['year']}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white30, height: 32),
          _buildInfoRow('Engine Size', '${_selectedVehicle!['engine_cc']} CC'),
          _buildInfoRow('HSC Code', _selectedVehicle!['hsc_code'] ?? 'N/A'),
          _buildInfoRow('Country of Origin', _selectedVehicle!['country_origin'] ?? 'N/A'),
          _buildInfoRow('CIF Value', '\$${_selectedVehicle!['cif_usd']}'),
          _buildInfoRow('Database Month', _selectedVehicle!['database_month']),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxBreakdownCard() {
    if (_taxCalculation == null) return const SizedBox.shrink();

    final breakdown = _taxCalculation!['breakdown'] as Map<String, dynamic>;
    final hasEnvLevy = _taxCalculation!['has_environmental_levy'] as bool;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E21),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tax Breakdown',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          if (hasEnvLevy)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This vehicle is ${_taxCalculation!['vehicle_age']} years old and subject to Environmental Levy (35%)',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          ...breakdown.entries.map((entry) {
            final amount = entry.value as double;
            if (amount == 0) return const SizedBox.shrink();
            
            return _buildTaxRow(entry.key, amount);
          }).toList(),
          const Divider(color: Colors.white30, height: 32),
          _buildTaxRow(
            'TOTAL TAX',
            _taxCalculation!['total_tax'],
            isTotal: true,
          ),
          const SizedBox(height: 16),
          Text(
            'Exchange Rate: UGX ${_taxCalculation!['exchange_rate'].toStringAsFixed(0)} per USD',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? const Color(0xFF667EEA) : Colors.white70,
            ),
          ),
          Text(
            'UGX ${amount.toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? const Color(0xFF667EEA) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _engineController.dispose();
    super.dispose();
  }
}


