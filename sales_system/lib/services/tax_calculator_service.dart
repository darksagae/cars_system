import 'dart:math';
import 'tax/tax_engine.dart';
import 'tax/policy_engine.dart';
import 'tax/surcharge_tables.dart';

/// Tax calculation result
class TaxCalculationResult {
  final String sheetUsed;
  final String vehicleCategory;
  final double cifUSD;
  final double exchangeRate;
  final double environmentalLevy;
  final double importDuty;
  final double infrastructureLevy;
  final double exciseDuty;
  final double vatAmount;
  final double whtAmount;
  final double totalTaxUGX;
  final String taxBreakdown;
  final String displayName;

  TaxCalculationResult({
    required this.sheetUsed,
    required this.vehicleCategory,
    required this.cifUSD,
    required this.exchangeRate,
    required this.environmentalLevy,
    required this.importDuty,
    required this.infrastructureLevy,
    required this.exciseDuty,
    required this.vatAmount,
    required this.whtAmount,
    required this.totalTaxUGX,
    required this.taxBreakdown,
    required this.displayName,
  });
}

/// Comprehensive Tax Calculator Service
/// Implements all 5 Excel sheet calculations (Sheets 2-6)
/// for accurate Uganda vehicle tax calculations
class TaxCalculatorService {
  static const double _exchangeRate = 3834.56; // Default UGX/USD rate
  static const double _vatRate = 0.18; // 18% VAT
  static const double _whtRate = 0.06; // 6% WHT

  // Helper to calculate taxes for a given CIF value and specific rates
  static TaxCalculationResult _calculateTaxes({
    required double cifUSD,
    required double exchangeRate,
    required double environmentalLevyRate,
    required double importDutyRate,
    required double infrastructureLevyRate,
    required double exciseDutyRate,
    required String sheetUsed,
    required String vehicleCategory,
  }) {
    final double cifUGX = cifUSD * exchangeRate;

    // Align bases to workbook examples
    final double importDuty = cifUGX * importDutyRate; // duty on CIF
    final double environmentalLevy = cifUGX * environmentalLevyRate; // trucks surcharge on CIF
    final double infrastructureLevy = cifUGX * infrastructureLevyRate; // on CIF when applicable

    // Excise (when applicable): on CIF + Duty
    final double exciseDuty = (cifUGX + importDuty) * exciseDutyRate;

    // VAT: on CIF + Duty (per updated rule)
    final double vat = (cifUGX + importDuty) * _vatRate;

    // WHT: on CIF
    final double wht = cifUGX * _whtRate;

    final double totalTaxUGX = importDuty + vat + wht + environmentalLevy + infrastructureLevy + exciseDuty;

    return TaxCalculationResult(
      sheetUsed: sheetUsed,
      vehicleCategory: vehicleCategory,
      cifUSD: cifUSD,
      exchangeRate: _exchangeRate,
      environmentalLevy: environmentalLevy,
      importDuty: importDuty,
      infrastructureLevy: infrastructureLevy,
      exciseDuty: exciseDuty,
      vatAmount: vat,
      whtAmount: wht,
      totalTaxUGX: totalTaxUGX,
      displayName: '$vehicleCategory (Using $sheetUsed)',
      taxBreakdown: '''
CIF (USD): ${cifUSD.toStringAsFixed(2)}
Exchange Rate: ${_exchangeRate.toStringAsFixed(2)}
CIF (UGX): ${(cifUSD * _exchangeRate).toStringAsFixed(2)}

Import Duty (on CIF): ${importDuty.toStringAsFixed(2)} UGX
Excise Duty (on CIF+Duty): ${exciseDuty.toStringAsFixed(2)} UGX
VAT 18% (on CIF+Duty+Excise): ${vat.toStringAsFixed(2)} UGX
WHT 6% (on CIF): ${wht.toStringAsFixed(2)} UGX
Environmental Levy: ${environmentalLevy.toStringAsFixed(2)} UGX
Infrastructure Levy: ${infrastructureLevy.toStringAsFixed(2)} UGX

Total Tax Payable: ${totalTaxUGX.toStringAsFixed(2)} UGX
''',
    );
  }

  // Sheet 2: Passenger Cars (2015 & Older)
  static TaxCalculationResult calculateSheet2(double cifUSD, double exchangeRate) {
    return _calculateTaxes(
      cifUSD: cifUSD,
      exchangeRate: exchangeRate,
      environmentalLevyRate: 0.00, // cars: levy not shown
      importDutyRate: 0.25, // 25%
      infrastructureLevyRate: 0.00, // not shown
      exciseDutyRate: 0.00, // not shown
      sheetUsed: 'Sheet 2',
      vehicleCategory: 'Passenger Car (2015 & Older)',
    );
  }

  // Sheet 3: Passenger Cars (2016 & Newer)
  static TaxCalculationResult calculateSheet3(double cifUSD, double exchangeRate) {
    return _calculateTaxes(
      cifUSD: cifUSD,
      exchangeRate: exchangeRate,
      environmentalLevyRate: 0.00,
      importDutyRate: 0.25,
      infrastructureLevyRate: 0.00,
      exciseDutyRate: 0.00,
      sheetUsed: 'Sheet 3',
      vehicleCategory: 'Passenger Car (2016 & Newer)',
    );
  }

  // Sheet 4: Light Trucks (3.5 - 6.9 Tonnes)
  static TaxCalculationResult calculateSheet4(double cifUSD, double exchangeRate) {
    return _calculateTaxes(
      cifUSD: cifUSD,
      exchangeRate: exchangeRate,
      environmentalLevyRate: 0.20, // trucks surcharge 20%
      importDutyRate: 0.25,
      infrastructureLevyRate: 0.015,
      exciseDutyRate: 0.00,
      sheetUsed: 'Sheet 4',
      vehicleCategory: 'Light Truck (3.5 - 6.9 Tonnes)',
    );
  }

  // Sheet 5: Medium Trucks (7 - 19.9 Tonnes)
  static TaxCalculationResult calculateSheet5(double cifUSD, double exchangeRate) {
    return _calculateTaxes(
      cifUSD: cifUSD,
      exchangeRate: exchangeRate,
      environmentalLevyRate: 0.20, // trucks surcharge 20%
      importDutyRate: 0.10, // 7-19.9t example
      infrastructureLevyRate: 0.015,
      exciseDutyRate: 0.00,
      sheetUsed: 'Sheet 5',
      vehicleCategory: 'Medium Truck (7 - 19.9 Tonnes)',
    );
  }

  // Sheet 6: Heavy Trucks (20+ Tonnes) & Tractor Heads
  static TaxCalculationResult calculateSheet6(double cifUSD, double exchangeRate) {
    return _calculateTaxes(
      cifUSD: cifUSD,
      exchangeRate: exchangeRate,
      environmentalLevyRate: 0.20, // trucks surcharge
      importDutyRate: 0.00, // 0%
      infrastructureLevyRate: 0.00, // as per example
      exciseDutyRate: 0.00,
      sheetUsed: 'Sheet 6',
      vehicleCategory: 'Heavy Truck (20+ Tonnes) / Tractor Head',
    );
  }

  // Main lookup function to determine which sheet to use
  static TaxCalculationResult? calculateVehicleTax({
    required String vehicleType, // 'Car', 'Light Truck', 'Medium Truck', 'Heavy Truck', 'Tractor Head'
    required int year,
    required double cifUSD,
    required double exchangeRate, // Pass exchange rate
    double? tonnage, // Required for trucks
  }) {
    if (cifUSD <= 0) return null;

    // Use the new engines to mirror workbook logic while preserving this API
    final policy = PolicyEngine(quotationDate: DateTime.now());
    final surcharge = const SurchargeTables();
    final engine = TaxEngine(policyEngine: policy, surchargeTables: surcharge);

    final String category = _mapVehicleTypeToCategory(vehicleType);
    final inputs = TaxInputs(
      cifUsd: cifUSD,
      usdToUgxRate: exchangeRate,
      hsCode: '8703',
      countryOfOrigin: 'JP',
      year: year,
      engineCc: 0,
      isHybrid: false,
      isEv: false,
      category: category,
      tonnageLabel: tonnage != null ? '${tonnage.toStringAsFixed(1)} Ton' : null,
      axleLabel: null,
    );

    final bool withSurcharge = category != 'passenger_car';
    final outputs = withSurcharge
        ? engine.computeWithSurcharge(inputs)
        : engine.computeWithoutSurcharge(inputs);

    // Determine sheet used based on actual environmental levy, not just category
    // If environmental levy > 0, it's "with surcharge", otherwise "without surcharge"
    final bool hasEnvironmentalLevy = outputs.surchargeUgx > 0;
    final String sheetUsedValue = hasEnvironmentalLevy ? 'with surcharge' : 'without surcharge';

    return TaxCalculationResult(
      sheetUsed: sheetUsedValue,
      vehicleCategory: vehicleType,
      cifUSD: cifUSD,
      exchangeRate: exchangeRate,
      environmentalLevy: outputs.surchargeUgx, // map surcharge here
      importDuty: outputs.dutyUgx,
      infrastructureLevy: 0.0,
      exciseDuty: outputs.exciseUgx,
      vatAmount: outputs.vatUgx,
      whtAmount: outputs.whtUgx,
      totalTaxUGX: outputs.taxTotalUgx,
      taxBreakdown: 'Calculated via engines; duty=${outputs.dutyUgx.toStringAsFixed(0)}, '
          'surcharge=${outputs.surchargeUgx.toStringAsFixed(0)}, '
          'vat=${outputs.vatUgx.toStringAsFixed(0)}',
      displayName: '$vehicleType (${withSurcharge ? 'With' : 'Without'} Surcharge)',
    );
  }

  // Auto-calculate tax based on vehicle details
  static TaxCalculationResult? autoCalculateTax({
    required String vehicleType,
    required int year,
    required double cifUSD,
    required double exchangeRate,
    double? tonnage,
  }) {
    return calculateVehicleTax(
      vehicleType: vehicleType,
      year: year,
      cifUSD: cifUSD,
      exchangeRate: exchangeRate,
      tonnage: tonnage,
    );
  }

  // Helper methods
  static String _formatCurrency(double amount) {
    return 'UGX ${amount.toStringAsFixed(2)}';
  }

  static double getCurrentExchangeRate() {
    return _exchangeRate;
  }

  static void updateExchangeRate(double newRate) {
    // In a real implementation, this would update a database or config
    // For now, we'll use the static constant
  }
}

String _mapVehicleTypeToCategory(String vehicleType) {
  switch (vehicleType) {
    case 'Car':
      return 'passenger_car';
    case 'Light Truck':
    case 'Medium Truck':
    case 'Heavy Truck':
    case 'Tractor Head':
    case 'Double/Single Cabin':
      return 'truck';
    default:
      return 'passenger_car';
  }
}