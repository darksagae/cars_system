
class PaymentRemindersScreen extends StatefulWidget {
  const PaymentRemindersScreen({super.key});

  @override
  State<PaymentRemindersScreen> createState() => _PaymentRemindersScreenState();
}

class _PaymentRemindersScreenState extends State<PaymentRemindersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ReminderStatus? _filterStatus;
  ReminderType? _filterType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentReminderProvider>().loadReminders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSearchAndActions(),
          const SizedBox(height: 24),
          _buildStatsCards(),
          const SizedBox(height: 24),
          Expanded(
            child: _buildRemindersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Reminders',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage automated payment reminders',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        Row(
          children: [
            GlassContainer(
              padding: const EdgeInsets.all(12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _processDueReminders,
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.play,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Process Due',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GlassContainer(
              padding: const EdgeInsets.all(12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showAddReminderDialog,
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.plus,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add Reminder',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchAndActions() {
    return Row(
      children: [
        Expanded(
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search reminders...',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.6),
                ),
                prefixIcon: const FaIcon(
                  FontAwesomeIcons.magnifyingGlass,
                  color: Colors.white,
                  size: 16,
                ),
                border: InputBorder.none,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                context.read<PaymentReminderProvider>().searchReminders(value);
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
        GlassContainer(
          padding: const EdgeInsets.all(12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showFilterDialog,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FaIcon(
                    FontAwesomeIcons.filter,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filter',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Consumer<PaymentReminderProvider>(
      builder: (context, provider, child) {
        final stats = provider.getReminderStats();
        
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total',
                '${stats['total']}',
                FontAwesomeIcons.list,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Scheduled',
                '${stats['scheduled']}',
                FontAwesomeIcons.clock,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Sent',
                '${stats['sent']}',
                FontAwesomeIcons.check,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Failed',
                '${stats['failed']}',
                FontAwesomeIcons.xmark,
                Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          FaIcon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersList() {
    return Consumer<PaymentReminderProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final reminders = provider.filteredReminders;

        if (reminders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  FontAwesomeIcons.bell,
                  size: 64,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No reminders found',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first payment reminder',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: reminders.length,
          itemBuilder: (context, index) {
            final reminder = reminders[index];
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.subject,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reminder #${reminder.reminderNumber}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
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
                _buildInfoChip(
                  reminder.typeText,
                  _getTypeIcon(reminder.type),
                  _getTypeColor(reminder.type),
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  reminder.urgencyLevel,
                  _getUrgencyIcon(reminder.urgencyLevel),
                  _getUrgencyColor(reminder.urgencyLevel),
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  _formatDate(reminder.scheduledDate),
                  FontAwesomeIcons.calendar,
                  Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              reminder.message.length > 100 
                  ? '${reminder.message.substring(0, 100)}...'
                  : reminder.message,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Scheduled: ${_formatDateTime(reminder.scheduledDate)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _navigateToReminderDetail(reminder),
                      icon: const FaIcon(
                        FontAwesomeIcons.eye,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showReminderMenu(reminder),
                      icon: const FaIcon(
                        FontAwesomeIcons.ellipsisVertical,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(ReminderStatus status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            icon,
            color: color,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.scheduled:
        return Colors.blue;
      case ReminderStatus.sent:
        return Colors.green;
      case ReminderStatus.delivered:
        return Colors.green;
      case ReminderStatus.failed:
        return Colors.red;
      case ReminderStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(ReminderType type) {
    switch (type) {
      case ReminderType.email:
        return FontAwesomeIcons.envelope;
      case ReminderType.sms:
        return FontAwesomeIcons.message;
      case ReminderType.whatsapp:
        return FontAwesomeIcons.whatsapp;
      case ReminderType.phone:
        return FontAwesomeIcons.phone;
      case ReminderType.letter:
        return FontAwesomeIcons.fileLines;
    }
  }

  Color _getTypeColor(ReminderType type) {
    switch (type) {
      case ReminderType.email:
        return Colors.blue;
      case ReminderType.sms:
        return Colors.green;
      case ReminderType.whatsapp:
        return Colors.green;
      case ReminderType.phone:
        return Colors.orange;
      case ReminderType.letter:
        return Colors.purple;
    }
  }

  IconData _getUrgencyIcon(String urgency) {
    switch (urgency) {
      case 'Critical':
        return FontAwesomeIcons.exclamationTriangle;
      case 'High':
        return FontAwesomeIcons.exclamation;
      case 'Medium':
        return FontAwesomeIcons.info;
      case 'Low':
        return FontAwesomeIcons.check;
      default:
        return FontAwesomeIcons.circle;
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency) {
      case 'Critical':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.yellow;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _navigateToReminderDetail(PaymentReminder reminder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentReminderDetailScreen(reminder: reminder),
      ),
    );
  }

  void _showReminderMenu(PaymentReminder reminder) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.eye, color: Colors.white),
              title: Text(
                'View Details',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _navigateToReminderDetail(reminder);
              },
            ),
            if (reminder.status == ReminderStatus.scheduled) ...[
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.play, color: Colors.white),
                title: Text(
                  'Send Now',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _sendReminder(reminder);
                },
              ),
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.calendar, color: Colors.white),
                title: Text(
                  'Reschedule',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _rescheduleReminder(reminder);
                },
              ),
            ],
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.edit, color: Colors.white),
              title: Text(
                'Edit',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _editReminder(reminder);
              },
            ),
            if (reminder.status == ReminderStatus.scheduled)
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.xmark, color: Colors.red),
                title: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _cancelReminder(reminder);
                },
              ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.trash, color: Colors.red),
              title: Text(
                'Delete',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteReminder(reminder);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddReminderDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PaymentReminderFormScreen(),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Filter Reminders',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              // Status filter
              DropdownButtonFormField<ReminderStatus?>(
                value: _filterStatus,
                decoration: InputDecoration(
                  labelText: 'Status',
                  labelStyle: GoogleFonts.poppins(color: Colors.white),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Statuses')),
                  ...ReminderStatus.values.map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(status.name.toUpperCase()),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _filterStatus = value;
                  });
                  context.read<PaymentReminderProvider>().filterByStatus(value);
                },
              ),
              const SizedBox(height: 16),
              // Type filter
              DropdownButtonFormField<ReminderType?>(
                value: _filterType,
                decoration: InputDecoration(
                  labelText: 'Type',
                  labelStyle: GoogleFonts.poppins(color: Colors.white),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Types')),
                  ...ReminderType.values.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.name.toUpperCase()),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _filterType = value;
                  });
                  context.read<PaymentReminderProvider>().filterByType(value);
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _filterStatus = null;
                          _filterType = null;
                        });
                        context.read<PaymentReminderProvider>().clearFilters();
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Clear',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Apply',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _processDueReminders() {
    context.read<PaymentReminderProvider>().processDueReminders();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Processing due reminders...',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.blue.withOpacity(0.8),
      ),
    );
  }

  void _sendReminder(PaymentReminder reminder) {
    context.read<PaymentReminderProvider>().sendReminder(reminder);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reminder sent successfully!',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green.withOpacity(0.8),
      ),
    );
  }

  void _rescheduleReminder(PaymentReminder reminder) {
    // Show date picker for rescheduling
    showDatePicker(
      context: context,
      initialDate: reminder.scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    ).then((date) {
      if (date != null) {
        context.read<PaymentReminderProvider>().rescheduleReminder(reminder, date);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reminder rescheduled successfully!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green.withOpacity(0.8),
          ),
        );
      }
    });
  }

  void _editReminder(PaymentReminder reminder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentReminderFormScreen(reminder: reminder),
      ),
    );
  }

  void _cancelReminder(PaymentReminder reminder) {
    context.read<PaymentReminderProvider>().cancelReminder(reminder);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reminder cancelled successfully!',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.orange.withOpacity(0.8),
      ),
    );
  }

  void _deleteReminder(PaymentReminder reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Delete Reminder',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete this reminder? This action cannot be undone.',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.read<PaymentReminderProvider>().deleteReminder(reminder.id!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Reminder deleted successfully!',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: Colors.red.withOpacity(0.8),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Delete',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
