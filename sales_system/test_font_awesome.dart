import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'lib/services/pdf/pdf_service.dart';
import 'lib/models/invoice.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Create a test invoice
  final testInvoice = Invoice(
    invoiceNumber: 'INV-000001',
    invoiceDate: DateTime.now(),
    stockNo: 'STK123',
    vehicleMake: 'Toyota',
    vehicleModel: 'Corolla',
    chassisNo: 'CH123456',
    engineSize: '1800',
    fuelType: 'Petrol',
    vehicleYear: 2020,
    carPriceUSD: 10000,
    exchangeRate: 3700,
    firstInstallmentUGX: 3700000,
    taxesURA: 5000000,
    numberPlatesFee: 714300,
    agencyFees: 400000,
    notes: 'Phase 1 Total: 3700000\nC&F Kampala: Selected',
  );

  try {
    final pdfService = PDFService();
    final pdfBytes = await pdfService.generateInvoicePDF(testInvoice);
    
    print('✅ Font Awesome PDF generated successfully!');
    print('📄 PDF size: ${pdfBytes.length} bytes');
    print('🎨 Icons included: Location, WhatsApp, Gmail, Facebook, X/Twitter, TikTok, Instagram');
    
    // Save to file for testing
    final pdfPath = await pdfService.savePDFToFile(testInvoice);
    print('💾 PDF saved to: $pdfPath');
    
  } catch (e) {
    print('❌ Error generating PDF: $e');
    print('📝 Make sure Font Awesome fonts are in assets/fonts/');
    print('   - fa-brands-400.ttf');
    print('   - fa-solid-900.ttf');
  }
}
