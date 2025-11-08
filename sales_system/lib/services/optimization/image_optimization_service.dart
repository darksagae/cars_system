import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageOptimizationService {
  static final ImageOptimizationService _instance = ImageOptimizationService._internal();
  factory ImageOptimizationService() => _instance;
  ImageOptimizationService._internal();

  // Image quality settings
  static const int _maxWidth = 1920;
  static const int _maxHeight = 1080;
  static const int _thumbnailWidth = 300;
  static const int _thumbnailHeight = 300;
  static const int _quality = 85;

  // Optimize image file
  Future<File> optimizeImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final optimizedBytes = await _optimizeImageBytes(bytes);
      
      final optimizedFile = await _saveOptimizedImage(optimizedBytes, imageFile.path);
      return optimizedFile;
    } catch (e) {
      print('Error optimizing image: $e');
      return imageFile; // Return original if optimization fails
    }
  }

  // Optimize image bytes
  Future<Uint8List> _optimizeImageBytes(Uint8List bytes) async {
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;

    // Resize if too large
    img.Image resizedImage = image;
    if (image.width > _maxWidth || image.height > _maxHeight) {
      resizedImage = img.copyResize(
        image,
        width: _maxWidth,
        height: _maxHeight,
        maintainAspect: true,
      );
    }

    // Encode with quality settings
    final optimizedBytes = img.encodeJpg(resizedImage, quality: _quality);
    return Uint8List.fromList(optimizedBytes);
  }

  // Save optimized image
  Future<File> _saveOptimizedImage(Uint8List bytes, String originalPath) async {
    final directory = Directory(path.dirname(originalPath));
    final fileName = path.basenameWithoutExtension(originalPath);
    final optimizedPath = path.join(directory.path, '${fileName}_optimized.jpg');
    
    final file = File(optimizedPath);
    await file.writeAsBytes(bytes);
    return file;
  }

  // Create thumbnail
  Future<File> createThumbnail(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return imageFile;

      final thumbnail = img.copyResize(
        image,
        width: _thumbnailWidth,
        height: _thumbnailHeight,
        maintainAspect: true,
      );

      final thumbnailBytes = img.encodeJpg(thumbnail, quality: 80);
      
      final directory = Directory(path.dirname(imageFile.path));
      final fileName = path.basenameWithoutExtension(imageFile.path);
      final thumbnailPath = path.join(directory.path, '${fileName}_thumb.jpg');
      
      final thumbnailFile = File(thumbnailPath);
      await thumbnailFile.writeAsBytes(thumbnailBytes);
      return thumbnailFile;
    } catch (e) {
      print('Error creating thumbnail: $e');
      return imageFile;
    }
  }

  // Get image info
  Future<ImageInfo> getImageInfo(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        return ImageInfo(
          width: 0,
          height: 0,
          size: bytes.length,
          format: 'unknown',
        );
      }

      return ImageInfo(
        width: image.width,
        height: image.height,
        size: bytes.length,
        format: _getImageFormat(bytes),
      );
    } catch (e) {
      print('Error getting image info: $e');
      return ImageInfo(
        width: 0,
        height: 0,
        size: 0,
        format: 'unknown',
      );
    }
  }

  // Get image format
  String _getImageFormat(Uint8List bytes) {
    if (bytes.length < 4) return 'unknown';
    
    // Check for common image formats
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) return 'JPEG';
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) return 'PNG';
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) return 'GIF';
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) return 'BMP';
    
    return 'unknown';
  }

  // Clean up old optimized images
  Future<void> cleanupOldImages() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final imageDir = Directory(path.join(documentsDir.path, 'images'));
      
      if (!await imageDir.exists()) return;
      
      final files = await imageDir.list().toList();
      final now = DateTime.now();
      
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          final age = now.difference(stat.modified);
          
          // Delete files older than 30 days
          if (age.inDays > 30) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      print('Error cleaning up old images: $e');
    }
  }

  // Get storage usage
  Future<StorageUsage> getStorageUsage() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final imageDir = Directory(path.join(documentsDir.path, 'images'));
      
      if (!await imageDir.exists()) {
        return StorageUsage(totalSize: 0, fileCount: 0);
      }
      
      int totalSize = 0;
      int fileCount = 0;
      
      final files = await imageDir.list().toList();
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          totalSize += stat.size;
          fileCount++;
        }
      }
      
      return StorageUsage(
        totalSize: totalSize,
        fileCount: fileCount,
      );
    } catch (e) {
      print('Error getting storage usage: $e');
      return StorageUsage(totalSize: 0, fileCount: 0);
    }
  }
}

// Image info data class
class ImageInfo {
  final int width;
  final int height;
  final int size;
  final String format;

  ImageInfo({
    required this.width,
    required this.height,
    required this.size,
    required this.format,
  });
}

// Storage usage data class
class StorageUsage {
  final int totalSize;
  final int fileCount;

  StorageUsage({
    required this.totalSize,
    required this.fileCount,
  });
}
