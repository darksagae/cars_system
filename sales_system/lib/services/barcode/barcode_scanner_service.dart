import 'package:flutter/services.dart';

class BarcodeScannerService {
  static const MethodChannel _channel = MethodChannel('barcode_scanner');

  // Initialize barcode scanner
  Future<bool> initialize() async {
    try {
      final bool result = await _channel.invokeMethod('initialize');
      return result;
    } on PlatformException catch (e) {
      print('Failed to initialize barcode scanner: ${e.message}');
      return false;
    }
  }

  // Start barcode scanning
  Future<String?> scanBarcode() async {
    try {
      final String? result = await _channel.invokeMethod('scanBarcode');
      return result;
    } on PlatformException catch (e) {
      print('Failed to scan barcode: ${e.message}');
      return null;
    }
  }

  // Stop barcode scanning
  Future<void> stopScanning() async {
    try {
      await _channel.invokeMethod('stopScanning');
    } on PlatformException catch (e) {
      print('Failed to stop scanning: ${e.message}');
    }
  }

  // Check if camera is available
  Future<bool> isCameraAvailable() async {
    try {
      final bool result = await _channel.invokeMethod('isCameraAvailable');
      return result;
    } on PlatformException catch (e) {
      print('Failed to check camera availability: ${e.message}');
      return false;
    }
  }

  // Get barcode scanner status
  Future<String> getScannerStatus() async {
    try {
      final String result = await _channel.invokeMethod('getScannerStatus');
      return result;
    } on PlatformException catch (e) {
      print('Failed to get scanner status: ${e.message}');
      return 'error';
    }
  }

  // Set barcode formats to scan
  Future<void> setBarcodeFormats(List<String> formats) async {
    try {
      await _channel.invokeMethod('setBarcodeFormats', {'formats': formats});
    } on PlatformException catch (e) {
      print('Failed to set barcode formats: ${e.message}');
    }
  }

  // Enable/disable flash
  Future<void> setFlashEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod('setFlashEnabled', {'enabled': enabled});
    } on PlatformException catch (e) {
      print('Failed to set flash: ${e.message}');
    }
  }

  // Set scan timeout
  Future<void> setScanTimeout(int timeoutMs) async {
    try {
      await _channel.invokeMethod('setScanTimeout', {'timeout': timeoutMs});
    } on PlatformException catch (e) {
      print('Failed to set scan timeout: ${e.message}');
    }
  }

  // Get supported barcode formats
  Future<List<String>> getSupportedFormats() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getSupportedFormats');
      return result.cast<String>();
    } on PlatformException catch (e) {
      print('Failed to get supported formats: ${e.message}');
      return [];
    }
  }

  // Validate barcode format
  bool isValidBarcodeFormat(String barcode, String format) {
    switch (format.toLowerCase()) {
      case 'ean13':
        return _isValidEAN13(barcode);
      case 'ean8':
        return _isValidEAN8(barcode);
      case 'upca':
        return _isValidUPCA(barcode);
      case 'upce':
        return _isValidUPCE(barcode);
      case 'code128':
        return _isValidCode128(barcode);
      case 'code39':
        return _isValidCode39(barcode);
      case 'qr':
        return barcode.isNotEmpty;
      default:
        return barcode.isNotEmpty;
    }
  }

  // Get barcode type from string
  String getBarcodeType(String barcode) {
    if (barcode.length == 13 && _isValidEAN13(barcode)) {
      return 'EAN13';
    } else if (barcode.length == 8 && _isValidEAN8(barcode)) {
      return 'EAN8';
    } else if (barcode.length == 12 && _isValidUPCA(barcode)) {
      return 'UPCA';
    } else if (barcode.length == 6 && _isValidUPCE(barcode)) {
      return 'UPCE';
    } else if (_isValidCode128(barcode)) {
      return 'CODE128';
    } else if (_isValidCode39(barcode)) {
      return 'CODE39';
    } else if (barcode.contains('http') || barcode.contains('www')) {
      return 'QR';
    } else {
      return 'UNKNOWN';
    }
  }

  // Validate EAN13 barcode
  bool _isValidEAN13(String barcode) {
    if (barcode.length != 13 || !RegExp(r'^\d+$').hasMatch(barcode)) {
      return false;
    }
    
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      int digit = int.parse(barcode[i]);
      sum += (i % 2 == 0) ? digit : digit * 3;
    }
    
    int checkDigit = (10 - (sum % 10)) % 10;
    return checkDigit == int.parse(barcode[12]);
  }

  // Validate EAN8 barcode
  bool _isValidEAN8(String barcode) {
    if (barcode.length != 8 || !RegExp(r'^\d+$').hasMatch(barcode)) {
      return false;
    }
    
    int sum = 0;
    for (int i = 0; i < 7; i++) {
      int digit = int.parse(barcode[i]);
      sum += (i % 2 == 0) ? digit * 3 : digit;
    }
    
    int checkDigit = (10 - (sum % 10)) % 10;
    return checkDigit == int.parse(barcode[7]);
  }

  // Validate UPCA barcode
  bool _isValidUPCA(String barcode) {
    if (barcode.length != 12 || !RegExp(r'^\d+$').hasMatch(barcode)) {
      return false;
    }

    int sum = 0;
    for (int i = 0; i < 11; i++) {
      int digit = int.parse(barcode[i]);
      sum += (i % 2 == 0) ? digit * 3 : digit;
    }
    
    int checkDigit = (10 - (sum % 10)) % 10;
    return checkDigit == int.parse(barcode[11]);
  }

  // Validate UPCE barcode
  bool _isValidUPCE(String barcode) {
    if (barcode.length != 6 || !RegExp(r'^\d+$').hasMatch(barcode)) {
      return false;
    }
    // UPCE validation logic would go here
    return true;
  }

  // Validate Code128 barcode
  bool _isValidCode128(String barcode) {
    // Code128 can contain various characters
    return barcode.isNotEmpty && barcode.length <= 80;
  }

  // Validate Code39 barcode
  bool _isValidCode39(String barcode) {
    // Code39 can contain uppercase letters, numbers, and some special characters
    return RegExp(r'^[A-Z0-9\-\.\s\$\/\+\%]+$').hasMatch(barcode);
  }

  // Generate barcode image (placeholder - would need barcode generation library)
  Future<String?> generateBarcodeImage(String barcode) async {
    // This would typically use a barcode generation library
    // For now, return null as placeholder
    return null;
  }

  // Search products by barcode
  Future<List<Map<String, dynamic>>> searchProductsByBarcode(String barcode) async {
    // This would search the database for products with matching barcode
    // For now, return empty list as placeholder
    return [];
  }

  // Create product from barcode
  Map<String, dynamic> createProductFromBarcode(String barcode) {
    return {
      'sku': barcode,
      'name': 'Product from Barcode',
      'description': 'Product created from barcode scan',
      'barcode': barcode,
      'barcodeType': getBarcodeType(barcode),
      'price': 0.0,
      'cost': 0.0,
      'stock': 0,
      'category': 'Scanned',
      'status': 'active',
    };
  }
}
