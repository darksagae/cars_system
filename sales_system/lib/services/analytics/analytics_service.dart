import '../invoice_service.dart';
import '../payment_service.dart';
import '../customer_service.dart';
import '../../models/invoice.dart';
import '../../models/payment.dart';
import '../../models/customer.dart';

class AnalyticsService {
  final InvoiceService _invoiceService = InvoiceService();
  final PaymentService _paymentService = PaymentService();
  final CustomerService _customerService = CustomerService();

  // Get sales analytics
  Future<Map<String, dynamic>> getSalesAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final invoices = await _invoiceService.getAllInvoices();
      final payments = await _paymentService.getAllPayments();
      final customers = await _customerService.getAllCustomers();

      // Filter by date range if provided
      List<Invoice> filteredInvoices = invoices;
      List<Payment> filteredPayments = payments;

      if (startDate != null && endDate != null) {
        final start = DateTime(startDate.year, startDate.month, startDate.day);
        final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);

        filteredInvoices = invoices.where((invoice) {
          final d = invoice.invoiceDate;
          return (d.isAtSameMomentAs(start) || d.isAfter(start)) &&
                 (d.isAtSameMomentAs(end) || d.isBefore(end));
        }).toList();

        filteredPayments = payments.where((payment) {
          final d = payment.paymentDate;
          return (d.isAtSameMomentAs(start) || d.isAfter(start)) &&
                 (d.isAtSameMomentAs(end) || d.isBefore(end));
        }).toList();
      }

      // Calculate metrics
      final totalRevenue = filteredInvoices.fold(0.0, (sum, invoice) => sum + invoice.totalAmount);
      final totalPaid = filteredPayments.fold(0.0, (sum, payment) => sum + payment.amount);
      final totalOutstanding = totalRevenue - totalPaid;
      final totalInvoices = filteredInvoices.length;
      final totalCustomers = customers.length;
      final averageInvoiceValue = totalInvoices > 0 ? totalRevenue / totalInvoices : 0.0;

      // Status breakdown
      final statusBreakdown = _calculateStatusBreakdown(filteredInvoices);
      final paymentMethodBreakdown = _calculatePaymentMethodBreakdown(filteredPayments);
      final monthlyRevenue = _calculateMonthlyRevenue(filteredInvoices);
      final topCustomers = _calculateTopCustomers(filteredInvoices, customers);

      return {
        'totalRevenue': totalRevenue,
        'totalPaid': totalPaid,
        'totalOutstanding': totalOutstanding,
        'totalInvoices': totalInvoices,
        'totalCustomers': totalCustomers,
        'averageInvoiceValue': averageInvoiceValue,
        'statusBreakdown': statusBreakdown,
        'paymentMethodBreakdown': paymentMethodBreakdown,
        'monthlyRevenue': monthlyRevenue,
        'topCustomers': topCustomers,
        'recentInvoices': filteredInvoices.take(10).toList(),
        'recentPayments': filteredPayments.take(10).toList(),
        'customers': customers,
        'stats': {
          'totalRevenue': totalRevenue,
          'totalPaid': totalPaid,
          'totalOutstanding': totalOutstanding,
          'totalInvoices': totalInvoices,
          'totalCustomers': totalCustomers,
          'averageInvoiceValue': averageInvoiceValue,
        },
      };
    } catch (e) {
      print('Error getting sales analytics: $e');
      return _getDefaultAnalytics();
    }
  }

  // Get customer analytics
  Future<Map<String, dynamic>> getCustomerAnalytics() async {
    try {
      final customers = await _customerService.getAllCustomers();
      final invoices = await _invoiceService.getAllInvoices();

      // Calculate customer metrics
      final totalCustomers = customers.length;
      final activeCustomers = customers.where((c) => c.isActive).length;
      final averageCustomerValue = customers.isNotEmpty 
          ? customers.fold(0.0, (sum, c) => sum + c.totalSpent) / customers.length 
          : 0.0;

      // Top customers by revenue
      final customerRevenue = <int, double>{};
      for (final invoice in invoices) {
        customerRevenue[invoice.customerId] = 
            (customerRevenue[invoice.customerId] ?? 0.0) + invoice.totalAmount;
      }

      final sortedCustomers = customerRevenue.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topCustomers = sortedCustomers.take(10).map((entry) {
        final customer = customers.firstWhere(
          (c) => c.id == entry.key,
          orElse: () => Customer.empty(),
        );
        return {
          'customer': customer,
          'revenue': entry.value,
        };
      }).toList();

      return {
        'totalCustomers': totalCustomers,
        'activeCustomers': activeCustomers,
        'averageCustomerValue': averageCustomerValue,
        'topCustomers': topCustomers,
        'customers': customers,
      };
    } catch (e) {
      print('Error getting customer analytics: $e');
      return {
        'totalCustomers': 0,
        'activeCustomers': 0,
        'averageCustomerValue': 0.0,
        'topCustomers': <Map<String, dynamic>>[],
        'customers': <Customer>[],
      };
    }
  }

  // Get payment analytics
  Future<Map<String, dynamic>> getPaymentAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final payments = await _paymentService.getAllPayments();

      // Filter by date range if provided
      List<Payment> filteredPayments = payments;
      if (startDate != null && endDate != null) {
        filteredPayments = payments.where((payment) {
          return payment.paymentDate.isAfter(startDate) && 
                 payment.paymentDate.isBefore(endDate);
        }).toList();
      }

      // Calculate payment metrics
      final totalPayments = filteredPayments.length;
      final totalAmount = filteredPayments.fold(0.0, (sum, payment) => sum + payment.amount);
      final averagePayment = totalPayments > 0 ? totalAmount / totalPayments : 0.0;

      // Payment method breakdown
      final paymentMethodBreakdown = _calculatePaymentMethodBreakdown(filteredPayments);
      final paymentStatusBreakdown = _calculatePaymentStatusBreakdown(filteredPayments);

      return {
        'totalPayments': totalPayments,
        'totalAmount': totalAmount,
        'averagePayment': averagePayment,
        'paymentMethodBreakdown': paymentMethodBreakdown,
        'paymentStatusBreakdown': paymentStatusBreakdown,
        'payments': filteredPayments,
      };
    } catch (e) {
      print('Error getting payment analytics: $e');
      return {
        'totalPayments': 0,
        'totalAmount': 0.0,
        'averagePayment': 0.0,
        'paymentMethodBreakdown': <String, int>{},
        'paymentStatusBreakdown': <String, int>{},
        'payments': <Payment>[],
      };
    }
  }

  // Get growth analytics
  Future<Map<String, dynamic>> getGrowthAnalytics() async {
    try {
      final invoices = await _invoiceService.getAllInvoices();
      final payments = await _paymentService.getAllPayments();
      final customers = await _customerService.getAllCustomers();

      // Calculate growth metrics
      final monthlyGrowth = _calculateMonthlyGrowth(invoices, payments, customers);
      final yearOverYearGrowth = _calculateYearOverYearGrowth(invoices, payments, customers);
      final trends = _calculateTrends(invoices, payments, customers);

      return {
        'monthlyGrowth': monthlyGrowth,
        'yearOverYearGrowth': yearOverYearGrowth,
        'trends': trends,
      };
    } catch (e) {
      print('Error getting growth analytics: $e');
      return {
        'monthlyGrowth': <Map<String, dynamic>>[],
        'yearOverYearGrowth': <String, dynamic>{},
        'trends': <String, dynamic>{},
      };
    }
  }

  // Helper methods for calculations
  Map<String, dynamic> _calculateStatusBreakdown(List<Invoice> invoices) {
    final breakdown = <String, int>{};
    for (final invoice in invoices) {
      final status = invoice.statusText;
      breakdown[status] = (breakdown[status] ?? 0) + 1;
    }
    return breakdown;
  }

  Map<String, dynamic> _calculatePaymentMethodBreakdown(List<Payment> payments) {
    final breakdown = <String, int>{};
    for (final payment in payments) {
      final method = payment.methodText;
      breakdown[method] = (breakdown[method] ?? 0) + 1;
    }
    return breakdown;
  }

  Map<String, dynamic> _calculatePaymentStatusBreakdown(List<Payment> payments) {
    final breakdown = <String, int>{};
    for (final payment in payments) {
      final status = payment.statusText;
      breakdown[status] = (breakdown[status] ?? 0) + 1;
    }
    return breakdown;
  }

  List<Map<String, dynamic>> _calculateMonthlyRevenue(List<Invoice> invoices) {
    final monthlyData = <String, double>{};
    for (final invoice in invoices) {
      final month = '${invoice.invoiceDate.year}-${invoice.invoiceDate.month.toString().padLeft(2, '0')}';
      monthlyData[month] = (monthlyData[month] ?? 0.0) + invoice.totalAmount;
    }

    return monthlyData.entries.map((entry) => {
      'month': entry.key,
      'revenue': entry.value,
    }).toList()
      ..sort((a, b) => a['month'].toString().compareTo(b['month'].toString()));
  }

  List<Map<String, dynamic>> _calculateMonthlyPayments(List<Payment> payments) {
    final monthlyData = <String, double>{};
    for (final payment in payments) {
      final month = '${payment.paymentDate.year}-${payment.paymentDate.month.toString().padLeft(2, '0')}';
      monthlyData[month] = (monthlyData[month] ?? 0.0) + payment.amount;
    }

    return monthlyData.entries.map((entry) => {
      'month': entry.key,
      'payments': entry.value,
    }).toList()
      ..sort((a, b) => a['month'].toString().compareTo(b['month'].toString()));
  }

  List<Map<String, dynamic>> _calculateTopCustomers(List<Invoice> invoices, List<Customer> customers) {
    final customerRevenue = <int, double>{};
    for (final invoice in invoices) {
      customerRevenue[invoice.customerId] = 
          (customerRevenue[invoice.customerId] ?? 0.0) + invoice.totalAmount;
    }

    final sortedCustomers = customerRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedCustomers.take(10).map((entry) {
      final customer = customers.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => Customer.empty(),
      );
      return {
        'customer': customer,
        'revenue': entry.value,
      };
    }).toList();
  }

  double _calculateAveragePaymentTime(List<Invoice> invoices, List<Payment> payments) {
    // Implementation for calculating average payment time
    return 0.0; // Placeholder
  }

  List<Map<String, dynamic>> _calculateMonthlyGrowth(List<Invoice> invoices, List<Payment> payments, List<Customer> customers) {
    // Implementation for calculating monthly growth
    return []; // Placeholder
  }

  Map<String, dynamic> _calculateYearOverYearGrowth(List<Invoice> invoices, List<Payment> payments, List<Customer> customers) {
    // Implementation for calculating year-over-year growth
    return {}; // Placeholder
  }

  Map<String, dynamic> _calculateTrends(List<Invoice> invoices, List<Payment> payments, List<Customer> customers) {
    // Implementation for calculating trends
    return {}; // Placeholder
  }

  Map<String, dynamic> _getDefaultAnalytics() {
    return {
      'totalRevenue': 0.0,
      'totalPaid': 0.0,
      'totalOutstanding': 0.0,
      'totalInvoices': 0,
      'totalCustomers': 0,
      'averageInvoiceValue': 0.0,
      'statusBreakdown': <String, int>{},
      'paymentMethodBreakdown': <String, int>{},
      'monthlyRevenue': <Map<String, dynamic>>[],
      'topCustomers': <Map<String, dynamic>>[],
      'recentInvoices': <Invoice>[],
      'recentPayments': <Payment>[],
      'customers': <Customer>[],
      'stats': {
        'totalRevenue': 0.0,
        'totalPaid': 0.0,
        'totalOutstanding': 0.0,
        'totalInvoices': 0,
        'totalCustomers': 0,
        'averageInvoiceValue': 0.0,
      },
    };
  }
}