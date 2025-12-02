import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:async';
import 'dart:io' show Directory, File, Platform, Process;
import 'dart:typed_data';
import '../models/ura_vehicle.dart';
import 'glass_liquid_theme.dart';

class DynamicPdfSearch extends StatefulWidget {
  final Function(UraVehicle) onVehicleSelected;

  const DynamicPdfSearch({
    Key? key,
    required this.onVehicleSelected,
  }) : super(key: key);

  @override
  State<DynamicPdfSearch> createState() => _DynamicPdfSearchState();
}

class _DynamicPdfSearchState extends State<DynamicPdfSearch> {
  String? _selectedPdfPath;
  String _searchQuery = '';
  List<Map<String, dynamic>> _allResults = [];
  List<Map<String, dynamic>> _filteredResults = [];
  List<String> _activeFilters = [];
  bool _isSearching = false;
  String _statusMessage = 'Select a PDF file to search';
  bool _isPdfLocked = false;
  
  // Filter options
  String? _selectedMake;
  String? _selectedYear;
  String? _selectedEngineSize;
  double? _minCif;
  double? _maxCif;
  
  // Available filter options
  List<String> _availableMakes = [];
  List<String> _availableYears = [];
  List<String> _availableEngineSizes = [];

  Timer? _pdfCheckTimer;
  Timer? _searchDebounceTimer;
  
  // Text caching
  String? _cachedPdfText;
  String? _cachedPdfPath;
  DateTime? _cachedPdfModificationTime;

  @override
  void initState() {
    super.initState();
    _loadPersistedState();
    // Periodically check for new PDFs every 5 seconds
    _pdfCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkForLatestPdf();
    });
  }

  @override
  void dispose() {
    _pdfCheckTimer?.cancel();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check for latest PDF when widget becomes visible
    _checkForLatestPdf();
  }

  String? _latestMvDatabasePdfPath;

  /// Check for and load the latest MV database PDF if available
  Future<void> _checkForLatestPdf() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? latestMvDatabasePdf = prefs.getString('last_ura_database_pdf_path');
      
          // Also check the Downloads/ura_database directory directly in case SharedPreferences is outdated
          if (latestMvDatabasePdf == null || !await File(latestMvDatabasePdf).exists()) {
            try {
              final homeDir = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '/tmp';
              final uraDatabaseDir = Directory(path.join(homeDir, 'Downloads', 'ura_database'));
          if (await uraDatabaseDir.exists()) {
            final pdfFiles = await uraDatabaseDir
                .list()
                .where((entity) => entity.path.toLowerCase().endsWith('.pdf'))
                .cast<File>()
                .toList();
            
            if (pdfFiles.isNotEmpty) {
              // Sort by modification time (newest first)
              final filesWithTime = await Future.wait(
                pdfFiles.map((file) async => {
                  'file': file,
                  'time': await file.lastModified(),
                })
              );
              
              filesWithTime.sort((a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));
              
              if (filesWithTime.isNotEmpty) {
                final latestFile = filesWithTime[0]['file'] as File;
                latestMvDatabasePdf = latestFile.path;
                await prefs.setString('last_ura_database_pdf_path', latestMvDatabasePdf);
              }
            }
          }
        } catch (e) {
          print('⚠️ Error checking ura_database directory: $e');
        }
      }
      
      _latestMvDatabasePdfPath = latestMvDatabasePdf;
      
      if (latestMvDatabasePdf != null && await File(latestMvDatabasePdf).exists()) {
        // Always update state to show the button if needed
        if (mounted) {
          setState(() {
            // Trigger rebuild to update UI
          });
        }
        
        // Only auto-load if no PDF is currently selected or if it's different
        if (_selectedPdfPath == null || _selectedPdfPath != latestMvDatabasePdf) {
          // Always auto-load the latest PDF (don't require user to manually select)
          if (_selectedPdfPath == null || !_isPdfLocked) {
            final month = prefs.getString('last_ura_database_month') ?? 'Unknown';
            if (mounted) {
              setState(() {
                _selectedPdfPath = latestMvDatabasePdf;
                _statusMessage = 'Latest MV Database PDF loaded (Month: $month)';
                _isPdfLocked = false;
                // Clear search results when loading new PDF
                _allResults = [];
                _filteredResults = [];
                _searchQuery = '';
                _activeFilters = [];
              });
              await _savePersistedState();
            }
          }
        }
      }
    } catch (e) {
      // Silently fail - don't disrupt the user experience
      print('⚠️ Error checking for latest PDF: $e');
    }
  }

  Future<void> _loadPersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    final isLocked = prefs.getBool('pdf_locked') ?? false;
    final pdfPath = prefs.getString('pdf_path');
    
    // First, try to find the latest PDF from SharedPreferences
    String? latestMvDatabasePdf = prefs.getString('last_ura_database_pdf_path');
    
      // If not found in SharedPreferences, check the Downloads/ura_database directory directly
      if (latestMvDatabasePdf == null || !await File(latestMvDatabasePdf).exists()) {
        try {
          final homeDir = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '/tmp';
          final uraDatabaseDir = Directory(path.join(homeDir, 'Downloads', 'ura_database'));
        if (await uraDatabaseDir.exists()) {
          final pdfFiles = await uraDatabaseDir
              .list()
              .where((entity) => entity.path.toLowerCase().endsWith('.pdf'))
              .cast<File>()
              .toList();
          
          if (pdfFiles.isNotEmpty) {
            // Sort by modification time (newest first)
            final filesWithTime = await Future.wait(
              pdfFiles.map((file) async => {
                'file': file,
                'time': await file.lastModified(),
              })
            );
            
            filesWithTime.sort((a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));
            
            if (filesWithTime.isNotEmpty) {
              final latestFile = filesWithTime[0]['file'] as File;
              latestMvDatabasePdf = latestFile.path;
              // Update SharedPreferences for future use
              await prefs.setString('last_ura_database_pdf_path', latestMvDatabasePdf);
            }
          }
        }
      } catch (e) {
        print('⚠️ Error checking ura_database directory: $e');
      }
    }
    
    // Always prioritize the latest MV database PDF
    if (latestMvDatabasePdf != null && await File(latestMvDatabasePdf).exists()) {
      // Check if the persisted PDF path is different from the latest
      // If so, always use the latest (even if locked)
      if (pdfPath != latestMvDatabasePdf) {
        // Clear old persisted path if it's not the latest
        if (pdfPath != null && pdfPath != latestMvDatabasePdf) {
          await prefs.remove('pdf_path');
          await prefs.setBool('pdf_locked', false);
        }
      }
      
      setState(() {
        _selectedPdfPath = latestMvDatabasePdf;
        final month = prefs.getString('last_ura_database_month') ?? 'Unknown';
        _statusMessage = 'Latest MV Database PDF loaded (Month: $month)';
        _isPdfLocked = false; // Always unlock when using latest PDF
      });
      await _savePersistedState();
      return;
    }
    
    // Fall back to previously selected PDF if locked (only if no latest MV database PDF exists)
    if (isLocked && pdfPath != null && await File(pdfPath).exists()) {
      // Check if this old PDF is in the Downloads/ura_database directory - if so, it's outdated
      try {
        final homeDir = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '/tmp';
        final uraDatabaseDir = path.join(homeDir, 'Downloads', 'ura_database');
        if (pdfPath.startsWith(uraDatabaseDir)) {
          // This is an old MV database PDF, clear it
          await prefs.remove('pdf_path');
          await prefs.setBool('pdf_locked', false);
          setState(() {
            _statusMessage = 'Please select a PDF file to search';
            _selectedPdfPath = null;
            _isPdfLocked = false;
          });
          return;
        }
      } catch (_) {
        // Ignore errors
      }
      
      setState(() {
        _isPdfLocked = isLocked;
        _selectedPdfPath = pdfPath;
        _statusMessage = 'PDF restored from previous session (locked)';
      });
    }
  }

  Future<void> _savePersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pdf_locked', _isPdfLocked);
    await prefs.setString('pdf_path', _selectedPdfPath ?? '');
  }

  Future<void> _clearPersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pdf_locked');
    await prefs.remove('pdf_path');
  }

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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),
            
            const SizedBox(height: 20),
            
            // PDF Selection
            _buildPdfSelection(),
            
            const SizedBox(height: 20),
            
            // Dynamic Search Interface
            if (_selectedPdfPath != null) _buildDynamicSearchInterface(),
            
            const SizedBox(height: 20),
            
            // Status Message
            _buildStatusMessage(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.auto_awesome,
          color: GlassLiquidTheme.accentBlue,
          size: 24,
        ),
        const SizedBox(width: 12),
        Text(
          'Dynamic PDF Search',
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
        // PDF path display
        Container(
          width: double.infinity,
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
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 12),
        // Buttons row - responsive layout
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Lock/Unlock button
            if (_selectedPdfPath != null)
              ElevatedButton.icon(
                onPressed: _togglePdfLock,
                icon: Icon(
                  _isPdfLocked ? Icons.lock : Icons.lock_open,
                  size: 16,
                ),
                label: Text(
                  _isPdfLocked ? 'Unlock' : 'Lock',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isPdfLocked 
                    ? Colors.orange 
                    : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            // Load Latest MV Database PDF button
            Builder(
              builder: (context) {
                final latestPdfPath = _latestMvDatabasePdfPath;
                final latestPdfExists = latestPdfPath != null;
                final isCurrentLatest = _selectedPdfPath == latestPdfPath;
                
                if (!latestPdfExists || isCurrentLatest) {
                  return const SizedBox.shrink();
                }
                
                return ElevatedButton.icon(
                  onPressed: _isPdfLocked ? null : _loadLatestMvDatabasePdf,
                  icon: const Icon(Icons.cloud_download, size: 16),
                  label: Text(
                    'Load Latest MV DB',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPdfLocked 
                      ? Colors.grey 
                      : Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                );
              },
            ),
            // Select PDF button
            ElevatedButton.icon(
              onPressed: _isPdfLocked ? null : _selectPdfFile,
              icon: const Icon(Icons.folder_open, size: 16),
              label: Text(
                'Select PDF',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isPdfLocked 
                  ? Colors.grey 
                  : GlassLiquidTheme.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
        // Lock status message
        if (_selectedPdfPath != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(
                  _isPdfLocked ? Icons.lock : Icons.lock_open,
                  color: _isPdfLocked ? Colors.orange : Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _isPdfLocked 
                    ? 'PDF is locked - will persist for future use'
                    : 'PDF is unlocked - will be cleared when loading new one',
                  style: GoogleFonts.poppins(
                    color: _isPdfLocked ? Colors.orange : Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDynamicSearchInterface() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '2. Dynamic Search',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        
        // Main Search Box
        _buildMainSearchBox(),
        
        const SizedBox(height: 16),
        
        // Active Filters
        if (_activeFilters.isNotEmpty) _buildActiveFilters(),
        
        const SizedBox(height: 16),
        
        // Filter Options
        _buildFilterOptions(),
        
        const SizedBox(height: 16),
        
        // Search Results
        if (_filteredResults.isNotEmpty) _buildSearchResults(),
      ],
    );
  }

  Widget _buildMainSearchBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GlassLiquidTheme.accentBlue.withOpacity(0.3)),
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          
          // Cancel previous debounce timer
          _searchDebounceTimer?.cancel();
          
          if (value.length >= 2) {
            // Debounce search - wait 400ms after user stops typing
            _searchDebounceTimer = Timer(const Duration(milliseconds: 400), () {
              _performSearch();
            });
          } else {
            setState(() {
              _allResults = [];
              _filteredResults = [];
            });
          }
        },
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Type any car information (e.g., "RAV4", "Toyota 2020", "BMW 3 Series", "2500cc")',
          hintStyle: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: GlassLiquidTheme.accentBlue,
            size: 20,
          ),
          suffixIcon: _isSearching
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(GlassLiquidTheme.accentBlue),
                  ),
                )
              : _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white70),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _allResults = [];
                          _filteredResults = [];
                          _activeFilters = [];
                        });
                      },
                    )
                  : null,
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Filters:',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _activeFilters.map((filter) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: GlassLiquidTheme.accentBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: GlassLiquidTheme.accentBlue),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    filter,
                    style: GoogleFonts.poppins(
                      color: GlassLiquidTheme.accentBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _removeFilter(filter),
                    child: Icon(
                      Icons.close,
                      color: GlassLiquidTheme.accentBlue,
                      size: 14,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFilterOptions() {
    if (_allResults.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Narrow Down Results:',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('Make', _selectedMake, _availableMakes, (value) {
                setState(() {
                  _selectedMake = value;
                  if (value != null) _addFilter('Make: $value');
                });
                _applyFilters();
              }),
              const SizedBox(width: 8),
              _buildFilterChip('Year', _selectedYear, _availableYears, (value) {
                setState(() {
                  _selectedYear = value;
                  if (value != null) _addFilter('Year: $value');
                });
                _applyFilters();
              }),
              const SizedBox(width: 8),
              _buildFilterChip('Engine', _selectedEngineSize, _availableEngineSizes, (value) {
                setState(() {
                  _selectedEngineSize = value;
                  if (value != null) _addFilter('Engine: $value');
                });
                _applyFilters();
              }),
              const SizedBox(width: 8),
              _buildCifRangeFilter(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String? selectedValue, List<String> options, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: selectedValue != null ? GlassLiquidTheme.accentBlue.withOpacity(0.2) : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selectedValue != null ? GlassLiquidTheme.accentBlue : Colors.white.withOpacity(0.2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          hint: Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          dropdownColor: const Color(0xFF2A2A3E),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 11,
          ),
          items: options.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCifRangeFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (_minCif != null || _maxCif != null) ? Colors.green.withOpacity(0.2) : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (_minCif != null || _maxCif != null) ? Colors.green : Colors.white.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'CIF:',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 60,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _minCif = double.tryParse(value);
                  if (_minCif != null) _addFilter('Min CIF: \$${_minCif!.toStringAsFixed(0)}');
                });
                _applyFilters();
              },
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 11,
              ),
              decoration: InputDecoration(
                hintText: 'Min',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 10,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              ),
            ),
          ),
          Text(
            '-',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          SizedBox(
            width: 60,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _maxCif = double.tryParse(value);
                  if (_maxCif != null) _addFilter('Max CIF: \$${_maxCif!.toStringAsFixed(0)}');
                });
                _applyFilters();
              },
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 11,
              ),
              decoration: InputDecoration(
                hintText: 'Max',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 10,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Results (${_filteredResults.length})',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            if (_filteredResults.length > 10)
              TextButton.icon(
                onPressed: _clearAllFilters,
                icon: const Icon(Icons.clear_all, size: 16),
                label: Text(
                  'Clear All',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
          ],
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
            itemCount: _filteredResults.length,
            itemBuilder: (context, index) {
              final result = _filteredResults[index];
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
    if (_filteredResults.isNotEmpty) return Colors.green;
    if (_allResults.isNotEmpty) return Colors.orange;
    if (_selectedPdfPath != null) return GlassLiquidTheme.accentBlue;
    return Colors.grey;
  }

  IconData _getStatusIcon() {
    if (_isSearching) return Icons.search;
    if (_filteredResults.isNotEmpty) return Icons.check_circle;
    if (_allResults.isNotEmpty) return Icons.filter_list;
    if (_selectedPdfPath != null) return Icons.info;
    return Icons.help_outline;
  }

  void _togglePdfLock() async {
    setState(() {
      _isPdfLocked = !_isPdfLocked;
    });
    
    if (_isPdfLocked) {
      // Save the lock state when locking
      await _savePersistedState();
    } else {
      // Clear the persisted state when unlocking
      await _clearPersistedState();
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isPdfLocked 
            ? '🔒 PDF locked - will persist for future use'
            : '🔓 PDF unlocked - will be cleared when loading new one'
        ),
        backgroundColor: _isPdfLocked ? Colors.orange : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadLatestMvDatabasePdf() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final latestPdfPath = prefs.getString('last_ura_database_pdf_path');
      
      if (latestPdfPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ No latest MV database PDF found'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      
      final file = File(latestPdfPath);
      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Latest MV database PDF file not found'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      
      // Get file size
      final length = await file.length();
      final sizeMb = length / (1024 * 1024);
      final month = prefs.getString('last_ura_database_month') ?? 'Unknown';
      
      setState(() {
        _selectedPdfPath = latestPdfPath;
        _statusMessage = 'Latest MV Database PDF loaded (Month: $month, ${sizeMb.toStringAsFixed(1)} MB)';
        _allResults = [];
        _filteredResults = [];
        _searchQuery = '';
        _activeFilters = [];
        _isPdfLocked = false; // Don't auto-lock the latest PDF
        
        // Clear cache when new PDF is loaded
        _cachedPdfText = null;
        _cachedPdfPath = null;
        _cachedPdfModificationTime = null;
      });
      
      await _savePersistedState();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Latest MV Database PDF loaded (Month: $month)'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading latest MV database PDF: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error loading latest MV database PDF: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _selectPdfFile() async {
    // If PDF is locked, show confirmation dialog
    if (_isPdfLocked) {
      final shouldUnlock = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'PDF is Locked',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'The current PDF is locked and will persist. To load a new PDF, you need to unlock it first. Do you want to unlock and load a new PDF?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: GoogleFonts.poppins()),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Unlock & Load New', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      );
      
      if (shouldUnlock != true) return;
      
      // Unlock the PDF
      setState(() {
        _isPdfLocked = false;
      });
      
      // Save the unlock state
      await _savePersistedState();
    }

    try {
      // Set initial directory to Downloads/ura_database folder if it exists
      String? initialDirectory;
      try {
        final homeDir = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '/tmp';
        final uraDatabaseDir = Directory(path.join(homeDir, 'Downloads', 'ura_database'));
        if (await uraDatabaseDir.exists()) {
          initialDirectory = uraDatabaseDir.path;
        }
      } catch (_) {
        // Ignore errors, use default directory
      }
      
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        dialogTitle: 'Select URA Database PDF',
        initialDirectory: initialDirectory,
      );

      if (result != null && result.files.single.path != null) {
        final selectedPath = result.files.single.path!;
        final file = File(selectedPath);

        // Basic validations
        if (!await file.exists()) {
          setState(() {
            _statusMessage = 'Selected file does not exist';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Selected file does not exist'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }

        if (!selectedPath.toLowerCase().endsWith('.pdf')) {
          setState(() {
            _statusMessage = 'Please select a .pdf file';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Invalid file type. Please select a .pdf'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }

        // Size validation (e.g., 200MB limit)
        final length = await file.length();
        final sizeMb = length / (1024 * 1024);
        if (sizeMb > 200) {
          setState(() {
            _statusMessage = 'PDF too large (${sizeMb.toStringAsFixed(1)} MB). Max 200MB';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ PDF too large (${sizeMb.toStringAsFixed(1)} MB). Max 200MB'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }

        setState(() {
          _selectedPdfPath = selectedPath;
          _statusMessage = 'PDF loaded successfully (${sizeMb.toStringAsFixed(1)} MB)';
          _allResults = [];
          _filteredResults = [];
          _searchQuery = '';
          _activeFilters = [];
          _isPdfLocked = false; // Reset lock when new PDF is loaded
          
          // Clear cache when new PDF is loaded
          _cachedPdfText = null;
          _cachedPdfPath = null;
          _cachedPdfModificationTime = null;
        });
        
        // Save the new PDF path and reset lock state
        await _savePersistedState();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ PDF loaded: ${selectedPath.split('/').last} (${sizeMb.toStringAsFixed(1)} MB)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error selecting PDF: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error selecting PDF: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _performSearch() async {
    if (_selectedPdfPath == null || _searchQuery.length < 2) return;

    setState(() {
      _isSearching = true;
      _statusMessage = 'Searching in PDF...';
    });

    try {
      // Check if pdftotext is available
      final pdftotextOk = await _isPdftotextAvailable();
      if (!pdftotextOk) {
        setState(() {
          _isSearching = false;
          _statusMessage = 'pdftotext not found. Please install poppler-utils (sudo apt install poppler-utils).';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ pdftotext not found. Install: sudo apt install poppler-utils'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      // Get cached text or extract new
      final file = File(_selectedPdfPath!);
      final currentModTime = await file.lastModified();
      
      String textContent;
      if (_cachedPdfText != null && 
          _cachedPdfPath == _selectedPdfPath && 
          _cachedPdfModificationTime == currentModTime) {
        // Use cached text
        textContent = _cachedPdfText!;
        print('✅ Using cached PDF text');
      } else {
        // Extract text from PDF
        final pdfBytes = await file.readAsBytes();
        textContent = await _extractTextFromPdf(pdfBytes);
        
        // Cache the extracted text
        _cachedPdfText = textContent;
        _cachedPdfPath = _selectedPdfPath;
        _cachedPdfModificationTime = currentModTime;
        print('✅ Cached PDF text for future searches');
      }
      
      // Search for matching lines
      final results = _searchInText(textContent, _searchQuery);
      
      setState(() {
        _allResults = results;
        _filteredResults = results;
        _isSearching = false;
        _statusMessage = results.isEmpty
            ? 'No results for "$_searchQuery". Try adding more details.'
            : 'Found ${results.length} results for "$_searchQuery"';
      });
      
      // Extract filter options from results
      _extractFilterOptions();
    } catch (e) {
      print('❌ Search error: $e');
      setState(() {
        _isSearching = false;
        // Provide more specific error messages
        if (e.toString().contains('pdftotext')) {
          _statusMessage = 'PDF text extraction failed. Please ensure the PDF is not corrupted.';
        } else if (e.toString().contains('Permission')) {
          _statusMessage = 'Permission denied. Please check file permissions.';
        } else if (e.toString().contains('No such file')) {
          _statusMessage = 'PDF file not found. Please select a valid PDF.';
        } else {
          _statusMessage = 'Search error: ${e.toString().length > 50 ? e.toString().substring(0, 50) + "..." : e.toString()}';
        }
        _allResults = [];
        _filteredResults = [];
      });
      
      // Clear cache on error to force re-extraction
      _cachedPdfText = null;
      _cachedPdfPath = null;
      _cachedPdfModificationTime = null;
    }
  }

  Future<bool> _isPdftotextAvailable() async {
    try {
      final result = await Process.run('pdftotext', ['-v']);
      return result.exitCode == 0 || result.stderr.toString().contains('pdftotext');
    } catch (_) {
      return false;
    }
  }

  void _extractFilterOptions() {
    final makes = <String>{};
    final years = <String>{};
    final engineSizes = <String>{};
    
    for (final result in _allResults) {
      final make = _extractMake(result['description'] ?? '');
      if (make != 'Unknown') makes.add(make);
      
      final year = result['year'];
      if (year != null && year != 'N/A') years.add(year);
      
      final engineSize = result['engine_size'];
      if (engineSize != null && engineSize != 'N/A') engineSizes.add(engineSize);
    }
    
    setState(() {
      _availableMakes = makes.toList()..sort();
      _availableYears = years.toList()..sort();
      _availableEngineSizes = engineSizes.toList()..sort();
    });
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allResults);
    
    if (_selectedMake != null) {
      filtered = filtered.where((result) {
        final make = _extractMake(result['description'] ?? '');
        return make == _selectedMake;
      }).toList();
    }
    
    if (_selectedYear != null) {
      filtered = filtered.where((result) {
        return result['year'] == _selectedYear;
      }).toList();
    }
    
    if (_selectedEngineSize != null) {
      filtered = filtered.where((result) {
        return result['engine_size'] == _selectedEngineSize;
      }).toList();
    }
    
    if (_minCif != null) {
      filtered = filtered.where((result) {
        final cif = double.tryParse(result['cif_value'] ?? '0') ?? 0;
        return cif >= _minCif!;
      }).toList();
    }
    
    if (_maxCif != null) {
      filtered = filtered.where((result) {
        final cif = double.tryParse(result['cif_value'] ?? '0') ?? 0;
        return cif <= _maxCif!;
      }).toList();
    }
    
    setState(() {
      _filteredResults = filtered;
    });
  }

  void _addFilter(String filter) {
    if (!_activeFilters.contains(filter)) {
      setState(() {
        _activeFilters.add(filter);
      });
    }
  }

  void _removeFilter(String filter) {
    setState(() {
      _activeFilters.remove(filter);
      
      // Reset corresponding filter
      if (filter.startsWith('Make:')) {
        _selectedMake = null;
      } else if (filter.startsWith('Year:')) {
        _selectedYear = null;
      } else if (filter.startsWith('Engine:')) {
        _selectedEngineSize = null;
      } else if (filter.startsWith('Min CIF:')) {
        _minCif = null;
      } else if (filter.startsWith('Max CIF:')) {
        _maxCif = null;
      }
      
      _applyFilters();
    });
  }

  void _clearAllFilters() {
    setState(() {
      _activeFilters = [];
      _selectedMake = null;
      _selectedYear = null;
      _selectedEngineSize = null;
      _minCif = null;
      _maxCif = null;
      _filteredResults = _allResults;
    });
  }

  Future<String> _extractTextFromPdf(Uint8List pdfBytes) async {
    try {
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/temp_pdf.pdf');
      final outputFile = File('${tempDir.path}/temp_output.txt');
      
      await tempFile.writeAsBytes(pdfBytes);
      
      final result = await Process.run('pdftotext', [
        '-layout',
        tempFile.path,
        outputFile.path,
      ]);
      
      if (result.exitCode == 0 && await outputFile.exists()) {
        final extractedText = await outputFile.readAsString();
        
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
    final queryLower = query.toLowerCase().trim();
    
    // Split query into words for better matching
    final queryWords = queryLower.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      final lineLower = line.toLowerCase();
      
      // Improved matching: check if all query words appear in the line
      bool matches = false;
      if (queryWords.length == 1) {
        // Single word: use word boundary or contains for partial matches
        final word = queryWords[0];
        matches = RegExp(r'\b' + RegExp.escape(word) + r'\w*', caseSensitive: false).hasMatch(lineLower) ||
                  lineLower.contains(word);
      } else {
        // Multiple words: all must appear (flexible order)
        matches = queryWords.every((word) => 
          RegExp(r'\b' + RegExp.escape(word) + r'\w*', caseSensitive: false).hasMatch(lineLower) ||
          lineLower.contains(word)
        );
      }
      
      if (matches) {
        // Try to parse as vehicle data line
        final vehicleData = _parseVehicleLine(line, i + 1);
        if (vehicleData != null) {
          results.add(vehicleData);
        } else {
          // Even if parsing fails, if it looks like vehicle data, include it with partial info
          if (_isVehicleDataLine(line)) {
            results.add({
              'description': line,
              'line_number': i + 1,
              'serial_number': _extractSerialNumber(line),
              'cif_value': _extractCifValue(line),
              'year': _extractYear(line),
              'engine_size': _extractEngineSize(line),
              'hsc_code': 'N/A',
              'country_origin': 'N/A',
            });
          }
        }
      }
    }
    
    return results;
  }

  bool _isVehicleDataLine(String line) {
    // More flexible patterns to detect vehicle data lines
    return RegExp(r'^\s*\d+\s+[\d.]+\s+[A-Z]{2}\s+').hasMatch(line) ||
           RegExp(r'\d+\s+[\d.]+\s+[A-Z]{2}').hasMatch(line) ||
           (line.contains('cc') && RegExp(r'\d+').hasMatch(line)) ||
           (line.contains('CIF') && RegExp(r'[\d,]+').hasMatch(line)) ||
           RegExp(r'\$\s*[\d,]+').hasMatch(line) ||
           RegExp(r'\b\d{4}\b').hasMatch(line) && // Contains a year
           (line.contains('Toyota') || line.contains('Honda') || line.contains('Nissan') || 
            line.contains('BMW') || line.contains('Mercedes') || line.contains('Audi') ||
            line.contains('Ford') || line.contains('Jeep') || line.contains('Chevrolet') ||
            line.contains('Hyundai') || line.contains('Kia') || line.contains('Mazda') ||
            line.contains('Subaru') || line.contains('Mitsubishi') || line.contains('Suzuki'));
  }

  Map<String, dynamic>? _parseVehicleLine(String line, int lineNumber) {
    try {
      // Primary regex pattern (strict format)
      var regex = RegExp(r'^\s*(\d+)\s+([\d.]+)\s+([A-Z]{2})\s+(.+?)\s+(\d+(?:\.\d+)?\s*(?:cc|Ton|bhp|Hp|Axle))\s+([\d,]+\.?\d*)\s*$');
      var match = regex.firstMatch(line.trim());
      
      if (match != null) {
        return _buildVehicleDataFromMatch(match, line, lineNumber);
      }
      
      // Fallback pattern 1: More flexible spacing
      regex = RegExp(r'^\s*(\d+)\s+([\d.]+)\s+([A-Z]{2})\s+(.+?)\s+(\d+(?:\.\d+)?\s*(?:cc|Ton|bhp|Hp|Axle)?)\s+([\d,]+\.?\d*)\s*');
      match = regex.firstMatch(line.trim());
      if (match != null) {
        return _buildVehicleDataFromMatch(match, line, lineNumber);
      }
      
      // Fallback pattern 2: Extract components individually
      final serialNumber = _extractSerialNumber(line);
      final hscCode = _extractHscCode(line);
      final countryOrigin = _extractCountryOrigin(line);
      final description = _extractDescription(line);
      final engineSize = _extractEngineSize(line);
      final cifValue = _extractCifValue(line);
      final year = _extractYear(line);
      
      // If we found at least serial number and description, it's valid
      if (serialNumber != 'N/A' && description.isNotEmpty) {
        return {
          'serial_number': serialNumber,
          'hsc_code': hscCode,
          'country_origin': countryOrigin,
          'description': description,
          'engine_size': engineSize,
          'cif_value': cifValue,
          'year': year,
          'line_number': lineNumber,
        };
      }
    } catch (e) {
      print('⚠️ Error parsing line $lineNumber: $e');
      // Return partial data instead of null
      return {
        'description': line,
        'line_number': lineNumber,
        'serial_number': _extractSerialNumber(line),
        'cif_value': _extractCifValue(line),
        'year': _extractYear(line),
        'engine_size': _extractEngineSize(line),
        'hsc_code': 'N/A',
        'country_origin': 'N/A',
      };
    }
    
    return null;
  }
  
  Map<String, dynamic> _buildVehicleDataFromMatch(RegExpMatch match, String line, int lineNumber) {
    final serialNumber = match.group(1)?.trim() ?? 'N/A';
    final hscCode = match.group(2)?.trim() ?? 'N/A';
    final countryOrigin = match.group(3)?.trim() ?? 'N/A';
    final description = match.group(4)?.trim() ?? line;
    final engineSize = match.group(5)?.trim() ?? _extractEngineSize(line);
    final cifValue = (match.group(6)?.trim() ?? _extractCifValue(line)).replaceAll(',', '');
    final year = _extractYear(description);
    
    return {
      'serial_number': serialNumber,
      'hsc_code': hscCode,
      'country_origin': countryOrigin,
      'description': description,
      'engine_size': engineSize,
      'cif_value': cifValue,
      'year': year,
      'line_number': lineNumber,
    };
  }
  
  String _extractSerialNumber(String line) {
    final match = RegExp(r'^\s*(\d+)').firstMatch(line.trim());
    return match?.group(1) ?? 'N/A';
  }
  
  String _extractHscCode(String line) {
    final match = RegExp(r'\s+(\d+\.\d+)\s+').firstMatch(line);
    return match?.group(1) ?? 'N/A';
  }
  
  String _extractCountryOrigin(String line) {
    final match = RegExp(r'\s+([A-Z]{2})\s+').firstMatch(line);
    return match?.group(1) ?? 'N/A';
  }
  
  String _extractDescription(String line) {
    // Extract text between country code and engine size
    final match = RegExp(r'[A-Z]{2}\s+(.+?)\s+\d+(?:\.\d+)?\s*(?:cc|Ton|bhp|Hp|Axle)').firstMatch(line);
    if (match != null) return match.group(1)?.trim() ?? '';
    
    // Fallback: extract text after first few numbers
    final fallback = RegExp(r'^\s*\d+\s+[\d.]+\s+[A-Z]{2}\s+(.+?)(?:\s+\d+(?:\.\d+)?\s*(?:cc|Ton|bhp|Hp|Axle)|\s+[\d,]+)').firstMatch(line);
    if (fallback != null) return fallback.group(1)?.trim() ?? '';
    
    // Last resort: return line without leading numbers
    return line.replaceAll(RegExp(r'^\s*\d+\s+[\d.]+\s+[A-Z]{2}\s+'), '').trim();
  }
  
  String _extractEngineSize(String line) {
    final match = RegExp(r'(\d+(?:\.\d+)?\s*(?:cc|Ton|bhp|Hp|Axle))').firstMatch(line);
    return match?.group(1)?.trim() ?? 'N/A';
  }
  
  String _extractCifValue(String line) {
    // Try to find CIF value (usually at the end, may have $ or comma)
    final match = RegExp(r'[\$]?\s*([\d,]+\.?\d*)\s*$').firstMatch(line.trim());
    if (match != null) return match.group(1)?.replaceAll(',', '') ?? 'N/A';
    
    // Alternative: find large number at the end
    final altMatch = RegExp(r'([\d,]{4,}(?:\.\d+)?)\s*$').firstMatch(line.trim());
    return altMatch?.group(1)?.replaceAll(',', '') ?? 'N/A';
  }
  
  String? _extractYear(String text) {
    final yearRegex = RegExp(r'\b(19[89]\d|20[0-2]\d)\b');
    final yearMatch = yearRegex.firstMatch(text);
    return yearMatch?.group(1);
  }

  void _selectVehicle(Map<String, dynamic> vehicleData) {
    try {
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
    final makes = ['Toyota', 'Honda', 'Nissan', 'BMW', 'Mercedes', 'Audi', 'Ford', 'Chevrolet', 'Hyundai', 'Kia', 'Mazda', 'Subaru', 'Mitsubishi', 'Suzuki', 'Lexus', 'Infiniti', 'Acura', 'Volvo', 'Saab', 'Jaguar', 'Land Rover', 'Jeep', 'Chrysler', 'Dodge', 'Cadillac', 'Lincoln', 'Buick', 'GMC', 'Ram', 'Tesla'];
    for (final make in makes) {
      if (description.toLowerCase().contains(make.toLowerCase())) {
        return make;
      }
    }
    return 'Unknown';
  }

  String _extractModel(String description) {
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
