
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../widgets/glass_container.dart';
import '../widgets/glass_liquid_theme.dart';
import '../models/customer.dart';
import '../models/invoice_type.dart';
import '../utils/uganda_formatters.dart';
import '../services/whatsapp_service.dart';
import '../services/customer_service.dart';
import '../services/email_service.dart';
import 'invoice_form_screen.dart';
import 'invoices_screen.dart';
import '../providers/theme_provider.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  late Customer _customer;
  final CustomerService _customerService = CustomerService();

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _refreshCustomerData();
  }

  Future<void> _refreshCustomerData() async {
    try {
      await _customerService.updateCustomerStats(_customer.id!);
      // Reload customer data to get updated statistics
      final updatedCustomer = await _customerService.getCustomerById(_customer.id!);
      if (updatedCustomer != null && mounted) {
        setState(() {
          _customer = updatedCustomer;
        });
      }
    } catch (e) {
      print('Error refreshing customer data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: GlassLiquidTheme.currentBackground,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildCustomerInfo(),
                      const SizedBox(height: 24),
                      _buildFinancialInfo(),
                      const SizedBox(height: 24),
                      _buildQuickActions(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(12),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Image.asset(
            'assets/logo/logo.png',
            height: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _customer.displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _customer.email,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showEditDialog(context),
                borderRadius: BorderRadius.circular(12),
                child: const FaIcon(
                  FontAwesomeIcons.pen,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _showImageOptions(),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  radius: 32,
                  backgroundImage: _customer.profileImage.isNotEmpty 
                      ? FileImage(File(_customer.profileImage))
                      : null,
                  child: _customer.profileImage.isEmpty
                      ? Text(
                          _customer.name.isNotEmpty ? _customer.name[0].toUpperCase() : '?',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _customer.displayName,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _customer.email,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _customer.phone,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoRow('Company', _customer.company.isNotEmpty ? _customer.company : 'Not specified'),
          _buildInfoRow('Address', _customer.fullAddress.isNotEmpty ? _customer.fullAddress : 'Not specified'),
          if (_customer.notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow('Notes', _customer.notes),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialInfo() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Information',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildFinancialCard(
                  'Total Spent',
                  UgandaFormatters.formatCurrency(_customer.totalSpent),
                  GlassLiquidTheme.accentGreen,
                  FontAwesomeIcons.dollarSign,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFinancialCard(
                  'Total Invoices',
                  '${_customer.totalInvoices}',
                  GlassLiquidTheme.accentBlue,
                  FontAwesomeIcons.fileInvoice,
                ),
              ),
            ],
          ),
          if (_customer.balance > 0) ...[
            const SizedBox(height: 16),
            _buildFinancialCard(
              'Outstanding Balance',
              UgandaFormatters.formatCurrency(_customer.balance),
              GlassLiquidTheme.error,
              FontAwesomeIcons.exclamationTriangle,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          FaIcon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Create Invoice',
                  FontAwesomeIcons.plus,
                  GlassLiquidTheme.accentBlue,
                  () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InvoiceFormScreen(
                          customer: _customer,
                          type: InvoiceType.invoice,
                        ),
                      ),
                    );
                    // Refresh customer data after creating invoice
                    _refreshCustomerData();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Send Email',
                  FontAwesomeIcons.envelope,
                  GlassLiquidTheme.accentGreen,
                  () => _sendEmailToCustomer(context, _customer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'WhatsApp',
                  FontAwesomeIcons.whatsapp,
                  GlassLiquidTheme.accentGreen,
                  () => _sendWhatsAppToCustomer(context, _customer),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'View Invoices',
                  FontAwesomeIcons.list,
                  GlassLiquidTheme.accentOrange,
                  () => _viewCustomerInvoices(context, _customer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Refresh Data',
                  FontAwesomeIcons.refresh,
                  GlassLiquidTheme.accentPurple,
                  () => _refreshCustomerData(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              FaIcon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit Customer',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Edit functionality will be available in the next update.',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlassLiquidTheme.accentBlue,
                ),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: GlassLiquidTheme.glassPrimary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Update Profile Image',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                  leading: FaIcon(FontAwesomeIcons.image, color: GlassLiquidTheme.accentBlue),
                    title: Text(
                      'Gallery',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _pickProfileImage();
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                  leading: FaIcon(FontAwesomeIcons.camera, color: GlassLiquidTheme.accentGreen),
                    title: Text(
                      'Camera',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _takeProfilePhoto();
                    },
                  ),
                ),
              ],
            ),
            if (_customer.profileImage.isNotEmpty) ...[
              const Divider(color: Colors.white24),
              ListTile(
                leading: FaIcon(FontAwesomeIcons.trash, color: GlassLiquidTheme.error),
                title: Text(
                  'Remove Image',
                  style: GoogleFonts.poppins(color: GlassLiquidTheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removeProfileImage();
                },
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _removeProfileImage() async {
    try {
      final updatedCustomer = _customer.copyWith(profileImage: '');
      final success = await _customerService.updateCustomer(updatedCustomer);
      
      if (success > 0) {
        setState(() {
          _customer = updatedCustomer;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile image removed successfully'),
            backgroundColor: GlassLiquidTheme.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to remove profile image'),
            backgroundColor: GlassLiquidTheme.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing image: ${e.toString()}'),
          backgroundColor: GlassLiquidTheme.error,
        ),
      );
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null) {
        // Update customer with new profile image
        final updatedCustomer = _customer.copyWith(profileImage: image.path);
        final success = await _customerService.updateCustomer(updatedCustomer);
        
        if (success > 0) {
          setState(() {
            _customer = updatedCustomer;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile image updated successfully'),
              backgroundColor: GlassLiquidTheme.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to update profile image'),
              backgroundColor: GlassLiquidTheme.error,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: ${e.toString()}'),
          backgroundColor: GlassLiquidTheme.error,
        ),
      );
    }
  }

  Future<void> _takeProfilePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null) {
        // Update customer with new profile image
        final updatedCustomer = _customer.copyWith(profileImage: image.path);
        final success = await _customerService.updateCustomer(updatedCustomer);
        
        if (success > 0) {
          setState(() {
            _customer = updatedCustomer;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile image updated successfully'),
              backgroundColor: GlassLiquidTheme.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to update profile image'),
              backgroundColor: GlassLiquidTheme.error,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error taking photo: ${e.toString()}'),
          backgroundColor: GlassLiquidTheme.error,
        ),
      );
    }
  }

  void _sendWhatsAppToCustomer(BuildContext context, Customer customer) async {
    try {
      if (_customer.phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Customer phone number is required for WhatsApp',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: GlassLiquidTheme.warning,
          ),
        );
        return;
      }

      final whatsappService = WhatsAppService();
      final message = '''
🏢 NSB Motors Ug
👋 Hello ${_customer.name}!

📊 *Your Account Summary:*
💰 Total Spent: ${UgandaFormatters.formatCurrency(_customer.totalSpent)}
📄 Total Invoices: ${_customer.totalInvoices}
💳 Current Balance: ${UgandaFormatters.formatCurrency(_customer.balance)}

Thank you for choosing NSB Motors Ug!

How can we assist you today?

For any inquiries, please contact us at +256394836253.

Best regards,
NSB Motors Ug Team
''';

      final success = await whatsappService.sendMessage(
        phoneNumber: _customer.phone,
        message: message,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'WhatsApp message sent successfully' : 'Failed to send WhatsApp message',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: success ? GlassLiquidTheme.success : GlassLiquidTheme.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error sending WhatsApp message: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: GlassLiquidTheme.error,
          ),
        );
      }
    }
  }

  void _viewCustomerInvoices(BuildContext context, Customer customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoicesScreen(customerFilter: customer),
      ),
    );
  }

  void _sendEmailToCustomer(BuildContext context, Customer customer) async {
    try {
      if (customer.email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Customer email is required for sending email',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: GlassLiquidTheme.warning,
          ),
        );
        return;
      }

      final emailService = EmailService();
      
      // Check if email is configured (async)
      if (!(await emailService.isConfigured)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Email service not configured. Please configure email settings first.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Send a general email to the customer
      final success = await emailService.sendInvoiceEmail(
        recipientEmail: customer.email,
        recipientName: customer.name,
        invoiceNumber: 'GENERAL',
        invoiceDate: UgandaFormatters.formatDate(DateTime.now()),
        totalAmount: customer.totalSpent,
        companyName: 'NSB Motors Ug',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Email sent successfully' : 'Failed to send email',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: success ? GlassLiquidTheme.success : GlassLiquidTheme.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error sending email: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: GlassLiquidTheme.error,
          ),
        );
      }
    }
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature coming soon!',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: GlassLiquidTheme.info.withOpacity(0.8),
      ),
    );
  }
}
