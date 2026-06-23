import 'package:flutter/foundation.dart';

import 'policy_engine.dart';
import 'surcharge_tables.dart';

class TaxInputs {
  final double cifUsd;
  final double usdToUgxRate;
  final String hsCode;
  final String countryOfOrigin;
  final int year;
  final int engineCc;
  final bool isHybrid;
  final bool isEv;
  final String category; // car, truck, trailer, industrial
  final String? tonnageLabel; // e.g., "13 Ton"
  final String? axleLabel; // e.g., "2 Axle"

  const TaxInputs({
    required this.cifUsd,
    required this.usdToUgxRate,
    required this.hsCode,
    required this.countryOfOrigin,
    required this.year,
    required this.engineCc,
    required this.isHybrid,
    required this.isEv,
    required this.category,
    this.tonnageLabel,
    this.axleLabel,
  });
}

class TaxOutputs {
  final double customsValueUgx; // CV
  final double dutyUgx;
  final double surchargeUgx;
  final double vatBaseUgx;
  final double vatUgx;
  final double whtUgx;
  final double exciseUgx;
  final Map<String, String> notes; // e.g., bases and rates used

  const TaxOutputs({
    required this.customsValueUgx,
    required this.dutyUgx,
    required this.surchargeUgx,
    required this.vatBaseUgx,
    required this.vatUgx,
    required this.whtUgx,
    required this.exciseUgx,
    required this.notes,
  });

  double get taxTotalUgx => dutyUgx + surchargeUgx + vatUgx + whtUgx + exciseUgx;
}

class TaxEngine {
  final PolicyEngine policyEngine;
  final SurchargeTables surchargeTables;

  const TaxEngine({
    required this.policyEngine,
    required this.surchargeTables,
  });

  TaxOutputs computeWithoutSurcharge(TaxInputs inputs) {
    final policy = policyEngine.evaluate(
      hsCode: inputs.hsCode,
      isHybrid: inputs.isHybrid,
      isEv: inputs.isEv,
    );

    final cv = inputs.cifUsd * inputs.usdToUgxRate;

    final double dutyRate = policy.overrideDutyRatePct ?? 25.0; // default 25%
    final bool dutyExempt = policy.dutyExempt;
    final double duty = dutyExempt ? 0.0 : cv * (dutyRate / 100.0);

    final double vatRate = policy.overrideVatRatePct ?? 18.0; // default 18%
    final bool vatExempt = policy.vatExempt;
    final double vatBase = cv + duty;
    final double vat = vatExempt ? 0.0 : vatBase * (vatRate / 100.0);

    return TaxOutputs(
      customsValueUgx: cv,
      dutyUgx: duty,
      surchargeUgx: 0.0,
      vatBaseUgx: vatBase,
      vatUgx: vat,
      whtUgx: 0.0,
      exciseUgx: 0.0,
      notes: {
        'path': 'without_surcharge',
        'dutyRatePct': dutyRate.toStringAsFixed(2),
        'vatRatePct': vatRate.toStringAsFixed(2),
        'policy': policy.label,
        'rateUsed': inputs.usdToUgxRate.toStringAsFixed(2),
      },
    );
  }

  TaxOutputs computeWithSurcharge(TaxInputs inputs) {
    final policy = policyEngine.evaluate(
      hsCode: inputs.hsCode,
      isHybrid: inputs.isHybrid,
      isEv: inputs.isEv,
    );

    final cv = inputs.cifUsd * inputs.usdToUgxRate;

    final double dutyRate = policy.overrideDutyRatePct ?? 25.0;
    final bool dutyExempt = policy.dutyExempt;
    final double duty = dutyExempt ? 0.0 : cv * (dutyRate / 100.0);

    final surchargeRule = surchargeTables.resolve(
      category: inputs.category,
      tonnageLabel: inputs.tonnageLabel,
      axleLabel: inputs.axleLabel,
    );

    final double surchargeBase = switch (surchargeRule.base) {
      SurchargeBase.cv => cv,
      SurchargeBase.cvPlusDuty => cv + duty,
    };
    final double surcharge = surchargeBase * (surchargeRule.ratePct / 100.0);

    final double vatRate = policy.overrideVatRatePct ?? 18.0;
    final bool vatExempt = policy.vatExempt;
    final double vatBase = cv + duty + surcharge;
    final double vat = vatExempt ? 0.0 : vatBase * (vatRate / 100.0);

    return TaxOutputs(
      customsValueUgx: cv,
      dutyUgx: duty,
      surchargeUgx: surcharge,
      vatBaseUgx: vatBase,
      vatUgx: vat,
      whtUgx: 0.0,
      exciseUgx: 0.0,
      notes: {
        'path': 'with_surcharge',
        'dutyRatePct': dutyRate.toStringAsFixed(2),
        'vatRatePct': vatRate.toStringAsFixed(2),
        'surchargeRatePct': surchargeRule.ratePct.toStringAsFixed(2),
        'surchargeBase': describeEnum(surchargeRule.base),
        'policy': policy.label,
        'rateUsed': inputs.usdToUgxRate.toStringAsFixed(2),
      },
    );
  }
}


