import 'package:flutter/foundation.dart';
import '../models/demand_letter.dart';
import '../models/invoice.dart';
import '../models/customer.dart';
import '../services/demand_letter/demand_letter_service.dart';

class DemandLetterProvider extends ChangeNotifier {
  final DemandLetterService _demandLetterService = DemandLetterService();
  
  List<DemandLetter> _demandLetters = [];
  List<DemandLetter> _filteredDemandLetters = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _filterStatus;
  DemandLetterTemplate? _filterTemplate;

  List<DemandLetter> get demandLetters => _filteredDemandLetters;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get filterStatus => _filterStatus;
  DemandLetterTemplate? get filterTemplate => _filterTemplate;

  // Load all demand letters
  Future<void> loadDemandLetters() async {
    _isLoading = true;
    notifyListeners();

    try {
      _demandLetters = await _demandLetterService.getAllDemandLetters();
      _filteredDemandLetters = List.from(_demandLetters);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading demand letters: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search demand letters
  void searchDemandLetters(String query) {
    _searchQuery = query;
    
    if (query.isEmpty) {
      _filteredDemandLetters = _filterByStatusAndTemplate(_demandLetters);
    } else {
      final searchResults = _demandLetters.where((letter) {
        return letter.letterNumber.toLowerCase().contains(query.toLowerCase()) ||
               letter.subject.toLowerCase().contains(query.toLowerCase()) ||
               letter.content.toLowerCase().contains(query.toLowerCase());
      }).toList();
      _filteredDemandLetters = _filterByStatusAndTemplate(searchResults);
    }
    
    notifyListeners();
  }

  // Filter by status
  void filterByStatus(String status) {
    _filterStatus = status;
    _filteredDemandLetters = _demandLetters.where((letter) => letter.status == status).toList();
    notifyListeners();
  }

  // Filter by template
  void filterByTemplate(DemandLetterTemplate template) {
    _filterTemplate = template;
    _filteredDemandLetters = _demandLetters.where((letter) => 
      _getTemplateFromStatus(letter.status.toString()) == template).toList();
    notifyListeners();
  }

  // Helper method to filter by status and template
  List<DemandLetter> _filterByStatusAndTemplate(List<DemandLetter> letters) {
    List<DemandLetter> filtered = letters;
    
    if (_filterStatus != null) {
      filtered = filtered.where((letter) => letter.status == _filterStatus).toList();
    }
    
    if (_filterTemplate != null) {
      filtered = filtered.where((letter) => 
        _getTemplateFromStatus(letter.status.toString()) == _filterTemplate).toList();
    }
    
    return filtered;
  }

  // Helper method to get template from status
  DemandLetterTemplate _getTemplateFromStatus(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return DemandLetterTemplate.firstNotice;
      case 'sent':
        return DemandLetterTemplate.firstNotice;
      case 'delivered':
        return DemandLetterTemplate.secondNotice;
      case 'acknowledged':
        return DemandLetterTemplate.finalNotice;
      case 'overdue':
        return DemandLetterTemplate.legalNotice;
      default:
        return DemandLetterTemplate.firstNotice;
    }
  }

  // Create demand letter
  Future<DemandLetter?> createDemandLetter({
    required Invoice invoice,
    required Customer customer,
    required DemandLetterTemplate template,
    required double interestRate,
    required int daysOverdue,
    String? customContent,
    String? notes,
  }) async {
    try {
      // Generate letter number
      final letterNumber = await _demandLetterService.generateDemandLetterNumber();
      
      // Generate content
      final content = await _demandLetterService.generateDemandLetterContent(
        invoice: invoice,
        customer: customer,
        template: template,
        interestRate: interestRate,
        daysOverdue: daysOverdue,
        customContent: customContent,
      );
      
      // Generate subject
      final subject = _demandLetterService.generateDemandLetterSubject(
        invoice: invoice,
        template: template,
        daysOverdue: daysOverdue,
      );
      
      // Calculate due date (7 days from now)
      final dueDate = DateTime.now().add(const Duration(days: 7));
      
      // Create demand letter
      final demandLetter = DemandLetter(
        invoiceId: invoice.id!,
        customerId: customer.id!,
        letterNumber: letterNumber,
        issueDate: DateTime.now(),
        dueDate: dueDate,
        amount: invoice.balanceAmount,
        interestRate: interestRate,
        daysOverdue: daysOverdue,
        status: DemandLetterStatus.draft,
        subject: subject,
        content: content,
        notes: notes ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final id = await _demandLetterService.createDemandLetter(demandLetter);
      if (id > 0) {
        final newDemandLetter = demandLetter.copyWith(id: id);
        _demandLetters.add(newDemandLetter);
        searchDemandLetters(_searchQuery);
        return newDemandLetter;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating demand letter: $e');
      }
      return null;
    }
  }

  // Update demand letter
  Future<bool> updateDemandLetter(DemandLetter demandLetter) async {
    try {
      final result = await _demandLetterService.updateDemandLetter(demandLetter);
      if (result > 0) {
        final index = _demandLetters.indexWhere((l) => l.id == demandLetter.id);
        if (index != -1) {
          _demandLetters[index] = demandLetter;
          searchDemandLetters(_searchQuery);
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating demand letter: $e');
      }
      return false;
    }
  }

  // Delete demand letter
  Future<bool> deleteDemandLetter(int id) async {
    try {
      final result = await _demandLetterService.deleteDemandLetter(id);
      if (result > 0) {
        _demandLetters.removeWhere((l) => l.id == id);
        searchDemandLetters(_searchQuery);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting demand letter: $e');
      }
      return false;
    }
  }

  // Get demand letter by ID
  DemandLetter? getDemandLetterById(int id) {
    try {
      return _demandLetters.firstWhere((l) => l.id == id);
    } catch (e) {
      return null;
    }
  }

  // Refresh demand letter data
  Future<void> refreshDemandLetters() async {
    await loadDemandLetters();
  }

  // Clear search and filters
  void clearFilters() {
    _searchQuery = '';
    _filterStatus = null;
    _filterTemplate = null;
    _filteredDemandLetters = List.from(_demandLetters);
    notifyListeners();
  }
}