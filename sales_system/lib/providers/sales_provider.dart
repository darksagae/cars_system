import 'package:flutter/foundation.dart';

class SalesProvider extends ChangeNotifier {
  // Current selected tab index
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  // Navigation methods
  void navigateToDashboard() {
    _currentIndex = 0;
    notifyListeners();
  }

  void navigateToCustomers() {
    _currentIndex = 1;
    notifyListeners();
  }

  void navigateToInvoices() {
    _currentIndex = 2;
    notifyListeners();
  }

  void navigateToPayments() {
    _currentIndex = 3;
    notifyListeners();
  }

  void navigateToProducts() {
    _currentIndex = 4;
    notifyListeners();
  }

  void navigateToDemandLetters() {
    _currentIndex = 5;
    notifyListeners();
  }

  void navigateToReminders() {
    _currentIndex = 6;
    notifyListeners();
  }

  void navigateToReports() {
    _currentIndex = 7;
    notifyListeners();
  }

  void navigateToSettings() {
    _currentIndex = 8;
    notifyListeners();
  }
}