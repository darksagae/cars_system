import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/background/background_service.dart';
import '../../widgets/glass_container.dart';
import '../widgets/glass_liquid_theme.dart';

class BackgroundSettingsScreen extends StatefulWidget {
  const BackgroundSettingsScreen({super.key});

  @override
  State<BackgroundSettingsScreen> createState() => _BackgroundSettingsScreenState();
}

class _BackgroundSettingsScreenState extends State<BackgroundSettingsScreen> {
  final BackgroundService _backgroundService = BackgroundService();
  final ImagePicker _imagePicker = ImagePicker();
  
  BackgroundDisplayInfo? _backgroundInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBackgroundInfo();
  }

  void _loadBackgroundInfo() async {
    try {
      final info = await _backgroundService.getBackgroundDisplayInfo();
      setState(() {
        _backgroundInfo = info;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading background info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Background Settings',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentBackground(),
                  const SizedBox(height: 20),
                  _buildDefaultBackgrounds(),
                  const SizedBox(height: 20),
                  _buildCustomBackgrounds(),
                  const SizedBox(height: 20),
                  _buildActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentBackground() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const FaIcon(FontAwesomeIcons.image, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Current Background',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_backgroundInfo!.currentBackground.type == 'none')
              _buildNoBackgroundInfo()
            else
              _buildCurrentBackgroundPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildNoBackgroundInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const FaIcon(
            FontAwesomeIcons.square,
            color: Colors.white54,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'No Background',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pure black background',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentBackgroundPreview() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _backgroundInfo!.currentBackground.isCustom
            ? Image.file(
                File(_backgroundInfo!.currentBackground.path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildErrorPreview();
                },
              )
            : Image.asset(
                'assets/background/${_backgroundInfo!.currentBackground.path}',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildErrorPreview();
                },
              ),
      ),
    );
  }

  Widget _buildErrorPreview() {
    return Container(
      color: Colors.grey[800],
      child: const Center(
        child: FaIcon(
          FontAwesomeIcons.image,
          color: Colors.white54,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildDefaultBackgrounds() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const FaIcon(FontAwesomeIcons.folder, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Default Backgrounds',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: _backgroundInfo!.defaultBackgrounds.length,
              itemBuilder: (context, index) {
                final background = _backgroundInfo!.defaultBackgrounds[index];
                final isSelected = _backgroundInfo!.currentBackground.path == background &&
                    _backgroundInfo!.currentBackground.type == 'default';
                
                return _buildBackgroundThumbnail(
                  background,
                  isSelected,
                  () => _selectDefaultBackground(background),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomBackgrounds() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const FaIcon(FontAwesomeIcons.user, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Custom Backgrounds',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _addCustomBackground,
                  icon: const FaIcon(FontAwesomeIcons.plus, color: Colors.white, size: 16),
                  tooltip: 'Add from gallery',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_backgroundInfo!.customBackgrounds.isEmpty)
              _buildEmptyCustomBackgrounds()
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: _backgroundInfo!.customBackgrounds.length,
                itemBuilder: (context, index) {
                  final background = _backgroundInfo!.customBackgrounds[index];
                  final isSelected = _backgroundInfo!.currentBackground.path == background &&
                      _backgroundInfo!.currentBackground.type == 'custom';
                  
                  return _buildCustomBackgroundThumbnail(
                    background,
                    isSelected,
                    () => _selectCustomBackground(background),
                    () => _deleteCustomBackground(background),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCustomBackgrounds() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const FaIcon(
            FontAwesomeIcons.image,
            color: Colors.white54,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            'No Custom Backgrounds',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + to add from gallery',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundThumbnail(String background, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? GlassLiquidTheme.accentBlue : Colors.white.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Image.asset(
                background,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[800],
                    child: const Center(
                      child: FaIcon(
                        FontAwesomeIcons.image,
                        color: Colors.white54,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
              if (isSelected)
                Container(
                  color: GlassLiquidTheme.accentBlue.withOpacity(0.3),
                  child: const Center(
                    child: FaIcon(
                      FontAwesomeIcons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomBackgroundThumbnail(
    String background,
    bool isSelected,
    VoidCallback onTap,
    VoidCallback onDelete,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? GlassLiquidTheme.accentBlue : Colors.white.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Image.file(
                File(background),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[800],
                    child: const Center(
                      child: FaIcon(
                        FontAwesomeIcons.image,
                        color: Colors.white54,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
              if (isSelected)
                Container(
                  color: GlassLiquidTheme.accentBlue.withOpacity(0.3),
                  child: const Center(
                    child: FaIcon(
                      FontAwesomeIcons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.trash,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const FaIcon(FontAwesomeIcons.tools, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Actions',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _removeBackground,
                    icon: const FaIcon(FontAwesomeIcons.square, size: 16),
                    label: const Text('Remove Background'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _clearAllCustom,
                    icon: const FaIcon(FontAwesomeIcons.trash, size: 16),
                    label: const Text('Clear All Custom'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _selectDefaultBackground(String background) async {
    await _backgroundService.setDefaultBackground(background);
    _loadBackgroundInfo();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Default background selected'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _selectCustomBackground(String background) async {
    await _backgroundService.setCustomBackground(background);
    _loadBackgroundInfo();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Custom background selected'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _addCustomBackground() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        await _backgroundService.setCustomBackground(image.path);
        _loadBackgroundInfo();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Custom background added'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding background: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteCustomBackground(String background) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Background'),
        content: const Text('Are you sure you want to delete this custom background?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _backgroundService.deleteCustomBackground(background);
      _loadBackgroundInfo();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Custom background deleted'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _removeBackground() async {
    await _backgroundService.removeBackground();
    _loadBackgroundInfo();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Background removed'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _clearAllCustom() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Custom Backgrounds'),
        content: const Text('Are you sure you want to delete all custom backgrounds? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _backgroundService.clearAllCustomBackgrounds();
      _loadBackgroundInfo();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All custom backgrounds cleared'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
