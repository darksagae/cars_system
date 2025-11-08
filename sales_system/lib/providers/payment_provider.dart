import 'package:flutter/foundation.dart';
import '../models/payment.dart';
import '../models/invoice.dart';
import '../services/payment_service.dart';
import '../services/invoice_service.dart';
import '../services/customer_service.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _paymentService = PaymentService();
  final InvoiceService _invoiceService = InvoiceService();
  final CustomerService _customerService = CustomerService();
  
  List<Payment> _payments = [];
  List<Payment> _filteredPayments = [];
  bool _isLoading = false;
  String _searchQuery = '';
  PaymentStatus? _filterStatus;
  PaymentMethod? _filterMethod;

  List<Payment> get payments => _filteredPayments;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  PaymentStatus? get filterStatus => _filterStatus;
  PaymentMethod? get filterMethod => _filterMethod;

  // Load all payments
  Future<void> loadPayments() async {
    _isLoading = true;
    notifyListeners();

    try {
      _payments = await _paymentService.getAllPayments();
      _filteredPayments = List.from(_payments);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading payments: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search payments
  void searchPayments(String query) {
    _searchQuery = query;
    
    if (query.isEmpty) {
      _filteredPayments = _filterByStatusAndMethod(_payments);
    } else {
      final searchResults = _payments.where((payment) {
        return payment.invoiceId.toString().contains(query) ||
               payment.amount.toString().contains(query) ||
               (payment.referenceNumber?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
               (payment.notes?.toLowerCase().contains(query.toLowerCase()) ?? false);
      }).toList();
      _filteredPayments = _filterByStatusAndMethod(searchResults);
    }
    
    notifyListeners();
  }

  // Filter by status
  void filterByStatus(PaymentStatus status) {
    _filterStatus = status;
    _filteredPayments = _payments.where((payment) => payment.status == status).toList();
    notifyListeners();
  }

  // Filter by method
  void filterByMethod(PaymentMethod method) {
    _filterMethod = method;
    _filteredPayments = _payments.where((payment) => payment.method == method).toList();
    notifyListeners();
  }

  // Clear status filter
  void clearStatusFilter() {
    _filterStatus = null;
    searchPayments(_searchQuery); // Refresh filtered list
  }

  // Clear method filter
  void clearMethodFilter() {
    _filterMethod = null;
    searchPayments(_searchQuery); // Refresh filtered list
  }

  // Helper method to filter by status and method
  List<Payment> _filterByStatusAndMethod(List<Payment> payments) {
    List<Payment> filtered = payments;
    
    if (_filterStatus != null) {
      filtered = filtered.where((payment) => payment.status == _filterStatus).toList();
    }
    
    if (_filterMethod != null) {
      filtered = filtered.where((payment) => payment.method == _filterMethod).toList();
    }
    
    return filtered;
  }

  // Add new payment
  Future<bool> addPayment(Payment payment) async {
    try {
      final id = await _paymentService.createPayment(payment);
      if (id > 0) {
        final newPayment = payment.copyWith(id: id);
        _payments.add(newPayment);
        
        // Update invoice balance
        if (payment.invoiceId != null) {
          await _updateInvoiceBalance(payment.invoiceId!, payment.amount);
          
          // Get invoice to update customer statistics
          final invoice = await _invoiceService.getInvoiceById(payment.invoiceId!);
          if (invoice != null) {
            await _customerService.updateCustomerStats(invoice.customerId);
          }
        }
        
        searchPayments(_searchQuery); // Refresh filtered list
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding payment: $e');
      }
      return false;
    }
  }

  // Update payment
  Future<bool> updatePayment(Payment payment) async {
    try {
      final oldPayment = _payments.firstWhere((p) => p.id == payment.id);
      final amountDifference = payment.amount - oldPayment.amount;
      
      final result = await _paymentService.updatePayment(payment);
      if (result > 0) {
        final index = _payments.indexWhere((p) => p.id == payment.id);
        if (index != -1) {
          _payments[index] = payment;
          
          // Update invoice balance if amount changed
          if (amountDifference != 0 && payment.invoiceId != null) {
            await _updateInvoiceBalance(payment.invoiceId!, amountDifference);
          }
          
          searchPayments(_searchQuery); // Refresh filtered list
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating payment: $e');
      }
      return false;
    }
  }

  // Delete payment
  Future<bool> deletePayment(int paymentId) async {
    try {
      // Get payment from database first to ensure we have the latest data
      final payment = await _paymentService.getPaymentById(paymentId);
      if (payment == null) {
        if (kDebugMode) {
          print('Payment with ID $paymentId not found in database');
        }
        // Still try to remove from local list if it exists
        _payments.removeWhere((p) => p.id == paymentId);
        searchPayments(_searchQuery);
        return false;
      }
      
      // Delete from database
      final result = await _paymentService.deletePayment(paymentId);
      if (result > 0) {
        // Remove from local list
        _payments.removeWhere((p) => p.id == paymentId);
        
        // Update invoice balance (subtract the deleted payment amount)
        // Only update if invoice exists
        if (payment.invoiceId != null && payment.invoiceId! > 0) {
          try {
            await _updateInvoiceBalance(payment.invoiceId!, -payment.amount);
          } catch (e) {
            // If invoice doesn't exist, continue with deletion anyway
            // This handles orphaned payments gracefully
            if (kDebugMode) {
              print('Warning: Could not update invoice balance for deleted payment: $e');
            }
          }
        }
        
        // Reload payments to ensure consistency
        await loadPayments();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting payment: $e');
      }
      // Even if there's an error, try to reload payments to sync state
      await loadPayments();
      return false;
    }
  }

  // Get payment by ID
  Payment? getPaymentById(int id) {
    try {
      return _payments.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get payments by invoice
  Future<List<Payment>> getPaymentsByInvoice(int invoiceId) async {
    try {
      return await _paymentService.getPaymentsByInvoice(invoiceId);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting payments by invoice: $e');
      }
      return [];
    }
  }

  // Get payment statistics
  Future<Map<String, dynamic>> getPaymentStats() async {
    try {
      return await _paymentService.getPaymentStats();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting payment stats: $e');
      }
      return {
        'totalPayments': 0,
        'totalAmount': 0.0,
        'statusBreakdown': [],
        'methodBreakdown': [],
      };
    }
  }

  // Get local payment statistics
  Map<String, dynamic> getLocalPaymentStats() {
    if (_payments.isEmpty) {
      return {
        'totalPayments': 0,
        'totalAmount': 0.0,
        'completedCount': 0,
        'pendingCount': 0,
        'failedCount': 0,
        'cashCount': 0,
        'cardCount': 0,
        'bankTransferCount': 0,
        'otherCount': 0,
      };
    }

    final totalAmount = _payments.fold(0.0, (sum, payment) => sum + payment.amount);
    final completedCount = _payments.where((p) => p.status == PaymentStatus.completed).length;
    final pendingCount = _payments.where((p) => p.status == PaymentStatus.pending).length;
    final failedCount = _payments.where((p) => p.status == PaymentStatus.failed).length;
    final cashCount = _payments.where((p) => p.method == PaymentMethod.cash).length;
    final cardCount = _payments.where((p) => p.method == PaymentMethod.credit_card || p.method == PaymentMethod.debitCard).length;
    final bankTransferCount = _payments.where((p) => p.method == PaymentMethod.bank_transfer).length;
    final otherCount = _payments.where((p) => p.method == PaymentMethod.other).length;

    return {
      'totalPayments': _payments.length,
      'totalAmount': totalAmount,
      'completedCount': completedCount,
      'pendingCount': pendingCount,
      'failedCount': failedCount,
      'cashCount': cashCount,
      'cardCount': cardCount,
      'bankTransferCount': bankTransferCount,
      'otherCount': otherCount,
    };
  }

  // Update invoice balance
  Future<void> _updateInvoiceBalance(int invoiceId, double amountChange) async {
    try {
      final invoice = await _invoiceService.getInvoiceById(invoiceId);
      if (invoice != null) {
        final newPaidAmount = invoice.paidAmount + amountChange;
        final newBalanceAmount = invoice.totalAmount - newPaidAmount;
        
        final updatedInvoice = invoice.copyWith(
          paidAmount: newPaidAmount,
          balanceAmount: newBalanceAmount,
        );
        
        await _invoiceService.updateInvoice(updatedInvoice);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating invoice balance: $e');
      }
    }
  }

  // Refresh payment data
  Future<void> refreshPayments() async {
    await loadPayments();
  }

  // Clear search and filters
  void clearFilters() {
    _searchQuery = '';
    _filterStatus = null;
    _filterMethod = null;
    _filteredPayments = List.from(_payments);
    notifyListeners();
  }

  // Get overdue payments
  Future<List<Payment>> getOverduePayments() async {
    try {
      return await _paymentService.getOverduePayments();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting overdue payments: $e');
      }
      return [];
    }
  }

  // Get recent payments
  Future<List<Payment>> getRecentPayments({int limit = 10}) async {
    try {
      return await _paymentService.getRecentPayments(limit: limit);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting recent payments: $e');
      }
      return [];
    }
  }
}