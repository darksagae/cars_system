import 'package:flutter/foundation.dart';
import '../models/vehicle.dart';
import '../services/vehicle_service.dart';

class VehicleProvider with ChangeNotifier {
  final VehicleService _vehicleService = VehicleService();
  
  List<Vehicle> _vehicles = [];
  List<Vehicle> _filteredVehicles = [];
  bool _isLoading = false;
  String _searchQuery = '';
  VehicleStatus? _statusFilter;
  String? _makeFilter;
  String? _modelFilter;

  // Getters
  List<Vehicle> get vehicles => _filteredVehicles;
  List<Vehicle> get allVehicles => _vehicles;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  VehicleStatus? get statusFilter => _statusFilter;
  String? get makeFilter => _makeFilter;
  String? get modelFilter => _modelFilter;

  // Get available vehicles (in stock)
  List<Vehicle> get availableVehicles {
    return _vehicles.where((vehicle) => vehicle.isAvailable).toList();
  }

  // Get vehicles by status
  List<Vehicle> getVehiclesByStatus(VehicleStatus status) {
    return _vehicles.where((vehicle) => vehicle.status == status).toList();
  }

  // Load all vehicles
  Future<void> loadVehicles() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _vehicles = await _vehicleService.getAllVehicles();
      _filteredVehicles = List.from(_vehicles);
      _applyFilters();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading vehicles: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load available vehicles only
  Future<void> loadAvailableVehicles() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _vehicles = await _vehicleService.getAvailableVehicles();
      _filteredVehicles = List.from(_vehicles);
      _applyFilters();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading available vehicles: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add vehicle
  Future<bool> addVehicle(Vehicle vehicle) async {
    try {
      final id = await _vehicleService.createVehicle(vehicle);
      if (id > 0) {
        final newVehicle = vehicle.copyWith(id: id);
        _vehicles.add(newVehicle);
        _applyFilters();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding vehicle: $e');
      }
      return false;
    }
  }

  // Update vehicle
  Future<bool> updateVehicle(Vehicle vehicle) async {
    try {
      final result = await _vehicleService.updateVehicle(vehicle);
      if (result > 0) {
        final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
        if (index != -1) {
          _vehicles[index] = vehicle;
          _applyFilters();
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating vehicle: $e');
      }
      return false;
    }
  }

  // Delete vehicle
  Future<bool> deleteVehicle(int id) async {
    try {
      final result = await _vehicleService.deleteVehicle(id);
      if (result > 0) {
        _vehicles.removeWhere((v) => v.id == id);
        _applyFilters();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting vehicle: $e');
      }
      return false;
    }
  }

  // Search vehicles
  void searchVehicles(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  // Filter by status
  void filterByStatus(VehicleStatus? status) {
    _statusFilter = status;
    _applyFilters();
  }

  // Filter by make
  void filterByMake(String? make) {
    _makeFilter = make;
    _modelFilter = null; // Reset model filter when make changes
    _applyFilters();
  }

  // Filter by model
  void filterByModel(String? model) {
    _modelFilter = model;
    _applyFilters();
  }

  // Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _statusFilter = null;
    _makeFilter = null;
    _modelFilter = null;
    _applyFilters();
  }

  // Apply all active filters
  void _applyFilters() {
    _filteredVehicles = List.from(_vehicles);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _filteredVehicles = _filteredVehicles.where((vehicle) {
        return vehicle.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               vehicle.make.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               vehicle.model.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               vehicle.color.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply status filter
    if (_statusFilter != null) {
      _filteredVehicles = _filteredVehicles.where((vehicle) {
        return vehicle.status == _statusFilter;
      }).toList();
    }

    // Apply make filter
    if (_makeFilter != null) {
      _filteredVehicles = _filteredVehicles.where((vehicle) {
        return vehicle.make == _makeFilter;
      }).toList();
    }

    // Apply model filter
    if (_modelFilter != null) {
      _filteredVehicles = _filteredVehicles.where((vehicle) {
        return vehicle.model == _modelFilter;
      }).toList();
    }

    notifyListeners();
  }

  // Get vehicle statistics
  Future<Map<String, dynamic>> getVehicleStatistics() async {
    try {
      return await _vehicleService.getVehicleStatistics();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting vehicle statistics: $e');
      }
      return {};
    }
  }

  // Get unique makes
  Future<List<String>> getUniqueMakes() async {
    try {
      return await _vehicleService.getUniqueMakes();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting unique makes: $e');
      }
      return [];
    }
  }

  // Get models by make
  Future<List<String>> getModelsByMake(String make) async {
    try {
      return await _vehicleService.getModelsByMake(make);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting models by make: $e');
      }
      return [];
    }
  }

  // Update vehicle status
  Future<bool> updateVehicleStatus(int id, VehicleStatus status) async {
    try {
      final result = await _vehicleService.updateVehicleStatus(id, status);
      if (result > 0) {
        final index = _vehicles.indexWhere((v) => v.id == id);
        if (index != -1) {
          _vehicles[index] = _vehicles[index].copyWith(status: status);
          _applyFilters();
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating vehicle status: $e');
      }
      return false;
    }
  }
}
