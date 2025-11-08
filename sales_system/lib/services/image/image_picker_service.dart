import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImagePickerService {
  static final ImagePickerService _instance = ImagePickerService._internal();
  factory ImagePickerService() => _instance;
  ImagePickerService._internal();

  final ImagePicker _picker = ImagePicker();

  // Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null) {
        return File(image.path);
      }
      
      if (kDebugMode) {
        print('No image selected from camera');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error picking image from camera: $e');
      }
      return null;
    }
  }

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null) {
        return File(image.path);
      }
      
      if (kDebugMode) {
        print('No image selected from gallery');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error picking image from gallery: $e');
      }
      return null;
    }
  }

  // Pick multiple images from gallery
  Future<List<File>> pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      return images.map((image) => File(image.path)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error picking multiple images: $e');
      }
      return [];
    }
  }

  // Save image to app directory
  Future<File?> saveImageToAppDirectory(File imageFile, String fileName) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory imagesDir = Directory('${appDir.path}/images');
      
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      final String newPath = '${imagesDir.path}/$fileName';
      final File savedFile = await imageFile.copy(newPath);
      
      if (kDebugMode) {
        print('Image saved to: ${savedFile.path}');
      }
      return savedFile;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving image: $e');
      }
      return null;
    }
  }

  // Get image as bytes
  Future<Uint8List?> getImageBytes(File imageFile) async {
    try {
      return await imageFile.readAsBytes();
    } catch (e) {
      if (kDebugMode) {
        print('Error reading image bytes: $e');
      }
      return null;
    }
  }

  // Convert image to base64
  Future<String?> imageToBase64(File imageFile) async {
    try {
      final Uint8List? bytes = await getImageBytes(imageFile);
      if (bytes != null) {
      return base64Encode(bytes);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error converting image to base64: $e');
      }
      return null;
    }
  }

  // Convert base64 to image file
  Future<File?> base64ToImageFile(String base64String, String fileName) async {
    try {
      final Uint8List bytes = base64Decode(base64String);
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory imagesDir = Directory('${appDir.path}/images');
      
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      final String filePath = '${imagesDir.path}/$fileName';
      final File imageFile = File(filePath);
      await imageFile.writeAsBytes(bytes);
      
      if (kDebugMode) {
        print('Base64 image saved to: ${imageFile.path}');
      }
      return imageFile;
    } catch (e) {
      if (kDebugMode) {
        print('Error converting base64 to image: $e');
      }
      return null;
    }
  }

  // Delete image file
  Future<bool> deleteImageFile(File imageFile) async {
    try {
      if (await imageFile.exists()) {
        await imageFile.delete();
        if (kDebugMode) {
          print('Image deleted: ${imageFile.path}');
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting image: $e');
      }
      return false;
    }
  }

  // Get all images in app directory
  Future<List<File>> getAllImages() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory imagesDir = Directory('${appDir.path}/images');
      
      if (!await imagesDir.exists()) {
        return [];
      }
      
      final List<FileSystemEntity> files = await imagesDir.list().toList();
      return files.whereType<File>().toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all images: $e');
      }
      return [];
    }
  }

  // Clear all images from app directory
  Future<bool> clearAllImages() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory imagesDir = Directory('${appDir.path}/images');
      
      if (await imagesDir.exists()) {
        await imagesDir.delete(recursive: true);
        await imagesDir.create(recursive: true);
        if (kDebugMode) {
          print('All images cleared from app directory');
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing images: $e');
      }
      return false;
    }
  }

  // Get image file size
  Future<int> getImageFileSize(File imageFile) async {
    try {
      return await imageFile.length();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting image file size: $e');
      }
      return 0;
    }
  }

  // Check if image file exists
  Future<bool> imageFileExists(File imageFile) async {
    try {
      return await imageFile.exists();
    } catch (e) {
      if (kDebugMode) {
        print('Error checking image file existence: $e');
      }
      return false;
    }
  }

  // Get image file extension
  String getImageFileExtension(File imageFile) {
    final String fileName = imageFile.path.split('/').last;
    final int lastDotIndex = fileName.lastIndexOf('.');
    
    if (lastDotIndex != -1 && lastDotIndex < fileName.length - 1) {
      return fileName.substring(lastDotIndex + 1).toLowerCase();
    }
    
    return '';
  }

  // Validate image file extension
  bool isValidImageExtension(String extension) {
    const List<String> validExtensions = [
      'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'
    ];
    
    return validExtensions.contains(extension.toLowerCase());
  }

  // Get image file info
  Future<Map<String, dynamic>> getImageFileInfo(File imageFile) async {
    try {
      final bool exists = await imageFileExists(imageFile);
      if (!exists) {
        return {'error': 'File does not exist'};
      }
      
      final int size = await getImageFileSize(imageFile);
      final String extension = getImageFileExtension(imageFile);
      
      return {
        'path': imageFile.path,
        'name': imageFile.path.split('/').last,
        'size': size,
        'extension': extension,
        'isValid': isValidImageExtension(extension),
        'exists': true,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting image file info: $e');
      }
      return {'error': e.toString()};
    }
  }
}
