import 'package:flutter/material.dart';
import '../database/optimized_database_service.dart';
import '../cache/memory_cache.dart' as memory_cache;

class AdvancedSearchService {
  static final AdvancedSearchService _instance = AdvancedSearchService._internal();
  factory AdvancedSearchService() => _instance;
  AdvancedSearchService._internal();

  final OptimizedDatabaseService _dbService = OptimizedDatabaseService();
  final memory_cache.MemoryCache _cache = memory_cache.MemoryCache();

  // Search filters
  Map<String, dynamic> _filters = {};
  String _searchQuery = '';
  String _sortBy = 'created_at';
  bool _sortAscending = false;
  int _page = 1;
  int _pageSize = 20;

  // Search across all entities
  Future<SearchResults> searchAll({
    required String query,
    Map<String, dynamic>? filters,
    String? sortBy,
    bool? ascending,
    int? page,
    int? pageSize,
  }) async {
    _searchQuery = query;
    _filters = filters ?? {};
    _sortBy = sortBy ?? 'created_at';
    _sortAscending = ascending ?? false;
    _page = page ?? 1;
    _pageSize = pageSize ?? 20;

    try {
      // Search customers
      final customerResults = await _searchCustomers();
      
      // Search vehicles
      final vehicleResults = await _searchVehicles();
      
      // Search invoices
      final invoiceResults = await _searchInvoices();
      
      // Combine and sort results
      final combinedResults = _combineResults(
        customerResults,
        vehicleResults,
        invoiceResults,
      );
      
      return SearchResults(
        query: query,
        totalResults: combinedResults.length,
        results: combinedResults,
        page: _page,
        pageSize: _pageSize,
        hasMore: combinedResults.length >= _pageSize,
      );
    } catch (e) {
      throw Exception('Search failed: $e');
    }
  }

  // Search customers with advanced filters
  Future<List<SearchResult>> _searchCustomers() async {
    try {
      final results = await _dbService.getCustomersPaginated(
        page: _page,
        pageSize: _pageSize,
        searchQuery: _searchQuery,
        sortBy: _sortBy,
        ascending: _sortAscending,
      );
      
      return results.map((customer) => SearchResult(
        id: customer['id'],
        type: SearchResultType.customer,
        title: customer['name'],
        subtitle: customer['email'],
        description: 'Phone: ${customer['phone']}',
        data: customer,
        relevanceScore: _calculateRelevanceScore(customer, _searchQuery),
      )).toList();
    } catch (e) {
      return [];
    }
  }

  // Search vehicles with advanced filters
  Future<List<SearchResult>> _searchVehicles() async {
    try {
      final results = await _dbService.getVehiclesPaginated(
        page: _page,
        pageSize: _pageSize,
        searchQuery: _searchQuery,
        status: _filters['status'],
        sortBy: _sortBy,
        ascending: _sortAscending,
      );
      
      return results.map((vehicle) => SearchResult(
        id: vehicle['id'],
        type: SearchResultType.vehicle,
        title: vehicle['name'],
        subtitle: '${vehicle['make']} ${vehicle['model']} (${vehicle['year']})',
        description: 'Price: ${vehicle['price']} UGX',
        data: vehicle,
        relevanceScore: _calculateRelevanceScore(vehicle, _searchQuery),
      )).toList();
    } catch (e) {
      return [];
    }
  }

  // Search invoices with advanced filters
  Future<List<SearchResult>> _searchInvoices() async {
    try {
      final results = await _dbService.getInvoicesPaginated(
        page: _page,
        pageSize: _pageSize,
        searchQuery: _searchQuery,
        status: _filters['status'],
        customerId: _filters['customerId'],
        sortBy: _sortBy,
        ascending: _sortAscending,
      );
      
      return results.map((invoice) => SearchResult(
        id: invoice['id'],
        type: SearchResultType.invoice,
        title: invoice['invoice_number'],
        subtitle: 'Customer: ${invoice['customer_name']}',
        description: 'Amount: ${invoice['total_amount']} UGX',
        data: invoice,
        relevanceScore: _calculateRelevanceScore(invoice, _searchQuery),
      )).toList();
    } catch (e) {
      return [];
    }
  }

  // Combine results from different sources
  List<SearchResult> _combineResults(
    List<SearchResult> customers,
    List<SearchResult> vehicles,
    List<SearchResult> invoices,
  ) {
    final allResults = [...customers, ...vehicles, ...invoices];
    
    // Sort by relevance score
    allResults.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    
    // Apply pagination
    final startIndex = (_page - 1) * _pageSize;
    final endIndex = startIndex + _pageSize;
    
    if (startIndex >= allResults.length) return [];
    
    return allResults.sublist(
      startIndex,
      endIndex > allResults.length ? allResults.length : endIndex,
    );
  }

  // Calculate relevance score for search results
  double _calculateRelevanceScore(Map<String, dynamic> data, String query) {
    if (query.isEmpty) return 0.0;
    
    double score = 0.0;
    final queryLower = query.toLowerCase();
    
    // Check title/name field
    final title = data['name']?.toString().toLowerCase() ?? '';
    if (title.contains(queryLower)) {
      score += 10.0;
      if (title.startsWith(queryLower)) {
        score += 5.0; // Bonus for starting with query
      }
    }
    
    // Check email field
    final email = data['email']?.toString().toLowerCase() ?? '';
    if (email.contains(queryLower)) {
      score += 8.0;
    }
    
    // Check phone field
    final phone = data['phone']?.toString().toLowerCase() ?? '';
    if (phone.contains(queryLower)) {
      score += 6.0;
    }
    
    // Check make/model for vehicles
    final make = data['make']?.toString().toLowerCase() ?? '';
    final model = data['model']?.toString().toLowerCase() ?? '';
    if (make.contains(queryLower) || model.contains(queryLower)) {
      score += 7.0;
    }
    
    // Check invoice number
    final invoiceNumber = data['invoice_number']?.toString().toLowerCase() ?? '';
    if (invoiceNumber.contains(queryLower)) {
      score += 9.0;
    }
    
    return score;
  }

  // Get search suggestions
  Future<List<String>> getSearchSuggestions(String query) async {
    if (query.length < 2) return [];
    
    try {
      final cacheKey = 'suggestions_$query';
      final cachedSuggestions = _cache.get<List<String>>(cacheKey);
      if (cachedSuggestions != null) {
        return cachedSuggestions;
      }
      
      final suggestions = <String>{};
      
      // Get customer names
      final customers = await _dbService.getCustomersPaginated(
        page: 1,
        pageSize: 10,
        searchQuery: query,
      );
      for (final customer in customers) {
        suggestions.add(customer['name']?.toString() ?? '');
      }
      
      // Get vehicle names
      final vehicles = await _dbService.getVehiclesPaginated(
        page: 1,
        pageSize: 10,
        searchQuery: query,
      );
      for (final vehicle in vehicles) {
        suggestions.add(vehicle['name']?.toString() ?? '');
        suggestions.add('${vehicle['make']} ${vehicle['model']}');
      }
      
      // Get invoice numbers
      final invoices = await _dbService.getInvoicesPaginated(
        page: 1,
        pageSize: 10,
        searchQuery: query,
      );
      for (final invoice in invoices) {
        suggestions.add(invoice['invoice_number']?.toString() ?? '');
      }
      
      final suggestionsList = suggestions.where((s) => s.isNotEmpty).toList();
      
      // Cache suggestions
      _cache.put(cacheKey, suggestionsList, ttl: const Duration(minutes: 5));
      
      return suggestionsList;
    } catch (e) {
      return [];
    }
  }

  // Get search filters
  Map<String, List<String>> getAvailableFilters() {
    return {
      'status': ['active', 'inactive', 'pending', 'completed'],
      'type': ['customer', 'vehicle', 'invoice'],
      'date_range': ['today', 'this_week', 'this_month', 'this_year'],
      'amount_range': ['0-100000', '100000-500000', '500000-1000000', '1000000+'],
    };
  }

  // Clear search cache
  void clearSearchCache() {
    _cache.clear();
  }

  // Get search history
  List<String> getSearchHistory() {
    return _cache.get<List<String>>('search_history') ?? [];
  }

  // Add to search history
  void addToSearchHistory(String query) {
    if (query.trim().isEmpty) return;
    
    final history = getSearchHistory();
    history.remove(query); // Remove if already exists
    history.insert(0, query); // Add to beginning
    
    // Keep only last 20 searches
    if (history.length > 20) {
      history.removeRange(20, history.length);
    }
    
    _cache.put('search_history', history, ttl: const Duration(days: 30));
  }
}

// Search result data class
class SearchResult {
  final dynamic id;
  final SearchResultType type;
  final String title;
  final String subtitle;
  final String description;
  final Map<String, dynamic> data;
  final double relevanceScore;

  SearchResult({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.data,
    required this.relevanceScore,
  });
}

// Search result type enum
enum SearchResultType {
  customer,
  vehicle,
  invoice,
  payment,
  demandLetter,
  reminder,
}

// Search results data class
class SearchResults {
  final String query;
  final int totalResults;
  final List<SearchResult> results;
  final int page;
  final int pageSize;
  final bool hasMore;

  SearchResults({
    required this.query,
    required this.totalResults,
    required this.results,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });
}
