import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/customer_provider.dart';
import '../providers/vehicle_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/payment_provider.dart';
import '../providers/theme_provider.dart';
import '../models/customer.dart';
import '../models/vehicle.dart';
import '../models/invoice.dart';
import '../models/payment.dart';
import '../widgets/glass_liquid_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_dashboard_cards.dart';
import '../services/cloud_api_service.dart';
import '../services/cloud_sync_notifier.dart';
import 'customer_form_screen.dart';
import 'invoice_form_screen.dart';
import 'vehicles/vehicle_form_screen.dart';
import 'reports_screen.dart';

// Helper classes for recent activity
enum _ActivityType {
  invoice,
  payment,
  customer,
  vehicle,
}

class _ActivityItem {
  final _ActivityType type;
  final String title;
  final String subtitle;
  final DateTime date;
  final IconData icon;
  final Color color;

  _ActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.icon,
    required this.color,
  });
}

class GlassDashboardScreen extends StatefulWidget {
  const GlassDashboardScreen({super.key});

  @override
  State<GlassDashboardScreen> createState() => _GlassDashboardScreenState();
}

class _GlassDashboardScreenState extends State<GlassDashboardScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  
  late AnimationController _headerAnimationController;
  late AnimationController _cardsAnimationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _cardsAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    CloudSyncNotifier.instance.addListener(_onCloudInvoicesSynced);
    
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _cardsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _cardsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardsAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CloudApiService().ensureCloudConnectionActive();
      _loadData();
      _headerAnimationController.forward();
      Future.delayed(const Duration(milliseconds: 200), () {
        _cardsAnimationController.forward();
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    CloudSyncNotifier.instance.removeListener(_onCloudInvoicesSynced);
    _headerAnimationController.dispose();
    _cardsAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  void _onCloudInvoicesSynced() {
    if (!mounted) return;
    Provider.of<InvoiceProvider>(context, listen: false).loadInvoices();
  }

  void _loadData() {
    print('Dashboard: Loading data...');
    Provider.of<CustomerProvider>(context, listen: false).loadCustomers();
    Provider.of<VehicleProvider>(context, listen: false).loadVehicles();
    Provider.of<InvoiceProvider>(context, listen: false).loadInvoices();
    Provider.of<PaymentProvider>(context, listen: false).loadPayments();
    print('Dashboard: Data loading completed');
  }

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
              child: Padding(
                padding: const EdgeInsets.all(GlassLiquidTheme.spacingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: GlassLiquidTheme.spacingLarge),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildStatsCards(),
                            const SizedBox(height: GlassLiquidTheme.spacingLarge),
                            _buildRecentActivity(),
                            const SizedBox(height: GlassLiquidTheme.spacingLarge),
                            _buildQuickActions(),
                            const SizedBox(height: GlassLiquidTheme.spacingLarge),
                            _buildProgressCards(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _headerAnimation.value)),
          child: Opacity(
            opacity: _headerAnimation.value,
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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(GlassLiquidTheme.spacingSmall),
                    decoration: BoxDecoration(
                      color: GlassLiquidTheme.accentBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(GlassLiquidTheme.radiusSmall),
                    ),
                    child: FaIcon(
                      FontAwesomeIcons.chartLine,
                      color: GlassLiquidTheme.accentBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: GlassLiquidTheme.spacingMedium),
                  Text(
                    'Dashboard',
                    style: GlassLiquidTheme.heading2,
                  ),
                  const Spacer(),
                  GlassButton(
                    onPressed: _loadData,
                    backgroundColor: GlassLiquidTheme.glassSecondary,
                    borderColor: GlassLiquidTheme.glassBorder,
                    padding: const EdgeInsets.all(GlassLiquidTheme.spacingSmall),
                    child: FaIcon(
                      FontAwesomeIcons.arrowsRotate,
                      color: GlassLiquidTheme.textPrimary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: GlassLiquidTheme.spacingSmall),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: GlassLiquidTheme.spacingMedium,
                      vertical: GlassLiquidTheme.spacingSmall,
                    ),
                    decoration: BoxDecoration(
                      color: GlassLiquidTheme.accentGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(GlassLiquidTheme.radiusMedium),
                      border: Border.all(
                        color: GlassLiquidTheme.accentGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      DateTime.now().toString().split(' ')[0],
                      style: GlassLiquidTheme.bodyMedium.copyWith(
                        color: GlassLiquidTheme.accentGreen,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildStatsCards() {
    return Consumer4<CustomerProvider, VehicleProvider, InvoiceProvider, PaymentProvider>(
      builder: (context, customerProvider, vehicleProvider, invoiceProvider, paymentProvider, child) {
        return AnimatedBuilder(
          animation: _cardsAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - _cardsAnimation.value)),
              child: Opacity(
                opacity: _cardsAnimation.value,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GlassStatCard(
                            title: 'Customers',
                            value: customerProvider.customers.length.toString(),
                            icon: FontAwesomeIcons.users,
                            color: GlassLiquidTheme.accentBlue,
                            animationDelay: 0,
                            onTap: () {
                              // Navigate to customers screen
                            },
                          ),
                        ),
                        const SizedBox(width: GlassLiquidTheme.spacingMedium),
                        Expanded(
                          child: GlassStatCard(
                            title: 'Vehicles',
                            value: vehicleProvider.vehicles.length.toString(),
                            icon: FontAwesomeIcons.car,
                            color: GlassLiquidTheme.accentGreen,
                            animationDelay: 100,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: GlassLiquidTheme.spacingMedium),
                    Row(
                      children: [
                        Expanded(
                          child: GlassStatCard(
                            title: 'Invoices',
                            value: invoiceProvider.invoices.length.toString(),
                            icon: FontAwesomeIcons.fileInvoice,
                            color: GlassLiquidTheme.accentOrange,
                            animationDelay: 200,
                          ),
                        ),
                        const SizedBox(width: GlassLiquidTheme.spacingMedium),
                        Expanded(
                          child: GlassStatCard(
                            title: 'Payments',
                            value: paymentProvider.payments.length.toString(),
                            icon: FontAwesomeIcons.creditCard,
                            color: GlassLiquidTheme.accentPurple,
                            animationDelay: 300,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecentActivity() {
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
          Text(
            'Recent Activity',
            style: GlassLiquidTheme.heading3,
          ),
          const SizedBox(height: GlassLiquidTheme.spacingMedium),
          Consumer4<CustomerProvider, VehicleProvider, InvoiceProvider, PaymentProvider>(
            builder: (context, customerProvider, vehicleProvider, invoiceProvider, paymentProvider, child) {
              // Create a list to hold all activities
              final List<_ActivityItem> activities = [];
              
              // Add invoices (sorted by createdAt DESC, take top 5)
              final invoices = List<Invoice>.from(invoiceProvider.invoices)
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
              for (final invoice in invoices.take(5)) {
                activities.add(_ActivityItem(
                  type: _ActivityType.invoice,
                  title: 'Invoice created',
                  subtitle: 'Invoice #${invoice.invoiceNumber}',
                  date: invoice.createdAt,
                  icon: FontAwesomeIcons.fileInvoice,
                  color: GlassLiquidTheme.accentOrange,
                ));
              }
              
              // Add payments (sorted by paymentDate DESC, take top 5)
              final payments = List<Payment>.from(paymentProvider.payments)
                ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
              for (final payment in payments.take(5)) {
                final invoice = invoiceProvider.invoices.firstWhere(
                  (inv) => inv.id == payment.invoiceId,
                  orElse: () => Invoice.empty(),
                );
                activities.add(_ActivityItem(
                  type: _ActivityType.payment,
                  title: 'Payment received',
                  subtitle: 'UGX ${_formatNumber(payment.amount)} - Invoice #${invoice.invoiceNumber.isNotEmpty ? invoice.invoiceNumber : payment.id}',
                  date: payment.paymentDate,
                  icon: FontAwesomeIcons.moneyBill,
                  color: GlassLiquidTheme.accentGreen,
                ));
              }
              
              // Add customers (sorted by createdAt DESC, take top 5)
              final customers = List<Customer>.from(customerProvider.customers)
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
              for (final customer in customers.take(5)) {
                activities.add(_ActivityItem(
                  type: _ActivityType.customer,
                  title: 'New customer added',
                  subtitle: customer.name,
                  date: customer.createdAt,
                  icon: FontAwesomeIcons.userPlus,
                  color: GlassLiquidTheme.accentBlue,
                ));
              }
              
              // Add vehicles (sorted by createdAt DESC, take top 5)
              final vehicles = List<Vehicle>.from(vehicleProvider.vehicles)
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
              for (final vehicle in vehicles.take(5)) {
                activities.add(_ActivityItem(
                  type: _ActivityType.vehicle,
                  title: 'Vehicle added',
                  subtitle: vehicle.name,
                  date: vehicle.createdAt,
                  icon: FontAwesomeIcons.car,
                  color: GlassLiquidTheme.accentGreen,
                ));
              }
              
              // Sort all activities by date (newest first) and take top 8
              activities.sort((a, b) => b.date.compareTo(a.date));
              final recentActivities = activities.take(8).toList();
              
              if (recentActivities.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(GlassLiquidTheme.spacingLarge),
                  child: Text(
                    'No recent activity',
                    style: GlassLiquidTheme.bodyMedium.copyWith(
                      color: GlassLiquidTheme.textTertiary,
                    ),
                  ),
                );
              }
              
              return Column(
                children: recentActivities.map((activity) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: GlassLiquidTheme.spacingSmall),
                    child: GlassActivityCard(
                      title: activity.title,
                      subtitle: activity.subtitle,
                      icon: activity.icon,
                      color: activity.color,
                      time: _formatTimeAgo(activity.date),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return '1 day ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return months == 1 ? '1 month ago' : '$months months ago';
      } else {
        final years = (difference.inDays / 365).floor();
        return years == 1 ? '1 year ago' : '$years years ago';
      }
    } else if (difference.inHours > 0) {
      return difference.inHours == 1 
          ? '1 hour ago' 
          : '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1 
          ? '1 minute ago' 
          : '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toStringAsFixed(0);
    }
  }

  Widget _buildQuickActions() {
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
          Text(
            'Quick Actions',
            style: GlassLiquidTheme.heading3,
          ),
          const SizedBox(height: GlassLiquidTheme.spacingMedium),
          Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GlassQuickActionCard(
                  title: 'Add Customer',
                  icon: FontAwesomeIcons.userPlus,
                  color: GlassLiquidTheme.accentBlue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CustomerFormScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: GlassLiquidTheme.spacingMedium),
              Expanded(
                child: GlassQuickActionCard(
                  title: 'Create Invoice',
                  icon: FontAwesomeIcons.fileInvoice,
                  color: GlassLiquidTheme.accentOrange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InvoiceFormScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: GlassLiquidTheme.spacingMedium),
          Row(
            children: [
              Expanded(
                child: GlassQuickActionCard(
                  title: 'Add Vehicle',
                  icon: FontAwesomeIcons.car,
                  color: GlassLiquidTheme.accentGreen,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VehicleFormScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: GlassLiquidTheme.spacingMedium),
              Expanded(
                child: GlassQuickActionCard(
                  title: 'View Reports',
                  icon: FontAwesomeIcons.chartBar,
                  color: GlassLiquidTheme.accentPurple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReportsScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          ],
        ),
        ],
      ),
    );
  }

  Widget _buildProgressCards() {
    return Consumer4<CustomerProvider, VehicleProvider, InvoiceProvider, PaymentProvider>(
      builder: (context, customerProvider, vehicleProvider, invoiceProvider, paymentProvider, child) {
        final totalCustomers = customerProvider.customers.length;
        final totalVehicles = vehicleProvider.vehicles.length;
        final totalInvoices = invoiceProvider.invoices.length;
        final totalPayments = paymentProvider.payments.length;
        
        final maxValue = [totalCustomers, totalVehicles, totalInvoices, totalPayments]
            .reduce((a, b) => a > b ? a : b);
        
        return Column(
          children: [
            GlassProgressCard(
              title: 'Sales Progress',
              progress: maxValue > 0 ? (totalInvoices / (maxValue * 2)).clamp(0.0, 1.0) : 0.0,
              progressText: '${totalInvoices} invoices',
              color: GlassLiquidTheme.accentBlue,
              icon: FontAwesomeIcons.chartLine,
            ),
            const SizedBox(height: GlassLiquidTheme.spacingMedium),
            GlassProgressCard(
              title: 'Customer Growth',
              progress: maxValue > 0 ? (totalCustomers / (maxValue * 2)).clamp(0.0, 1.0) : 0.0,
              progressText: '${totalCustomers} customers',
              color: GlassLiquidTheme.accentGreen,
              icon: FontAwesomeIcons.users,
            ),
          ],
        );
      },
    );
  }
}
