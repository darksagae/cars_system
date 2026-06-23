class FeesConfig {
  final double registrationUgx;
  final double stampUgx;
  final double formUgx;
  final double platesUgx;
  final double agentUgx;
  final double inspectionUgx;
  final double ttUsdFactor; // e.g., 40 USD per CIF USD

  const FeesConfig({
    required this.registrationUgx,
    required this.stampUgx,
    required this.formUgx,
    required this.platesUgx,
    required this.agentUgx,
    required this.inspectionUgx,
    required this.ttUsdFactor,
  });
}

class FeesOutputs {
  final double ttUgx;
  final double totalUgx;

  const FeesOutputs({
    required this.ttUgx,
    required this.totalUgx,
  });
}

class FeesEngine {
  const FeesEngine();

  FeesOutputs compute({
    required FeesConfig config,
    required double cifUsd,
    required double usdToUgxRate,
  }) {
    final double ttUgx = config.ttUsdFactor * cifUsd; // Sheet shows TT as USD×CIF; no FX
    final double total = config.registrationUgx +
        config.stampUgx +
        config.formUgx +
        config.platesUgx +
        config.agentUgx +
        config.inspectionUgx +
        ttUgx;

    return FeesOutputs(ttUgx: ttUgx, totalUgx: total);
  }
}


