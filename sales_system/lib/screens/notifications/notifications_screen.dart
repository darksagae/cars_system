import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/notifications/notification_service.dart';
import '../../widgets/glass_container.dart';
import '../../providers/theme_provider.dart';
import '../widgets/glass_liquid_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> 
    implements NotificationListener {
  final NotificationService _notificationService = NotificationService();
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _notificationService.addListener(this);
  }

  @override
  void dispose() {
    _notificationService.removeListener(this);
    super.dispose();
  }

  @override
  void onNotificationsChanged(List<NotificationItem> notifications) {
    setState(() {
      _notifications = notifications;
    });
  }

  void _loadNotifications() async {
    try {
      await _notificationService.initialize();
      setState(() {
        _notifications = _notificationService.getNotifications();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading notifications: $e');
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
          'Notifications',
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
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.checkDouble, color: Colors.white),
            onPressed: _markAllAsRead,
            tooltip: 'Mark all as read',
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.trash, color: Colors.white),
            onPressed: _clearAllNotifications,
            tooltip: 'Clear all',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _notifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const FaIcon(
            FontAwesomeIcons.bellSlash,
            color: Colors.white54,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildNotificationStats(),
          const SizedBox(height: 20),
          ..._notifications.map((notification) => _buildNotificationCard(notification)),
        ],
      ),
    );
  }

  Widget _buildNotificationStats() {
    final unreadCount = _notificationService.getUnreadCount();
    final totalCount = _notificationService.getNotificationCount();
    
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Total',
                totalCount.toString(),
                FontAwesomeIcons.bell,
                GlassLiquidTheme.accentBlue,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildStatItem(
                'Unread',
                unreadCount.toString(),
                FontAwesomeIcons.bellSlash,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildStatItem(
                'Read',
                (totalCount - unreadCount).toString(),
                FontAwesomeIcons.check,
                Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        FaIcon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        child: InkWell(
          onTap: () => _onNotificationTap(notification),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNotificationIcon(notification.type),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: notification.isRead 
                                    ? FontWeight.normal 
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: GlassLiquidTheme.accentBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            _formatDateTime(notification.createdAt),
                            style: GoogleFonts.poppins(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          PopupMenuButton<String>(
                            icon: const FaIcon(
                              FontAwesomeIcons.ellipsisVertical,
                              color: Colors.white54,
                              size: 16,
                            ),
                            onSelected: (value) => _onMenuAction(value, notification),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'mark_read',
                                child: Row(
                                  children: [
                                    const FaIcon(FontAwesomeIcons.check, size: 14),
                                    const SizedBox(width: 8),
                                    Text(notification.isRead ? 'Mark as unread' : 'Mark as read'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const FaIcon(FontAwesomeIcons.trash, size: 14),
                                    const SizedBox(width: 8),
                                    const Text('Delete'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type) {
    IconData icon;
    Color color;
    
    switch (type) {
      case NotificationType.success:
        icon = FontAwesomeIcons.checkCircle;
        color = Colors.green;
        break;
      case NotificationType.warning:
        icon = FontAwesomeIcons.exclamationTriangle;
        color = Colors.orange;
        break;
      case NotificationType.error:
        icon = FontAwesomeIcons.timesCircle;
        color = Colors.red;
        break;
      case NotificationType.reminder:
        icon = FontAwesomeIcons.clock;
        color = GlassLiquidTheme.accentBlue;
        break;
      case NotificationType.payment:
        icon = FontAwesomeIcons.moneyBill;
        color = Colors.green;
        break;
      case NotificationType.invoice:
        icon = FontAwesomeIcons.fileInvoice;
        color = GlassLiquidTheme.accentBlue;
        break;
      case NotificationType.customer:
        icon = FontAwesomeIcons.user;
        color = Colors.purple;
        break;
      default:
        icon = FontAwesomeIcons.infoCircle;
        color = GlassLiquidTheme.accentBlue;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: FaIcon(icon, color: color, size: 16),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _onNotificationTap(NotificationItem notification) {
    if (!notification.isRead) {
      _notificationService.markAsRead(notification.id);
    }
    
    // Handle notification action if available
    if (notification.action != null) {
      // Navigate to relevant screen based on action
      // This would be implemented based on the specific action
    }
  }

  void _onMenuAction(String action, NotificationItem notification) {
    switch (action) {
      case 'mark_read':
        if (notification.isRead) {
          // Mark as unread (would need to implement this)
        } else {
          _notificationService.markAsRead(notification.id);
        }
        break;
      case 'delete':
        _notificationService.deleteNotification(notification.id);
        break;
    }
  }

  void _markAllAsRead() async {
    await _notificationService.markAllAsRead();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _clearAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications? This action cannot be undone.'),
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
      await _notificationService.clearAllNotifications();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications cleared'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
