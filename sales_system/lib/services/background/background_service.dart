import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  static const String _backgroundKey = 'selected_background';
  static const String _backgroundTypeKey = 'background_type';
  
  // Background types
  static const String _typeDefault = 'default';
  static const String _typeCustom = 'custom';
  static const String _typeNone = 'none';

  // Get available default backgrounds
  List<String> getDefaultBackgrounds() {
    return [
      'assets/background/background.jpeg',
      'assets/background/2f69bda709bd682818bf59f254add43c.jpg',
      'assets/background/93d4a6f5c8ea295e3b24dd36f2540c39.jpg',
      'assets/background/2f69bda709bd682818bf59f254add43c copy.jpg',
      'assets/background/e3fd48689a1f505c0544f201df3129fa.jpg',
      'assets/background/3b47341725db37f1a09bf818dc6673a3.jpg',
      'assets/background/dc84471b6e90dc2fd9e38422bfe8fed0.jpg',
      'assets/background/ec815997f16545213fadd9f33d121ecc.jpg',
    ];
  }

  // Get current background
  Future<BackgroundInfo> getCurrentBackground() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backgroundType = prefs.getString(_backgroundTypeKey) ?? _typeDefault;
      final backgroundName = prefs.getString(_backgroundKey) ?? 'background.jpeg';
      
      // Return full asset path for default backgrounds
      final backgroundPath = backgroundType == _typeDefault 
          ? 'assets/background/$backgroundName'
          : backgroundName;

      return BackgroundInfo(
        type: backgroundType,
        path: backgroundPath,
        isCustom: backgroundType == _typeCustom,
      );
    } catch (e) {
      return BackgroundInfo(
        type: _typeDefault,
        path: 'assets/background/background.jpeg',
        isCustom: false,
      );
    }
  }

  // Set default background
  Future<void> setDefaultBackground(String backgroundPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_backgroundTypeKey, _typeDefault);
      // Extract just the filename from the full asset path
      final backgroundName = backgroundPath.replaceFirst('assets/background/', '');
      await prefs.setString(_backgroundKey, backgroundName);
    } catch (e) {
      print('Error setting default background: $e');
    }
  }

  // Set custom background
  Future<void> setCustomBackground(String imagePath) async {
    try {
      // Copy image to app directory
      final appDir = await getApplicationDocumentsDirectory();
      final backgroundDir = Directory(path.join(appDir.path, 'backgrounds'));
      
      if (!await backgroundDir.exists()) {
        await backgroundDir.create(recursive: true);
      }

      final fileName = path.basename(imagePath);
      final customPath = path.join(backgroundDir.path, 'custom_$fileName');
      
      // Copy file
      final sourceFile = File(imagePath);
      final targetFile = File(customPath);
      await sourceFile.copy(targetFile.path);

      // Save preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_backgroundTypeKey, _typeCustom);
      await prefs.setString(_backgroundKey, customPath);
    } catch (e) {
      print('Error setting custom background: $e');
    }
  }

  // Remove background (use pure black)
  Future<void> removeBackground() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_backgroundTypeKey, _typeNone);
      await prefs.remove(_backgroundKey);
    } catch (e) {
      print('Error removing background: $e');
    }
  }

  // Get background image path
  Future<String?> getBackgroundImagePath() async {
    final backgroundInfo = await getCurrentBackground();
    
    if (backgroundInfo.type == _typeNone) {
      return null; // No background
    }
    
    if (backgroundInfo.type == _typeDefault) {
      return backgroundInfo.path;
    }
    
    if (backgroundInfo.type == _typeCustom) {
      return backgroundInfo.path;
    }
    
    return null;
  }

  // Check if background exists
  Future<bool> backgroundExists(String imagePath) async {
    try {
      if (imagePath.startsWith('assets/')) {
        // For asset images, we assume they exist
        return true;
      } else {
        // For custom images, check if file exists
        final file = File(imagePath);
        return await file.exists();
      }
    } catch (e) {
      return false;
    }
  }

  // Get custom backgrounds
  Future<List<String>> getCustomBackgrounds() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backgroundDir = Directory(path.join(appDir.path, 'backgrounds'));
      
      if (!await backgroundDir.exists()) {
        return [];
      }
      
      final files = await backgroundDir.list().toList();
      return files
          .where((file) => file is File && _isImageFile(file.path))
          .map((file) => file.path)
          .toList();
    } catch (e) {
      print('Error getting custom backgrounds: $e');
      return [];
    }
  }

  // Check if file is an image
  bool _isImageFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension);
  }

  // Delete custom background
  Future<void> deleteCustomBackground(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting custom background: $e');
    }
  }

  // Clear all custom backgrounds
  Future<void> clearAllCustomBackgrounds() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backgroundDir = Directory(path.join(appDir.path, 'backgrounds'));
      
      if (await backgroundDir.exists()) {
        await backgroundDir.delete(recursive: true);
      }
    } catch (e) {
      print('Error clearing custom backgrounds: $e');
    }
  }

  // Get background info for display
  Future<BackgroundDisplayInfo> getBackgroundDisplayInfo() async {
    final backgroundInfo = await getCurrentBackground();
    final defaultBackgrounds = getDefaultBackgrounds();
    final customBackgrounds = await getCustomBackgrounds();
    
    return BackgroundDisplayInfo(
      currentBackground: backgroundInfo,
      defaultBackgrounds: defaultBackgrounds,
      customBackgrounds: customBackgrounds,
    );
  }
}

// Background info data class
class BackgroundInfo {
  final String type;
  final String path;
  final bool isCustom;

  BackgroundInfo({
    required this.type,
    required this.path,
    required this.isCustom,
  });
}

// Background display info data class
class BackgroundDisplayInfo {
  final BackgroundInfo currentBackground;
  final List<String> defaultBackgrounds;
  final List<String> customBackgrounds;

  BackgroundDisplayInfo({
    required this.currentBackground,
    required this.defaultBackgrounds,
    required this.customBackgrounds,
  });
}
