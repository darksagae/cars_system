import 'package:flutter/foundation.dart';
import '../models/invoice.dart';
import '../services/invoice_service.dart';
import '../services/customer_service.dart';

class InvoiceProvider extends ChangeNotifier {
  final InvoiceService _invoiceService = InvoiceService();
  final CustomerService _customerService = CustomerService();
  
  List<Invoice> _invoices = [];
  List<Invoice> _filteredInvoices = [];
  bool _isLoading = false;
  String _searchQuery = '';
  InvoiceStatus? _filterStatus;

  List<Invoice> get invoices => _filteredInvoices;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  InvoiceStatus? get filterStatus => _filterStatus;

  // Load all invoices
  Future<void> loadInvoices() async {
    _isLoading = true;
    notifyListeners();

    try {
      _invoices = await _invoiceService.getAllInvoices();
      _filteredInvoices = List.from(_invoices);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading invoices: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search invoices
  void searchInvoices(String query) {
    _searchQuery = query;
    
    if (query.isEmpty) {
      _filteredInvoices = _filterByStatus(_invoices);
    } else {
      final searchResults = _invoices.where((invoice) {
        return invoice.invoiceNumber.toLowerCase().contains(query.toLowerCase()) ||
               invoice.customerId.toString().contains(query) ||
               invoice.totalAmount.toString().contains(query);
      }).toList();
      _filteredInvoices = _filterByStatus(searchResults);
    }
    
    notifyListeners();
  }

  // Filter by status
  void filterByStatus(InvoiceStatus status) {
    _filterStatus = status;
    _filteredInvoices = _invoices.where((invoice) => invoice.status == status).toList();
    notifyListeners();
  }

  // Helper method to filter by status
  List<Invoice> _filterByStatus(List<Invoice> invoices) {
    if (_filterStatus == null) return invoices;
    return invoices.where((invoice) => invoice.status == _filterStatus).toList();
  }

  // Add new invoice
  Future<bool> addInvoice(Invoice invoice) async {
    try {
      final id = await _invoiceService.createInvoice(invoice);
      if (id > 0) {
        final newInvoice = invoice.copyWith(id: id);
        _invoices.add(newInvoice);
        
        // Update customer statistics
        await _customerService.updateCustomerStats(invoice.customerId);
        
        searchInvoices(_searchQuery); // Refresh filtered list
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding invoice: $e');
      }
      return false;
    }
  }

  // Update invoice
  Future<bool> updateInvoice(Invoice invoice) async {
    try {
      final result = await _invoiceService.updateInvoice(invoice);
      if (result > 0) {
        final index = _invoices.indexWhere((i) => i.id == invoice.id);
        if (index != -1) {
          _invoices[index] = invoice;
          searchInvoices(_searchQuery); // Refresh filtered list
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating invoice: $e');
      }
      return false;
    }
  }

  // Delete invoice
  Future<bool> deleteInvoice(int invoiceId) async {
    try {
      final result = await _invoiceService.deleteInvoice(invoiceId);
      if (result > 0) {
        _invoices.removeWhere((i) => i.id == invoiceId);
        searchInvoices(_searchQuery); // Refresh filtered list
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting invoice: $e');
      }
      return false;
    }
  }

  // Delete all invoices
  Future<void> deleteAllInvoices() async {
    try {
      await _invoiceService.deleteAllInvoices();
      _invoices.clear();
      _filteredInvoices.clear();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting all invoices: $e');
      }
    }
  }

  // Get invoice by ID
  Invoice? getInvoiceById(int id) {
    try {
      return _invoices.firstWhere((i) => i.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get invoices by customer
  Future<List<Invoice>> getInvoicesByCustomer(int customerId) async {
    try {
      return await _invoiceService.getInvoicesByCustomer(customerId);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting invoices by customer: $e');
      }
      return [];
    }
  }

  // Get overdue invoices
  Future<List<Invoice>> getOverdueInvoices() async {
    try {
      return await _invoiceService.getOverdueInvoices();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting overdue invoices: $e');
      }
      return [];
    }
  }

  // Get invoice statistics
  Future<Map<String, dynamic>> getInvoiceStats() async {
    try {
      return await _invoiceService.getInvoiceStats();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting invoice stats: $e');
      }
      return {
        'totalInvoices': 0,
        'totalAmount': 0.0,
        'paidAmount': 0.0,
        'balanceAmount': 0.0,
        'statusBreakdown': [],
      };
    }
  }

  // Generate next invoice number
  Future<String> generateInvoiceNumber() async {
    try {
      return await _invoiceService.generateInvoiceNumber();
    } catch (e) {
      if (kDebugMode) {
        print('Error generating invoice number: $e');
      }
      return 'INV-000001';
    }
  }

  // Update invoice status
  Future<bool> updateInvoiceStatus(int invoiceId, InvoiceStatus status) async {
    try {
      final result = await _invoiceService.updateInvoiceStatus(invoiceId, status);
      if (result > 0) {
        final index = _invoices.indexWhere((i) => i.id == invoiceId);
        if (index != -1) {
          _invoices[index] = _invoices[index].copyWith(status: status);
          searchInvoices(_searchQuery); // Refresh filtered list
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating invoice status: $e');
      }
      return false;
    }
  }

  // Get invoice statistics
  Map<String, dynamic> getLocalInvoiceStats() {
    if (_invoices.isEmpty) {
      return {
        'totalInvoices': 0,
        'totalAmount': 0.0,
        'paidAmount': 0.0,
        'balanceAmount': 0.0,
        'draftCount': 0,
        'sentCount': 0,
        'paidCount': 0,
        'overdueCount': 0,
      };
    }

    final totalAmount = _invoices.fold(0.0, (sum, invoice) => sum + invoice.totalAmount);
    final paidAmount = _invoices.fold(0.0, (sum, invoice) => sum + invoice.paidAmount);
    final balanceAmount = _invoices.fold(0.0, (sum, invoice) => sum + invoice.balanceAmount);

    final draftCount = _invoices.where((i) => i.status == InvoiceStatus.draft).length;
    final sentCount = _invoices.where((i) => i.status == InvoiceStatus.sent).length;
    final paidCount = _invoices.where((i) => i.status == InvoiceStatus.paid).length;
    final overdueCount = _invoices.where((i) => i.status == InvoiceStatus.overdue).length;

    return {
      'totalInvoices': _invoices.length,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'balanceAmount': balanceAmount,
      'draftCount': draftCount,
      'sentCount': sentCount,
      'paidCount': paidCount,
      'overdueCount': overdueCount,
    };
  }

  // Refresh invoice data
  Future<void> refreshInvoices() async {
    await loadInvoices();
  }

  // Clear search and filters
  void clearFilters() {
    _searchQuery = '';
    _filterStatus = null;
    _filteredInvoices = List.from(_invoices);
    notifyListeners();
  }
}