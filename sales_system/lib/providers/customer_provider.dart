import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerService _customerService = CustomerService();
  
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<Customer> get customers => _filteredCustomers;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  // Load all customers
  Future<void> loadCustomers() async {
    print('loadCustomers called');
    _isLoading = true;
    notifyListeners();

    try {
      print('Loading customers...');
      _customers = await _customerService.getAllCustomers();
      _filteredCustomers = List.from(_customers);
      print('Loaded ${_customers.length} customers');
      print('Filtered customers: ${_filteredCustomers.length}');
    } catch (e) {
      if (kDebugMode) {
        print('Error loading customers: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search customers
  void searchCustomers(String query) {
    _searchQuery = query;
    
    if (query.isEmpty) {
      _filteredCustomers = List.from(_customers);
    } else {
      _filteredCustomers = _customers.where((customer) {
        return customer.name.toLowerCase().contains(query.toLowerCase()) ||
               customer.email.toLowerCase().contains(query.toLowerCase()) ||
               customer.company.toLowerCase().contains(query.toLowerCase()) ||
               customer.phone.contains(query);
      }).toList();
    }
    
    notifyListeners();
  }

  // Add new customer
  Future<Customer?> addCustomer(Customer customer) async {
    try {
      print('Adding customer: ${customer.name}');
      final id = await _customerService.createCustomer(customer);
      print('Customer created with ID: $id');
      if (id > 0) {
        final newCustomer = customer.copyWith(id: id);
        _customers.add(newCustomer);
        print('Customer added to local list. Total customers: ${_customers.length}');
        searchCustomers(_searchQuery); // Refresh filtered list
        print('After searchCustomers - Filtered customers: ${_filteredCustomers.length}');
        return newCustomer;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding customer: $e');
      }
      return null;
    }
  }

  // Update customer
  Future<bool> updateCustomer(Customer customer) async {
    try {
      final result = await _customerService.updateCustomer(customer);
      if (result > 0) {
        final index = _customers.indexWhere((c) => c.id == customer.id);
        if (index != -1) {
          _customers[index] = customer;
          searchCustomers(_searchQuery); // Refresh filtered list
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating customer: $e');
      }
      return false;
    }
  }

  // Delete customer
  Future<bool> deleteCustomer(int customerId) async {
    try {
      final result = await _customerService.deleteCustomer(customerId);
      if (result > 0) {
        _customers.removeWhere((c) => c.id == customerId);
        searchCustomers(_searchQuery); // Refresh filtered list
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting customer: $e');
      }
      return false;
    }
  }

  // Get customer by ID
  Customer? getCustomerById(int id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get customers with balance
  Future<List<Customer>> getCustomersWithBalance() async {
    try {
      return await _customerService.getCustomersWithBalance();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting customers with balance: $e');
      }
      return [];
    }
  }

  // Get top customers
  Future<List<Customer>> getTopCustomers({int limit = 10}) async {
    try {
      return await _customerService.getTopCustomers(limit: limit);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting top customers: $e');
      }
      return [];
    }
  }

  // Get customer statistics
  Map<String, dynamic> getCustomerStats() {
    if (_customers.isEmpty) {
      return {
        'totalCustomers': 0,
        'totalSpent': 0.0,
        'averageSpent': 0.0,
        'customersWithBalance': 0,
        'totalBalance': 0.0,
      };
    }

    final totalSpent = _customers.fold(0.0, (sum, customer) => sum + customer.totalSpent);
    final customersWithBalance = _customers.where((c) => c.balance > 0).length;
    final totalBalance = _customers.fold(0.0, (sum, customer) => sum + customer.balance);

    return {
      'totalCustomers': _customers.length,
      'totalSpent': totalSpent,
      'averageSpent': totalSpent / _customers.length,
      'customersWithBalance': customersWithBalance,
      'totalBalance': totalBalance,
    };
  }

  // Refresh customer data
  Future<void> refreshCustomers() async {
    await loadCustomers();
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    _filteredCustomers = List.from(_customers);
    notifyListeners();
  }
}