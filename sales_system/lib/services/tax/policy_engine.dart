class PolicyResult {
  final bool dutyExempt;
  final bool vatExempt;
  final double? overrideDutyRatePct;
  final double? overrideVatRatePct;
  final String label;

  const PolicyResult({
    required this.dutyExempt,
    required this.vatExempt,
    this.overrideDutyRatePct,
    this.overrideVatRatePct,
    required this.label,
  });
}

class PolicyEngine {
  final DateTime quotationDate;

  const PolicyEngine({required this.quotationDate});

  PolicyResult evaluate({
    required String hsCode,
    required bool isHybrid,
    required bool isEv,
  }) {
    // Placeholder defaults; integrate real policy table when available
    if (isHybrid || isEv) {
      return const PolicyResult(
        dutyExempt: true,
        vatExempt: true,
        overrideDutyRatePct: null,
        overrideVatRatePct: null,
        label: 'Hybrid/EV Exemption (placeholder)',
      );
    }
    return const PolicyResult(
      dutyExempt: false,
      vatExempt: false,
      overrideDutyRatePct: 25.0,
      overrideVatRatePct: 18.0,
      label: 'Standard policy',
    );
  }
}


