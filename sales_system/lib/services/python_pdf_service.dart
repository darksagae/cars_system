import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

class PythonPdfService {
  static const String _pythonScriptName = 'ura_pdf_extractor.py';
  static const String _pythonDir = 'python_pdf_extractor';

  /// Extract data from URA PDF using Python script
  static Future<Map<String, dynamic>> extractFromPdf(String pdfPath) async {
    try {
      // Get the application documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      final pythonDir = Directory('${documentsDir.path}/$_pythonDir');
      
      // Ensure Python directory exists
      if (!await pythonDir.exists()) {
        await pythonDir.create(recursive: true);
        await _setupPythonEnvironment(pythonDir);
      }

      // Check if Python script exists
      final scriptFile = File('${pythonDir.path}/$_pythonScriptName');
      if (!await scriptFile.exists()) {
        return {
          'success': false,
          'error': 'Python extraction script not found. Please ensure the script is properly installed.'
        };
      }

      // Generate output CSV filename
      final pdfFileName = pdfPath.split('/').last.split('.').first;
      final outputCsv = '${pythonDir.path}/${pdfFileName}_extracted.csv';

      // Run Python script using virtual environment
      final result = await Process.run(
        'venv/bin/python',
        [
          scriptFile.path,
          pdfPath,
          '-o', outputCsv,
          '-v'
        ],
        workingDirectory: pythonDir.path,
      );

      print('Python script stdout: ${result.stdout}');
      print('Python script stderr: ${result.stderr}');

      if (result.exitCode == 0) {
        // Check if output CSV was created
        final outputFile = File(outputCsv);
        if (await outputFile.exists()) {
          // Parse the CSV data
          final csvData = await _parseCsvFile(outputFile);
          
          return {
            'success': true,
            'data': csvData['vehicles'],
            'stats': csvData['stats'],
            'output_file': outputCsv,
            'message': 'PDF extraction completed successfully'
          };
        } else {
          return {
            'success': false,
            'error': 'Python script completed but no output CSV was generated'
          };
        }
      } else {
        return {
          'success': false,
          'error': 'Python script failed: ${result.stderr}'
        };
      }

    } catch (e) {
      return {
        'success': false,
        'error': 'Error running Python extraction: $e'
      };
    }
  }

  /// Setup Python environment and dependencies
  static Future<void> _setupPythonEnvironment(Directory pythonDir) async {
    try {
      // Create requirements.txt
      final requirementsFile = File('${pythonDir.path}/requirements.txt');
      await requirementsFile.writeAsString('''
pdfplumber==0.10.3
pandas==2.1.4
numpy==1.24.3
openpyxl==3.1.2
python-dateutil==2.8.2
''');

      // Create the Python extraction script
      final scriptFile = File('${pythonDir.path}/$_pythonScriptName');
      await scriptFile.writeAsString(_getPythonScriptContent());

      // Make script executable
      await Process.run('chmod', ['+x', scriptFile.path]);

      print('Python environment setup completed');
    } catch (e) {
      print('Error setting up Python environment: $e');
    }
  }

  /// Parse CSV file and extract vehicle data
  static Future<Map<String, dynamic>> _parseCsvFile(File csvFile) async {
    try {
      final lines = await csvFile.readAsLines();
      if (lines.isEmpty) {
        return {'vehicles': [], 'stats': {}};
      }

      final headers = _parseCsvLine(lines[0]);
      final vehicles = <Map<String, dynamic>>[];

      for (int i = 1; i < lines.length; i++) {
        final values = _parseCsvLine(lines[i]);
        if (values.length >= headers.length) {
          final vehicle = <String, dynamic>{};
          
          for (int j = 0; j < headers.length; j++) {
            vehicle[headers[j]] = values[j];
          }
          
          vehicles.add(vehicle);
        }
      }

      // Generate stats
      final stats = {
        'total_vehicles': vehicles.length,
        'unique_makes': vehicles.map((v) => v['make']).toSet().length,
        'unique_models': vehicles.map((v) => v['model']).toSet().length,
        'year_range': _getYearRange(vehicles),
        'cif_range': _getCifRange(vehicles),
      };

      return {'vehicles': vehicles, 'stats': stats};
    } catch (e) {
      print('Error parsing CSV file: $e');
      return {'vehicles': [], 'stats': {}};
    }
  }

  /// Parse a single CSV line
  static List<String> _parseCsvLine(String line) {
    final result = <String>[];
    bool inQuotes = false;
    String currentField = '';
    
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(currentField.trim());
        currentField = '';
      } else {
        currentField += char;
      }
    }
    
    result.add(currentField.trim());
    return result;
  }

  /// Get year range from vehicles data
  static String _getYearRange(List<Map<String, dynamic>> vehicles) {
    if (vehicles.isEmpty) return 'N/A';
    
    final years = vehicles
        .map((v) => int.tryParse(v['year']?.toString() ?? '0'))
        .where((y) => y != null && y! > 0)
        .cast<int>()
        .toList();
    
    if (years.isEmpty) return 'N/A';
    
    years.sort();
    return '${years.first} - ${years.last}';
  }

  /// Get CIF value range from vehicles data
  static String _getCifRange(List<Map<String, dynamic>> vehicles) {
    if (vehicles.isEmpty) return 'N/A';
    
    final cifValues = vehicles
        .map((v) => double.tryParse(v['cif_usd']?.toString().replaceAll(',', '') ?? '0'))
        .where((c) => c != null && c! > 0)
        .cast<double>()
        .toList();
    
    if (cifValues.isEmpty) return 'N/A';
    
    cifValues.sort();
    return '\$${cifValues.first.toStringAsFixed(0)} - \$${cifValues.last.toStringAsFixed(0)}';
  }

  /// Check if Python is available on the system
  static Future<bool> isPythonAvailable() async {
    try {
      final result = await Process.run('python3', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Install Python dependencies
  static Future<Map<String, dynamic>> installDependencies() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final pythonDir = Directory('${documentsDir.path}/$_pythonDir');
      
      if (!await pythonDir.exists()) {
        return {'success': false, 'error': 'Python directory not found'};
      }

      final requirementsFile = File('${pythonDir.path}/requirements.txt');
      if (!await requirementsFile.exists()) {
        return {'success': false, 'error': 'Requirements file not found'};
      }

      final result = await Process.run(
        'pip3',
        ['install', '-r', requirementsFile.path],
        workingDirectory: pythonDir.path,
      );

      if (result.exitCode == 0) {
        return {'success': true, 'message': 'Dependencies installed successfully'};
      } else {
        return {
          'success': false,
          'error': 'Failed to install dependencies: ${result.stderr}'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error installing dependencies: $e'};
    }
  }

  /// Get the Python script content (embedded for distribution)
  static String _getPythonScriptContent() {
    // This would contain the full Python script content
    // For brevity, I'll return a placeholder that references the actual script
    return '''
# URA PDF Extractor Script
# This is a placeholder - the actual script should be copied from ura_pdf_extractor.py
print("URA PDF Extractor - Please ensure the full script is installed")
''';
  }
}
