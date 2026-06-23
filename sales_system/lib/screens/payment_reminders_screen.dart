import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/payment_reminder_provider.dart';
import '../providers/customer_provider.dart';
import '../models/payment_reminder.dart';
import '../models/customer.dart';
import '../utils/uganda_formatters.dart';
import '../widgets/glass_container.dart';
import 'payment_reminders/payment_reminder_form_screen.dart';
import 'payment_reminders/payment_reminder_detail_screen.dart';
import '../providers/theme_provider.dart';
import '../widgets/glass_liquid_theme.dart';

class PaymentRemindersScreen extends StatefulWidget {
  const PaymentRemindersScreen({super.key});

  @override
  State<PaymentRemindersScreen> createState() => _PaymentRemindersScreenState();
}

class _PaymentRemindersScreenState extends State<PaymentRemindersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReminders();
    });
  }

  void _loadReminders() {
    Provider.of<PaymentReminderProvider>(context, listen: false).loadReminders();
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildSearchAndFilters(),
                const SizedBox(height: 24),
                Expanded(
                  child: _buildRemindersList(),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PaymentReminderFormScreen(),
            ),
          ).then((_) => _loadReminders());
        },
        backgroundColor: Colors.purple,
        child: const FaIcon(
          FontAwesomeIcons.plus,
          color: Colors.white,
        ),
      ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          FontAwesomeIcons.bell,
          size: 32,
          color: Colors.white,
        ),
        const SizedBox(width: 12),
        Text(
          'Payment Reminders',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        Consumer<PaymentReminderProvider>(
          builder: (context, provider, child) {
            return Text(
              '${provider.reminders.length} Reminders',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Consumer<PaymentReminderProvider>(
      builder: (context, provider, child) {
        return Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  onChanged: provider.searchReminders,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search reminders...',
                    hintStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.6)),
                    prefixIcon: const FaIcon(
                      FontAwesomeIcons.magnifyingGlass,
                      color: Colors.white,
                      size: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _buildFilterButton(provider),
          ],
        );
      },
    );
  }

  Widget _buildFilterButton(PaymentReminderProvider provider) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const FaIcon(
          FontAwesomeIcons.filter,
          color: Colors.white,
          size: 16,
        ),
      ),
      onSelected: (value) {
        if (value == 'all') {
          provider.filterByStatus(null);
        } else {
          provider.filterByStatus(ReminderStatus.values.firstWhere(
            (status) => status.name == value,
          ));
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'all',
          child: Text('All Status'),
        ),
        const PopupMenuItem(
          value: 'scheduled',
          child: Text('Scheduled'),
        ),
        const PopupMenuItem(
          value: 'sent',
          child: Text('Sent'),
        ),
        const PopupMenuItem(
          value: 'delivered',
          child: Text('Delivered'),
        ),
        const PopupMenuItem(
          value: 'failed',
          child: Text('Failed'),
        ),
        const PopupMenuItem(
          value: 'cancelled',
          child: Text('Cancelled'),
        ),
      ],
    );
  }

  Widget _buildRemindersList() {
    return Consumer<PaymentReminderProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        }

        if (provider.reminders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FontAwesomeIcons.bell,
                  size: 80,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Payment Reminders',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first payment reminder',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: provider.filteredReminders.length,
          itemBuilder: (context, index) {
            final reminder = provider.filteredReminders[index];
            return _buildReminderCard(reminder);
          },
        );
      },
    );
  }

  Widget _buildReminderCard(PaymentReminder reminder) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentReminderDetailScreen(paymentReminder: reminder),
              ),
            ).then((_) => _loadReminders());
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Consumer<CustomerProvider>(
              builder: (context, customerProvider, child) {
                final customer = customerProvider.customers.firstWhere(
                  (c) => c.id == reminder.customerId,
                  orElse: () => Customer(id: 0, name: 'Unknown', email: '', phone: ''),
                );
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Customer: ${customer.name}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                reminder.reminderNumber,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                reminder.subject,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildStatusChip(reminder.status),
                      ],
                    ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        _getTypeIcon(reminder.type),
                        'Type',
                        reminder.typeText,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        FontAwesomeIcons.calendar,
                        'Scheduled',
                        UgandaFormatters.formatDate(reminder.scheduledDate),
                      ),
                    ),
                    if (reminder.sentDate != null)
                      Expanded(
                        child: _buildInfoItem(
                          FontAwesomeIcons.check,
                          'Sent',
                          UgandaFormatters.formatDate(reminder.sentDate!),
                        ),
                      ),
                  ],
                ),
                if (reminder.isRecurring) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: GlassLiquidTheme.accentBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.rotate,
                          size: 12,
                          color: GlassLiquidTheme.accentBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Recurring (${reminder.frequency.name})',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: GlassLiquidTheme.accentBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FaIcon(
              icon,
              size: 12,
              color: Colors.white.withOpacity(0.6),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(ReminderStatus status) {
    Color statusColor;
    switch (status) {
      case ReminderStatus.scheduled:
        statusColor = GlassLiquidTheme.accentBlue;
        break;
      case ReminderStatus.sent:
        statusColor = Colors.orange;
        break;
      case ReminderStatus.delivered:
        statusColor = Colors.green;
        break;
      case ReminderStatus.failed:
        statusColor = Colors.red;
        break;
      case ReminderStatus.cancelled:
        statusColor = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: statusColor,
        ),
      ),
    );
  }

  IconData _getTypeIcon(ReminderType type) {
    switch (type) {
      case ReminderType.email:
        return FontAwesomeIcons.envelope;
      case ReminderType.sms:
        return FontAwesomeIcons.sms;
      case ReminderType.whatsapp:
        return FontAwesomeIcons.whatsapp;
      case ReminderType.phone:
        return FontAwesomeIcons.phone;
      case ReminderType.letter:
        return FontAwesomeIcons.fileLines;
    }
  }
}