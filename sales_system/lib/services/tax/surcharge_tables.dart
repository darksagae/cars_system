enum SurchargeBase { cv, cvPlusDuty }

class SurchargeRule {
  final SurchargeBase base;
  final double ratePct;

  const SurchargeRule({required this.base, required this.ratePct});
}

class SurchargeTables {
  const SurchargeTables();

  SurchargeRule resolve({
    required String category,
    String? tonnageLabel,
    String? axleLabel,
  }) {
    // Placeholder defaults; map to actual tables:
    if (category == 'truck') {
      // Example: 13 Ton trucks
      if ((tonnageLabel ?? '').contains('13')) {
        return const SurchargeRule(base: SurchargeBase.cvPlusDuty, ratePct: 20.0);
      }
      return const SurchargeRule(base: SurchargeBase.cvPlusDuty, ratePct: 15.0);
    }
    if (category == 'trailer') {
      // Example: Axle-based
      if ((axleLabel ?? '').contains('2')) {
        return const SurchargeRule(base: SurchargeBase.cv, ratePct: 10.0);
      }
      return const SurchargeRule(base: SurchargeBase.cv, ratePct: 8.0);
    }
    return const SurchargeRule(base: SurchargeBase.cv, ratePct: 0.0);
  }
}


