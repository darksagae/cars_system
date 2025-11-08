import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import '../models/ura_vehicle.dart';
import 'glass_liquid_theme.dart';

class SimplePdfSearch extends StatefulWidget {
  final Function(UraVehicle) onVehicleSelected;

  const SimplePdfSearch({
    Key? key,
    required this.onVehicleSelected,
  }) : super(key: key);

  @override
  State<SimplePdfSearch> createState() => _SimplePdfSearchState();
}

class _SimplePdfSearchState extends State<SimplePdfSearch> {
  String? _selectedPdfPath;
  String _searchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String _statusMessage = 'Select a PDF file to search';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Simple PDF Search',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_selectedPdfPath != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Text(
                      'PDF Loaded',
                      style: GoogleFonts.poppins(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // PDF Selection
            _buildPdfSelection(),
            
            const SizedBox(height: 20),
            
            // Search Interface
            if (_selectedPdfPath != null) _buildSearchInterface(),
            
            const SizedBox(height: 20),
            
            // Status Message
            _buildStatusMessage(),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1. Select PDF File',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Text(
                  _selectedPdfPath != null 
                    ? _selectedPdfPath!.split('/').last
                    : 'No PDF selected',
                  style: GoogleFonts.poppins(
                    color: _selectedPdfPath != null ? Colors.white : Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _selectPdfFile,
              icon: const Icon(Icons.folder_open, size: 16),
              label: Text(
                'Select PDF',
                style: GoogleFonts.poppins(fontSize: 12),
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
    );
  }

  Widget _buildSearchInterface() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '2. Search for Vehicle',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  if (value.length >= 2) {
                    _searchInPdf();
                  } else {
                    setState(() {
                      _searchResults = [];
                    });
                  }
                },
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Type vehicle name (e.g., RAV4, Toyota, BMW)',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: GlassLiquidTheme.accentBlue),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (_isSearching)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(GlassLiquidTheme.accentBlue),
                ),
              ),
          ],
        ),
        
        // Search Results
        if (_searchResults.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSearchResults(),
        ],
      ],
    );
  }

  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Results (${_searchResults.length})',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final result = _searchResults[index];
              return _buildResultItem(result);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultItem(Map<String, dynamic> result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () => _selectVehicle(result),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    result['description'] ?? 'Unknown Vehicle',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: GlassLiquidTheme.accentBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'S/N: ${result['serial_number'] ?? 'N/A'}',
                    style: GoogleFonts.poppins(
                      color: GlassLiquidTheme.accentBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip('CIF: \$${result['cif_value'] ?? 'N/A'}', Colors.green),
                const SizedBox(width: 8),
                _buildInfoChip('Year: ${result['year'] ?? 'N/A'}', Colors.orange),
                const SizedBox(width: 8),
                _buildInfoChip('Engine: ${result['engine_size'] ?? 'N/A'}', Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatusMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getStatusColor().withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(),
            color: _getStatusColor(),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _statusMessage,
              style: GoogleFonts.poppins(
                color: _getStatusColor(),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (_isSearching) return GlassLiquidTheme.accentBlue;
    if (_searchResults.isNotEmpty) return Colors.green;
    if (_selectedPdfPath != null) return Colors.orange;
    return Colors.grey;
  }

  IconData _getStatusIcon() {
    if (_isSearching) return Icons.search;
    if (_searchResults.isNotEmpty) return Icons.check_circle;
    if (_selectedPdfPath != null) return Icons.info;
    return Icons.help_outline;
  }

  Future<void> _selectPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        dialogTitle: 'Select URA Database PDF',
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedPdfPath = result.files.single.path!;
          _statusMessage = 'PDF loaded successfully';
          _searchResults = [];
          _searchQuery = '';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error selecting PDF: $e';
      });
    }
  }

  Future<void> _searchInPdf() async {
    if (_selectedPdfPath == null || _searchQuery.length < 2) return;

    setState(() {
      _isSearching = true;
      _statusMessage = 'Searching in PDF...';
    });

    try {
      // Read PDF file
      final file = File(_selectedPdfPath!);
      final pdfBytes = await file.readAsBytes();
      
      // Extract text from PDF
      final textContent = await _extractTextFromPdf(pdfBytes);
      
      // Search for matching lines
      final results = _searchInText(textContent, _searchQuery);
      
      setState(() {
        _searchResults = results;
        _isSearching = false;
        _statusMessage = 'Found ${results.length} results for "$_searchQuery"';
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _statusMessage = 'Search error: $e';
        _searchResults = [];
      });
    }
  }

  Future<String> _extractTextFromPdf(Uint8List pdfBytes) async {
    try {
      // Use system pdftotext command for proper PDF text extraction
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/temp_pdf.pdf');
      final outputFile = File('${tempDir.path}/temp_output.txt');
      
      // Write PDF bytes to temporary file
      await tempFile.writeAsBytes(pdfBytes);
      
      // Use pdftotext to extract text with layout preservation
      final result = await Process.run('pdftotext', [
        '-layout',
        tempFile.path,
        outputFile.path,
      ]);
      
      if (result.exitCode == 0 && await outputFile.exists()) {
        final extractedText = await outputFile.readAsString();
        
        // Clean up temporary files
        await tempFile.delete();
        await outputFile.delete();
        
        return extractedText;
      } else {
        throw Exception('pdftotext failed');
      }
    } catch (e) {
      throw Exception('PDF text extraction failed: $e');
    }
  }

  List<Map<String, dynamic>> _searchInText(String text, String query) {
    final lines = text.split('\n');
    final results = <Map<String, dynamic>>[];
    final queryLower = query.toLowerCase();
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      // Look for lines that contain the search query and look like vehicle data
      if (line.toLowerCase().contains(queryLower) && 
          _isVehicleDataLine(line)) {
        
        final vehicleData = _parseVehicleLine(line, i + 1);
        if (vehicleData != null) {
          results.add(vehicleData);
        }
      }
    }
    
    return results;
  }

  bool _isVehicleDataLine(String line) {
    // Check if line looks like vehicle data (contains S/N pattern and CIF value)
    return RegExp(r'^\s*\d+\s+[\d.]+\s+[A-Z]{2}\s+').hasMatch(line) ||
           line.contains('cc') ||
           line.contains('CIF') ||
           RegExp(r'\$\d+').hasMatch(line);
  }

  Map<String, dynamic>? _parseVehicleLine(String line, int lineNumber) {
    try {
      // Parse the fixed-width format: S/N, HSC CODE, COO, Description, CC, CIF (USD)
      final regex = RegExp(r'^\s*(\d+)\s+([\d.]+)\s+([A-Z]{2})\s+(.+?)\s+(\d+(?:\.\d+)?\s*(?:cc|Ton|bhp|Hp|Axle))\s+([\d,]+\.?\d*)\s*$');
      final match = regex.firstMatch(line.trim());
      
      if (match != null) {
        final serialNumber = match.group(1)?.trim();
        final hscCode = match.group(2)?.trim();
        final countryOrigin = match.group(3)?.trim();
        final description = match.group(4)?.trim();
        final engineSize = match.group(5)?.trim();
        final cifValue = match.group(6)?.trim();
        
        // Extract year from description
        final yearRegex = RegExp(r'\b(19[9]\d|20[0-2]\d)\b');
        final yearMatch = yearRegex.firstMatch(description ?? '');
        final year = yearMatch?.group(1);
        
        return {
          'serial_number': serialNumber,
          'hsc_code': hscCode,
          'country_origin': countryOrigin,
          'description': description,
          'engine_size': engineSize,
          'cif_value': cifValue?.replaceAll(',', ''),
          'year': year,
          'line_number': lineNumber,
        };
      }
    } catch (e) {
      // If parsing fails, return basic info
      return {
        'description': line,
        'line_number': lineNumber,
        'serial_number': 'N/A',
        'cif_value': 'N/A',
        'year': 'N/A',
        'engine_size': 'N/A',
      };
    }
    
    return null;
  }

  void _selectVehicle(Map<String, dynamic> vehicleData) {
    try {
      // Create UraVehicle object from search result
      final vehicle = UraVehicle(
        id: vehicleData['line_number'] ?? 0,
        serialNumber: vehicleData['serial_number'],
        hscCode: vehicleData['hsc_code'] ?? '',
        countryOrigin: vehicleData['country_origin'] ?? '',
        make: _extractMake(vehicleData['description'] ?? ''),
        model: _extractModel(vehicleData['description'] ?? ''),
        year: int.tryParse(vehicleData['year'] ?? '2020') ?? 2020,
        engineCC: _parseEngineCC(vehicleData['engine_size']) ?? 0,
        description: vehicleData['description'] ?? '',
        cifUsd: double.tryParse(vehicleData['cif_value'] ?? '0') ?? 0.0,
        databaseMonth: 'PDF Search',
        downloadedAt: DateTime.now(),
        isActive: true,
      );
      
      widget.onVehicleSelected(vehicle);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Vehicle selected: ${vehicle.description}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error selecting vehicle: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _extractMake(String description) {
    final makes = ['Toyota', 'Honda', 'Nissan', 'BMW', 'Mercedes', 'Audi', 'Ford', 'Chevrolet'];
    for (final make in makes) {
      if (description.toLowerCase().contains(make.toLowerCase())) {
        return make;
      }
    }
    return 'Unknown';
  }

  String _extractModel(String description) {
    // Simple model extraction - first word after make
    final words = description.split(' ');
    if (words.length > 1) {
      return words[1];
    }
    return 'Unknown';
  }

  int? _parseEngineCC(String? engineSize) {
    if (engineSize == null || engineSize.isEmpty) return null;
    
    final regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(engineSize);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }
}
