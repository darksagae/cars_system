import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/sales_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/glass_liquid_theme.dart';
import 'glass_dashboard_screen.dart';
import 'customers_screen.dart';
import 'invoices_screen.dart';
import 'enhanced_payments_screen.dart';
// Vehicles module removed - using URA database instead
import 'enhanced_demand_letters_screen.dart';
import 'enhanced_reminders_screen.dart';
// import 'ura_search_screen.dart'; // Removed - URA search now embedded in invoices
// import 'pdf_import_screen.dart'; // Removed - no longer needed
import 'enhanced_reports_screen.dart';
import 'theme_screen.dart';
import 'contact_forwarding_screen.dart';
import '../services/whatsapp_message_tracking_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _selectedIndex = 0;
  int? _hoveredNavIndex;
  
  // User profile state
  String _userName = 'Admin User';
  String _userEmail = 'admin@example.com';
  String? _userPhone;
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _loadUserProfile();
  }
  
  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_profile_name') ?? 'Admin User';
      _userEmail = prefs.getString('user_profile_email') ?? 'admin@example.com';
      _userPhone = prefs.getString('user_profile_phone');
      _profileImagePath = prefs.getString('user_profile_image_path');
    });
    
    // Update WhatsApp tracking service with user profile
    try {
      final trackingService = WhatsAppMessageTrackingService();
      await trackingService.setUserProfile(
        userId: _userEmail,
        userName: _userName,
        userPhone: _userPhone,
      );
    } catch (e) {
      print('Error updating WhatsApp tracking profile: $e');
    }
  }
  
  Future<void> _saveUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile_name', _userName);
    await prefs.setString('user_profile_email', _userEmail);
    if (_userPhone != null && _userPhone!.isNotEmpty) {
      await prefs.setString('user_profile_phone', _userPhone!);
    }
    if (_profileImagePath != null) {
      await prefs.setString('user_profile_image_path', _profileImagePath!);
    }
    
    // Update WhatsApp tracking service
    try {
      final trackingService = WhatsAppMessageTrackingService();
      await trackingService.setUserProfile(
        userId: _userEmail,
        userName: _userName,
        userPhone: _userPhone,
      );
    } catch (e) {
      print('Error updating WhatsApp tracking profile: $e');
    }
  }
  
  Future<void> _pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      // Copy image to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'profile_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = File('${appDir.path}/$fileName');
      await File(image.path).copy(savedImage.path);
      
      setState(() {
        _profileImagePath = savedImage.path;
      });
      await _saveUserProfile();
    }
  }
  
  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _userName);
    final emailController = TextEditingController(text: _userEmail);
    final phoneController = TextEditingController(text: _userPhone ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile Picture
              GestureDetector(
                onTap: _pickProfileImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      backgroundImage: _profileImagePath != null 
                          ? FileImage(File(_profileImagePath!)) 
                          : null,
                      child: _profileImagePath == null
                          ? const FaIcon(
                              FontAwesomeIcons.user,
                              color: Colors.white,
                              size: 40,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Username field
              TextField(
                controller: nameController,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: GoogleFonts.poppins(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Phone field
              TextField(
                controller: phoneController,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: GoogleFonts.poppins(color: Colors.white70),
                  hintText: 'e.g., 0751234567',
                  hintStyle: GoogleFonts.poppins(color: Colors.white38),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              // Email field
              TextField(
                controller: emailController,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: GoogleFonts.poppins(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _userName = nameController.text.trim();
                _userEmail = emailController.text.trim();
                _userPhone = phoneController.text.trim();
              });
              _saveUserProfile();
              Navigator.pop(context);
            },
            child: Text(
              'Save',
              style: GoogleFonts.poppins(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: themeProvider.backgroundGradient,
                ),
            child: SafeArea(
              child: Row(
                children: [
                  _buildSidebar(),
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildMainContent(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLogo(),
                const SizedBox(height: 40),
                Expanded(
                  child: _buildNavigationItems(),
                ),
                _buildUserInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NSB Motors Ug',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Vehicle Sales Management',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationItems() {
    final navigationItems = [
      {'icon': FontAwesomeIcons.house, 'title': 'Dashboard', 'index': 0},
      {'icon': FontAwesomeIcons.users, 'title': 'Customers', 'index': 1},
      {'icon': FontAwesomeIcons.fileInvoice, 'title': 'Invoices & Quotes', 'index': 2},
      {'icon': FontAwesomeIcons.creditCard, 'title': 'Payments', 'index': 3},
      {'icon': FontAwesomeIcons.fileLines, 'title': 'Demand Letters', 'index': 4},
      {'icon': FontAwesomeIcons.bell, 'title': 'Reminders', 'index': 5},
      {'icon': FontAwesomeIcons.chartBar, 'title': 'Reports', 'index': 6},
      {'icon': FontAwesomeIcons.palette, 'title': 'Theme', 'index': 7},
      {'icon': FontAwesomeIcons.whatsapp, 'title': 'WhatsApp', 'index': 8},
    ];

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: navigationItems.map((item) {
        final isSelected = _selectedIndex == item['index'];
        return Consumer<SalesProvider>(
          builder: (context, salesProvider, child) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedIndex = item['index'] as int;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  onHover: (isHovering) {
                    setState(() {
                      _hoveredNavIndex = isHovering ? item['index'] as int : null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: (_hoveredNavIndex == item['index'])
                          ? const Color(0xFFFFF1E6)
                          : (isSelected ? Colors.white.withOpacity(0.14) : Colors.transparent),
                      borderRadius: BorderRadius.circular(12),
                      border: (_hoveredNavIndex == item['index'])
                          ? Border.all(color: const Color(0xFFFFE4C7), width: 1)
                          : (isSelected ? Border.all(color: Colors.white.withOpacity(0.4), width: 1) : null),
                      boxShadow: (_hoveredNavIndex == item['index'])
                          ? [
                              BoxShadow(
                                color: const Color(0xFFFFE4C7).withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : (isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null),
                    ),
                    child: Row(
                      children: [
                        FaIcon(
                          item['icon'] as IconData,
                          color: (_hoveredNavIndex == item['index'])
                              ? Colors.black
                              : (isSelected ? Colors.white : Colors.white.withOpacity(0.7)),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item['title'] as String,
                          style: GoogleFonts.poppins(
                            color: (_hoveredNavIndex == item['index'])
                                ? Colors.black
                                : (isSelected ? Colors.white : Colors.white.withOpacity(0.7)),
                            fontWeight: (isSelected || _hoveredNavIndex == item['index'])
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return GestureDetector(
      onTap: _showEditProfileDialog,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      backgroundImage: _profileImagePath != null 
                          ? FileImage(File(_profileImagePath!)) 
                          : null,
                      child: _profileImagePath == null
                          ? const FaIcon(
                              FontAwesomeIcons.user,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _userEmail,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      if (_userPhone != null && _userPhone!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.phone,
                              size: 10,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _userPhone!,
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const FaIcon(
                  FontAwesomeIcons.pencil,
                  color: Colors.white70,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Consumer<SalesProvider>(
      builder: (context, salesProvider, child) {
        switch (_selectedIndex) {
          case 0:
            return const GlassDashboardScreen();
          case 1:
            return const CustomersScreen();
          case 2:
            return const InvoicesScreen();
          case 3:
            return EnhancedPaymentsScreen();
          case 4:
            return EnhancedDemandLettersScreen();
          case 5:
            return const EnhancedRemindersScreen();
          case 6:
            return EnhancedReportsScreen();
          case 7:
            return const ThemeScreen();
          case 8:
            return ContactForwardingScreen(
              onClose: () {
                setState(() {
                  _selectedIndex = 0;
                });
              },
            );
          default:
            return const GlassDashboardScreen();
        }
      },
    );
  }
}