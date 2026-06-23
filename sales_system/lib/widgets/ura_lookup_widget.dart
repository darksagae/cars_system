import 'package:flutter/material.dart';
import '../models/ura_vehicle.dart';
import 'dynamic_pdf_search.dart';

class UraLookupWidget extends StatelessWidget {
  final Function(String make, String model, int year, int engineCC, double cifUSD, String? serialNumber) onVehicleSelected;
  final String? initialMake;
  final String? initialModel;
  final int? initialYear;
  final int? initialEngineCC;
  final double? initialCifUSD;

  const UraLookupWidget({
    Key? key,
    required this.onVehicleSelected,
    this.initialMake,
    this.initialModel,
    this.initialYear,
    this.initialEngineCC,
    this.initialCifUSD,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Directly use DynamicPdfSearch - it's the same search functionality
    // This makes URA Database Lookup a direct link/mirror to Dynamic PDF Search
    return DynamicPdfSearch(
      onVehicleSelected: (UraVehicle vehicle) {
        // Convert UraVehicle to the callback format expected by invoice form
        onVehicleSelected(
          vehicle.make,
          vehicle.model,
          vehicle.year,
          vehicle.engineCC,
          vehicle.cifUsd,
          vehicle.serialNumber,
        );
      },
    );
  }
}
