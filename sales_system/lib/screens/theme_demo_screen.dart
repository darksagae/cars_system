import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/theme_provider.dart';
import '../widgets/glass_liquid_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/theme_selector.dart';

class ThemeDemoScreen extends StatelessWidget {
  const ThemeDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: themeProvider.backgroundGradient,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(GlassLiquidTheme.spacingLarge),
                child: Column(
                  children: [
                    // Header
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(GlassLiquidTheme.radiusLarge),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                        ),
                      ),
                      padding: const EdgeInsets.all(GlassLiquidTheme.spacingLarge),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              FaIcon(
                                FontAwesomeIcons.palette,
                                color: GlassLiquidTheme.accentBlue,
                                size: 32,
                              ),
                              const SizedBox(width: GlassLiquidTheme.spacingMedium),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Global Theme Control',
                                      style: GlassLiquidTheme.heading2.copyWith(
                                        color: GlassLiquidTheme.accentBlue,
                                      ),
                                    ),
                                    Text(
                                      'Change themes here and see them applied to all screens instantly',
                                      style: GlassLiquidTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: GlassLiquidTheme.spacingLarge),
                    
                    // Theme Selector
                    const ThemeSelector(),
                    
                    const SizedBox(height: GlassLiquidTheme.spacingLarge),
                    
                    // Demo Cards
                    _buildDemoCards(),
                    
                    const SizedBox(height: GlassLiquidTheme.spacingLarge),
                    
                    // Instructions
                    _buildInstructions(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDemoCards() {
    return Column(
      children: [
        Text(
          'Glass Components',
          style: GlassLiquidTheme.heading3,
        ),
        const SizedBox(height: GlassLiquidTheme.spacingMedium),
        
        Row(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(GlassLiquidTheme.radiusLarge),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                  ),
                ),
                padding: const EdgeInsets.all(GlassLiquidTheme.spacingLarge),
                child: Column(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.palette,
                      color: GlassLiquidTheme.accentBlue,
                      size: 32,
                    ),
                    const SizedBox(height: GlassLiquidTheme.spacingMedium),
                    Text(
                      'Glass Container',
                      style: GlassLiquidTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: GlassLiquidTheme.spacingSmall),
                    Text(
                      'This demonstrates the glass effect with backdrop blur',
                      style: GlassLiquidTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: GlassLiquidTheme.spacingMedium),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(GlassLiquidTheme.radiusLarge),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                  ),
                ),
                padding: const EdgeInsets.all(GlassLiquidTheme.spacingLarge),
                child: Column(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.star,
                      color: GlassLiquidTheme.accentGreen,
                      size: 32,
                    ),
                    const SizedBox(height: GlassLiquidTheme.spacingMedium),
                    Text(
                      'Colored Glass',
                      style: GlassLiquidTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: GlassLiquidTheme.spacingSmall),
                    Text(
                      'Glass with accent color tinting',
                      style: GlassLiquidTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(GlassLiquidTheme.radiusLarge),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
        ),
      ),
      padding: const EdgeInsets.all(GlassLiquidTheme.spacingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.globe,
                color: GlassLiquidTheme.accentOrange,
                size: 20,
              ),
              const SizedBox(width: GlassLiquidTheme.spacingSmall),
              Text(
                'Global Theme Control - Changes Apply Everywhere',
                style: GlassLiquidTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: GlassLiquidTheme.spacingMedium),
          Text(
            '🎯 This is the ONLY place to change themes - affects ALL screens instantly',
            style: GlassLiquidTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: GlassLiquidTheme.accentGreen,
            ),
          ),
          const SizedBox(height: GlassLiquidTheme.spacingSmall),
          Text(
            '1. Choose from 6 predefined themes inspired by glass liquid UI designs',
            style: GlassLiquidTheme.bodyMedium,
          ),
          const SizedBox(height: GlassLiquidTheme.spacingSmall),
          Text(
            '2. Or create custom themes using the color pickers below',
            style: GlassLiquidTheme.bodyMedium,
          ),
          const SizedBox(height: GlassLiquidTheme.spacingSmall),
          Text(
            '3. Changes apply to: Login, Dashboard, Customers, Invoices, Payments, Reports, and ALL subscreens',
            style: GlassLiquidTheme.bodyMedium,
          ),
          const SizedBox(height: GlassLiquidTheme.spacingSmall),
          Text(
            '4. No background images - pure glass liquid UI with dynamic color gradients',
            style: GlassLiquidTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
