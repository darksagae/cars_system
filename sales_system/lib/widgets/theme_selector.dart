import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'glass_liquid_theme.dart';
import 'glass_container.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return GlassCard(
          title: 'Theme Colors',
          borderRadius: GlassLiquidTheme.radiusLarge,
          padding: const EdgeInsets.all(GlassLiquidTheme.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose your preferred background theme:',
                style: GlassLiquidTheme.bodyMedium.copyWith(
                  color: GlassLiquidTheme.textSecondary,
                ),
              ),
              const SizedBox(height: GlassLiquidTheme.spacingLarge),
              
              // Theme preview
              _buildThemePreview(themeProvider),
              const SizedBox(height: GlassLiquidTheme.spacingLarge),
              
              // Theme selection grid
              _buildThemeGrid(themeProvider),
              const SizedBox(height: GlassLiquidTheme.spacingLarge),
              
              // Hue & Intensity sliders
              _buildHueIntensityControls(themeProvider),
              const SizedBox(height: GlassLiquidTheme.spacingLarge),
              
              // Custom color pickers
              _buildCustomColorPickers(themeProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHueIntensityControls(ThemeProvider themeProvider) {
    // A slim gradient bar for hue preview similar to the screenshot
    Widget hueBar = Container(
      height: 8,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(999)),
        gradient: LinearGradient(
          colors: [
            Color(0xFFFF0000), // red
            Color(0xFFFFFF00), // yellow
            Color(0xFF00FF00), // green
            Color(0xFF00FFFF), // cyan
            Color(0xFF0000FF), // blue
            Color(0xFFFF00FF), // magenta
          ],
        ),
      ),
    );
    Widget intensityBar = Container(
      height: 8,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(999)),
        gradient: LinearGradient(
          colors: [
            Color(0xFF000000),
            Color(0xFFFFFFFF),
          ],
        ),
      ),
    );
    
    return GlassContainer(
      padding: const EdgeInsets.all(GlassLiquidTheme.spacingLarge),
      borderRadius: GlassLiquidTheme.radiusLarge,
      backgroundColor: GlassLiquidTheme.glassSecondary,
      borderColor: GlassLiquidTheme.glassBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Color',
                style: GlassLiquidTheme.bodyMedium,
              ),
              const Spacer(),
              Text(
                '${themeProvider.hue.toStringAsFixed(0)}°',
                style: GlassLiquidTheme.caption,
              ),
            ],
          ),
          const SizedBox(height: GlassLiquidTheme.spacingSmall),
          hueBar,
          Slider(
            value: themeProvider.hue,
            min: 0,
            max: 360,
            onChanged: (v) => themeProvider.setHue(v),
          ),
          const SizedBox(height: GlassLiquidTheme.spacingMedium),
          Row(
            children: [
              Text(
                'Intensity',
                style: GlassLiquidTheme.bodyMedium,
              ),
              const Spacer(),
              Text(
                '${(themeProvider.intensity * 100).round()}%',
                style: GlassLiquidTheme.caption,
              ),
            ],
          ),
          const SizedBox(height: GlassLiquidTheme.spacingSmall),
          intensityBar,
          Slider(
            value: themeProvider.intensity,
            min: 0,
            max: 1,
            onChanged: (v) => themeProvider.setIntensity(v),
          ),
        ],
      ),
    );
  }

  Widget _buildThemePreview(ThemeProvider themeProvider) {
    return GlassContainer(
      padding: const EdgeInsets.all(GlassLiquidTheme.spacingLarge),
      borderRadius: GlassLiquidTheme.radiusMedium,
      backgroundColor: GlassLiquidTheme.glassSecondary,
      borderColor: GlassLiquidTheme.glassBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Theme Preview',
            style: GlassLiquidTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: GlassLiquidTheme.spacingMedium),
          Container(
            height: 60,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: themeProvider.backgroundGradient,
              borderRadius: BorderRadius.circular(GlassLiquidTheme.radiusMedium),
              border: Border.all(
                color: GlassLiquidTheme.glassBorder,
              ),
            ),
            child: Center(
              child: Text(
                'Glass Liquid UI Preview',
                style: GlassLiquidTheme.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeGrid(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Predefined Themes',
          style: GlassLiquidTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: GlassLiquidTheme.spacingMedium),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: GlassLiquidTheme.spacingMedium,
            mainAxisSpacing: GlassLiquidTheme.spacingMedium,
            childAspectRatio: 2.5,
          ),
          itemCount: themeProvider.availableThemes.length,
          itemBuilder: (context, index) {
            final themeName = themeProvider.availableThemes[index];
            final isSelected = themeProvider.currentTheme == themeName;
            
            return _buildThemeOption(themeProvider, themeName, isSelected);
          },
        ),
      ],
    );
  }

  Widget _buildThemeOption(ThemeProvider themeProvider, String themeName, bool isSelected) {
    // Get colors for this theme
    Color primaryColor;
    Color secondaryColor;
    Color accentColor;
    
    switch (themeName) {
      case 'smart_home':
        primaryColor = const Color(0xFF1A1A2E);
        secondaryColor = const Color(0xFF16213E);
        accentColor = const Color(0xFF0F3460);
        break;
      case 'e_commerce':
        primaryColor = const Color(0xFF2C2C54);
        secondaryColor = const Color(0xFF40407A);
        accentColor = const Color(0xFF706FD3);
        break;
      case 'living_room':
        primaryColor = const Color(0xFF1E1E2E);
        secondaryColor = const Color(0xFF2D2D44);
        accentColor = const Color(0xFF4A4A6A);
        break;
      case 'ocean_view':
        primaryColor = const Color(0xFF0F172A);
        secondaryColor = const Color(0xFF1E293B);
        accentColor = const Color(0xFF334155);
        break;
      case 'modern_glass':
        primaryColor = const Color(0xFF1A1A1A);
        secondaryColor = const Color(0xFF2A2A2A);
        accentColor = const Color(0xFF3A3A3A);
        break;
      case 'frosted_blue':
        primaryColor = const Color(0xFF0A1929);
        secondaryColor = const Color(0xFF1A2332);
        accentColor = const Color(0xFF2A3441);
        break;
      default:
        primaryColor = const Color(0xFF1A1A2E);
        secondaryColor = const Color(0xFF16213E);
        accentColor = const Color(0xFF0F3460);
    }
    
    return GlassButton(
      onPressed: () => themeProvider.setTheme(themeName),
      backgroundColor: isSelected 
          ? GlassLiquidTheme.accentBlue.withOpacity(0.2)
          : GlassLiquidTheme.glassSecondary,
      borderColor: isSelected 
          ? GlassLiquidTheme.accentBlue.withOpacity(0.5)
          : GlassLiquidTheme.glassBorder,
      borderRadius: GlassLiquidTheme.radiusMedium,
      padding: const EdgeInsets.all(GlassLiquidTheme.spacingMedium),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Color preview
          Container(
            height: 20,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, secondaryColor, accentColor],
              ),
              borderRadius: BorderRadius.circular(GlassLiquidTheme.radiusSmall),
            ),
          ),
          const SizedBox(height: GlassLiquidTheme.spacingSmall),
          // Theme name
          Text(
            themeName.replaceAll('_', ' ').toUpperCase(),
            style: GlassLiquidTheme.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: isSelected ? GlassLiquidTheme.accentBlue : GlassLiquidTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomColorPickers(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom Colors',
          style: GlassLiquidTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: GlassLiquidTheme.spacingMedium),
        
        Row(
          children: [
            Expanded(
              child: _buildColorPicker(
                'Primary',
                themeProvider.primaryBackground,
                (color) => themeProvider.updateBackgroundColors(primary: color),
              ),
            ),
            const SizedBox(width: GlassLiquidTheme.spacingMedium),
            Expanded(
              child: _buildColorPicker(
                'Secondary',
                themeProvider.secondaryBackground,
                (color) => themeProvider.updateBackgroundColors(secondary: color),
              ),
            ),
            const SizedBox(width: GlassLiquidTheme.spacingMedium),
            Expanded(
              child: _buildColorPicker(
                'Accent',
                themeProvider.accentBackground,
                (color) => themeProvider.updateBackgroundColors(accent: color),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: GlassLiquidTheme.spacingLarge),
        
        // Reset button
        SizedBox(
          width: double.infinity,
          child: GlassButton(
            onPressed: () => themeProvider.resetToDefault(),
            backgroundColor: GlassLiquidTheme.accentOrange.withOpacity(0.2),
            borderColor: GlassLiquidTheme.accentOrange.withOpacity(0.5),
            child: Text(
              'Reset to Default',
              style: GlassLiquidTheme.bodyMedium.copyWith(
                color: GlassLiquidTheme.accentOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorPicker(String label, Color currentColor, Function(Color) onColorChanged) {
    return GlassContainer(
      padding: const EdgeInsets.all(GlassLiquidTheme.spacingMedium),
      borderRadius: GlassLiquidTheme.radiusMedium,
      backgroundColor: GlassLiquidTheme.glassSecondary,
      borderColor: GlassLiquidTheme.glassBorder,
      child: Column(
        children: [
          Text(
            label,
            style: GlassLiquidTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: GlassLiquidTheme.spacingSmall),
          GestureDetector(
            onTap: () => _showColorPicker(currentColor, onColorChanged),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: currentColor,
                borderRadius: BorderRadius.circular(GlassLiquidTheme.radiusSmall),
                border: Border.all(
                  color: GlassLiquidTheme.glassBorder,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(Color currentColor, Function(Color) onColorChanged) {
    // Cycle through glass liquid UI inspired colors
    final colors = [
      const Color(0xFF1A1A2E),      // Smart Home Navy
      const Color(0xFF16213E),      // Ocean Blue
      const Color(0xFF0F3460),      // Deep Blue
      const Color(0xFF2C2C54),      // E-commerce Purple
      const Color(0xFF40407A),      // Medium Purple
      const Color(0xFF706FD3),      // Light Purple
      const Color(0xFF1E1E2E),      // Living Room Gray
      const Color(0xFF2D2D44),      // Warm Gray
      const Color(0xFF4A4A6A),      // Soft Purple-Gray
      const Color(0xFF0F172A),      // Ocean View Blue
      const Color(0xFF1E293B),      // Medium Ocean
      const Color(0xFF334155),      // Light Ocean
      const Color(0xFF1A1A1A),      // Modern Glass Dark
      const Color(0xFF2A2A2A),      // Modern Glass Medium
      const Color(0xFF3A3A3A),      // Modern Glass Light
      const Color(0xFF0A1929),      // Frosted Blue Dark
      const Color(0xFF1A2332),      // Frosted Blue Medium
      const Color(0xFF2A3441),      // Frosted Blue Light
    ];
    
    final currentIndex = colors.indexOf(currentColor);
    final nextIndex = (currentIndex + 1) % colors.length;
    onColorChanged(colors[nextIndex]);
  }
}
