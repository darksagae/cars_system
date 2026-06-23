import 'package:flutter/foundation.dart';
import '../models/payment_reminder.dart';
import '../services/reminders/payment_reminder_service.dart';

class PaymentReminderProvider extends ChangeNotifier {
  final PaymentReminderService _reminderService = PaymentReminderService();
  
  List<PaymentReminder> _reminders = [];
  bool _isLoading = false;
  String _searchQuery = '';
  ReminderStatus? _filterStatus;
  ReminderType? _filterType;
  ReminderTemplate _selectedTemplate = ReminderTemplate.friendly;

  // Getters
  List<PaymentReminder> get reminders => _reminders;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  ReminderStatus? get filterStatus => _filterStatus;
  ReminderType? get filterType => _filterType;
  ReminderTemplate get selectedTemplate => _selectedTemplate;

  // Get filtered reminders
  List<PaymentReminder> get filteredReminders {
    List<PaymentReminder> filtered = _reminders;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((reminder) =>
        reminder.reminderNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        reminder.subject.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        reminder.message.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Apply status filter
    if (_filterStatus != null) {
      filtered = filtered.where((reminder) => reminder.status == _filterStatus).toList();
    }

    // Apply type filter
    if (_filterType != null) {
      filtered = filtered.where((reminder) => reminder.type == _filterType).toList();
    }

    return filtered;
  }

  // Load all reminders
  Future<void> loadReminders() async {
    _setLoading(true);
    try {
      _reminders = await _reminderService.getAllReminders();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading reminders: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Create reminder
  Future<bool> createReminder(PaymentReminder reminder) async {
    try {
      final id = await _reminderService.createReminder(reminder);
      if (id > 0) {
        _reminders.add(reminder.copyWith(id: id));
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating reminder: $e');
      }
      return false;
    }
  }

  // Update reminder
  Future<bool> updateReminder(PaymentReminder reminder) async {
    try {
      final result = await _reminderService.updateReminder(reminder);
      if (result > 0) {
        final index = _reminders.indexWhere((r) => r.id == reminder.id);
        if (index != -1) {
          _reminders[index] = reminder;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating reminder: $e');
      }
      return false;
    }
  }

  // Delete reminder
  Future<bool> deleteReminder(int reminderId) async {
    try {
      final result = await _reminderService.deleteReminder(reminderId);
      if (result > 0) {
        _reminders.removeWhere((reminder) => reminder.id == reminderId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting reminder: $e');
      }
      return false;
    }
  }

  // Search reminders
  void searchReminders(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Filter by status
  void filterByStatus(ReminderStatus? status) {
    _filterStatus = status;
    notifyListeners();
  }

  // Filter by type
  void filterByType(ReminderType? type) {
    _filterType = type;
    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _searchQuery = '';
    _filterStatus = null;
    _filterType = null;
    notifyListeners();
  }

  // Set selected template
  void setSelectedTemplate(ReminderTemplate template) {
    _selectedTemplate = template;
    notifyListeners();
  }

  // Send reminder
  Future<bool> sendReminder(PaymentReminder reminder) async {
    try {
      if (reminder.id == null) {
        return false;
      }

      // Get invoice and customer data for the reminder
      final invoice = await _reminderService.getInvoiceForReminder(reminder.id!);
      final customer = await _reminderService.getCustomerForReminder(reminder.id!);
      
      if (invoice == null || customer == null) {
        return false;
      }

      final success = await _reminderService.sendReminder(reminder, invoice, customer);
      
      if (success) {
        // Update the reminder status in our local list
        final index = _reminders.indexWhere((r) => r.id == reminder.id);
        if (index != -1) {
          _reminders[index] = reminder.copyWith(
            status: ReminderStatus.sent,
            sentDate: DateTime.now(),
          );
          notifyListeners();
        }
      }
      
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending reminder: $e');
      }
      return false;
    }
  }

  // Reschedule reminder
  Future<bool> rescheduleReminder(PaymentReminder reminder, DateTime newDate) async {
    try {
      if (reminder.id == null) {
        return false;
      }

      final updatedReminder = reminder.copyWith(
        scheduledDate: newDate,
        status: ReminderStatus.scheduled,
      );
      
      final result = await _reminderService.updateReminder(updatedReminder);
      if (result > 0) {
        final index = _reminders.indexWhere((r) => r.id == reminder.id);
        if (index != -1) {
          _reminders[index] = updatedReminder;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error rescheduling reminder: $e');
      }
      return false;
    }
  }

  // Cancel reminder
  Future<bool> cancelReminder(PaymentReminder reminder) async {
    try {
      if (reminder.id == null) {
        return false;
      }

      final updatedReminder = reminder.copyWith(
        status: ReminderStatus.cancelled,
      );
      
      final result = await _reminderService.updateReminder(updatedReminder);
      if (result > 0) {
        final index = _reminders.indexWhere((r) => r.id == reminder.id);
        if (index != -1) {
          _reminders[index] = updatedReminder;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling reminder: $e');
      }
      return false;
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}