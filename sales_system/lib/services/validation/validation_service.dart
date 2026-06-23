import 'package:flutter/material.dart';

class ValidationService {
  static final ValidationService _instance = ValidationService._internal();
  factory ValidationService() => _instance;
  ValidationService._internal();

  // Email validation
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  // Phone number validation (Uganda format)
  static bool isValidUgandaPhone(String phone) {
    if (phone.isEmpty) return false;
    
    // Remove any non-numeric characters
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Check if it's a valid Uganda phone number
    if (cleanPhone.startsWith('256')) {
      // International format: 256XXXXXXXXX
      return cleanPhone.length == 12;
    } else if (cleanPhone.startsWith('0')) {
      // Local format: 0XXXXXXXXX
      return cleanPhone.length == 10;
    }
    
    return false;
  }

  // Name validation
  static bool isValidName(String name) {
    if (name.isEmpty) return false;
    if (name.length < 2) return false;
    if (name.length > 50) return false;
    
    // Check if name contains only letters, spaces, and common punctuation
    final nameRegex = RegExp(r'^[a-zA-Z\s\'-]+$');
    return nameRegex.hasMatch(name);
  }

  // Vehicle VIN validation
  static bool isValidVIN(String vin) {
    if (vin.isEmpty) return false;
    if (vin.length != 17) return false;
    
    // VIN should not contain I, O, or Q
    final vinRegex = RegExp(r'^[A-HJ-NPR-Z0-9]{17}$');
    return vinRegex.hasMatch(vin.toUpperCase());
  }

  // Price validation
  static bool isValidPrice(String price) {
    if (price.isEmpty) return false;
    
    final priceValue = double.tryParse(price);
    if (priceValue == null) return false;
    if (priceValue < 0) return false;
    if (priceValue > 999999999) return false; // Max 999 million
    
    return true;
  }

  // Year validation
  static bool isValidYear(String year) {
    if (year.isEmpty) return false;
    
    final yearValue = int.tryParse(year);
    if (yearValue == null) return false;
    
    final currentYear = DateTime.now().year;
    if (yearValue < 1900) return false;
    if (yearValue > currentYear + 1) return false; // Allow next year for new models
    
    return true;
  }

  // Mileage validation
  static bool isValidMileage(String mileage) {
    if (mileage.isEmpty) return false;
    
    final mileageValue = int.tryParse(mileage);
    if (mileageValue == null) return false;
    if (mileageValue < 0) return false;
    if (mileageValue > 999999) return false; // Max 999,999 km
    
    return true;
  }

  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Email validation with custom message
  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Email is required';
    }
    if (!isValidEmail(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // Phone validation with custom message
  static String? validatePhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return 'Phone number is required';
    }
    if (!isValidUgandaPhone(phone)) {
      return 'Please enter a valid Uganda phone number';
    }
    return null;
  }

  // Name validation with custom message
  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Name is required';
    }
    if (!isValidName(name)) {
      return 'Name must be 2-50 characters and contain only letters';
    }
    return null;
  }

  // VIN validation with custom message
  static String? validateVIN(String? vin) {
    if (vin == null || vin.trim().isEmpty) {
      return 'VIN is required';
    }
    if (!isValidVIN(vin)) {
      return 'VIN must be 17 characters and contain only letters and numbers (no I, O, Q)';
    }
    return null;
  }

  // Price validation with custom message
  static String? validatePrice(String? price) {
    if (price == null || price.trim().isEmpty) {
      return 'Price is required';
    }
    if (!isValidPrice(price)) {
      return 'Please enter a valid price (0 - 999,999,999)';
    }
    return null;
  }

  // Year validation with custom message
  static String? validateYear(String? year) {
    if (year == null || year.trim().isEmpty) {
      return 'Year is required';
    }
    if (!isValidYear(year)) {
      return 'Please enter a valid year (1900 - ${DateTime.now().year + 1})';
    }
    return null;
  }

  // Mileage validation with custom message
  static String? validateMileage(String? mileage) {
    if (mileage == null || mileage.trim().isEmpty) {
      return 'Mileage is required';
    }
    if (!isValidMileage(mileage)) {
      return 'Please enter a valid mileage (0 - 999,999 km)';
    }
    return null;
  }

  // Password validation
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Date validation
  static String? validateDate(DateTime? date, String fieldName) {
    if (date == null) {
      return '$fieldName is required';
    }
    if (date.isAfter(DateTime.now())) {
      return '$fieldName cannot be in the future';
    }
    return null;
  }

  // Future date validation
  static String? validateFutureDate(DateTime? date, String fieldName) {
    if (date == null) {
      return '$fieldName is required';
    }
    if (date.isBefore(DateTime.now())) {
      return '$fieldName cannot be in the past';
    }
    return null;
  }

  // Number validation
  static String? validateNumber(String? value, String fieldName, {double? min, double? max}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    final number = double.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }
    
    if (min != null && number < min) {
      return '$fieldName must be at least $min';
    }
    
    if (max != null && number > max) {
      return '$fieldName must be at most $max';
    }
    
    return null;
  }

  // Integer validation
  static String? validateInteger(String? value, String fieldName, {int? min, int? max}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    final number = int.tryParse(value);
    if (number == null) {
      return 'Please enter a valid integer';
    }
    
    if (min != null && number < min) {
      return '$fieldName must be at least $min';
    }
    
    if (max != null && number > max) {
      return '$fieldName must be at most $max';
    }
    
    return null;
  }

  // URL validation
  static String? validateURL(String? url) {
    if (url == null || url.trim().isEmpty) {
      return null; // URL is optional
    }
    
    final urlRegex = RegExp(r'^https?:\/\/[^\s/$.?#].[^\s]*$');
    if (!urlRegex.hasMatch(url)) {
      return 'Please enter a valid URL';
    }
    return null;
  }

  // Credit card validation (basic)
  static bool isValidCreditCard(String cardNumber) {
    if (cardNumber.isEmpty) return false;
    
    // Remove spaces and dashes
    String cleanNumber = cardNumber.replaceAll(RegExp(r'[\s-]'), '');
    
    // Check if it's all digits and proper length
    if (!RegExp(r'^\d{13,19}$').hasMatch(cleanNumber)) return false;
    
    // Luhn algorithm validation
    int sum = 0;
    bool alternate = false;
    
    for (int i = cleanNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cleanNumber[i]);
      
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }
      
      sum += digit;
      alternate = !alternate;
    }
    
    return sum % 10 == 0;
  }

  // Show validation error dialog
  static void showValidationError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Validation Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Show validation success message
  static void showValidationSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
