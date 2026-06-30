import 'package:flutter/material.dart';
import '../services/machine_lock_service.dart';
import 'glass_liquid_theme.dart';

/// Blocks all interaction when the machine is admin-locked or banned.
class MachineLockOverlay extends StatelessWidget {
  final Widget child;

  const MachineLockOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MachineLockService.instance,
      builder: (context, _) {
        final locked = MachineLockService.instance.isLocked;
        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (locked)
              Positioned.fill(
                child: Material(
                  color: Colors.black.withValues(alpha: 0.92),
                  child: SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.block,
                              size: 72,
                              color: GlassLiquidTheme.accentRed.withValues(alpha: 0.9),
                            ),
                            const SizedBox(height: 28),
                            Text(
                              MachineLockService.instance.message,
                              textAlign: TextAlign.center,
                              style: GlassLiquidTheme.bodyMedium.copyWith(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'This system has been locked by NSB Motors administration.',
                              textAlign: TextAlign.center,
                              style: GlassLiquidTheme.bodyMedium.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
