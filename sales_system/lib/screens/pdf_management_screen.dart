import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/dynamic_pdf_search.dart';
import '../models/ura_vehicle.dart';
import '../providers/theme_provider.dart';
import '../widgets/glass_liquid_theme.dart';

class PdfManagementScreen extends StatefulWidget {
  const PdfManagementScreen({Key? key}) : super(key: key);

  @override
  State<PdfManagementScreen> createState() => _PdfManagementScreenState();
}

class _PdfManagementScreenState extends State<PdfManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        title: Text(
          'Dynamic PDF Search',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: GlassLiquidTheme.accentBlue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: GlassLiquidTheme.accentBlue, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dynamic PDF Search',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Type any car info and progressively narrow down results',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Dynamic PDF Search Widget
            DynamicPdfSearch(
              onVehicleSelected: (vehicle) {
                Navigator.pop(context, vehicle);
              },
            ),
          ],
        ),
      ),
    );
  }
}