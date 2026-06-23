import 'package:shared_preferences/shared_preferences.dart';

/// Notification Preferences Service
/// 
/// Manages user preferences for push notifications and email alerts.
/// Persists settings to SharedPreferences.
class NotificationPreferencesService {
  static final NotificationPreferencesService _instance = 
      NotificationPreferencesService._internal();
  factory NotificationPreferencesService() => _instance;
  NotificationPreferencesService._internal();

  static const String _pushNotificationsKey = 'push_notifications_enabled';
  static const String _emailAlertsKey = 'email_alerts_enabled';

  // Default values
  static const bool _defaultPushNotifications = true;
  static const bool _defaultEmailAlerts = false;

  bool? _pushNotificationsCache;
  bool? _emailAlertsCache;

  /// Initialize and load preferences
  Future<void> initialize() async {
    await loadPreferences();
  }

  /// Load preferences from SharedPreferences
  Future<void> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _pushNotificationsCache = prefs.getBool(_pushNotificationsKey) ?? _defaultPushNotifications;
      _emailAlertsCache = prefs.getBool(_emailAlertsKey) ?? _defaultEmailAlerts;
      print('✅ Notification preferences loaded: Push=$_pushNotificationsCache, Email=$_emailAlertsCache');
    } catch (e) {
      print('⚠️ Error loading notification preferences: $e');
      // Use defaults
      _pushNotificationsCache = _defaultPushNotifications;
      _emailAlertsCache = _defaultEmailAlerts;
    }
  }

  /// Get push notifications enabled state
  bool get pushNotificationsEnabled {
    return _pushNotificationsCache ?? _defaultPushNotifications;
  }

  /// Get email alerts enabled state
  bool get emailAlertsEnabled {
    return _emailAlertsCache ?? _defaultEmailAlerts;
  }

  /// Set push notifications enabled
  Future<bool> setPushNotificationsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setBool(_pushNotificationsKey, enabled);
      if (success) {
        _pushNotificationsCache = enabled;
        print('✅ Push notifications ${enabled ? "enabled" : "disabled"}');
      }
      return success;
    } catch (e) {
      print('❌ Error saving push notifications preference: $e');
      return false;
    }
  }

  /// Set email alerts enabled
  Future<bool> setEmailAlertsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setBool(_emailAlertsKey, enabled);
      if (success) {
        _emailAlertsCache = enabled;
        print('✅ Email alerts ${enabled ? "enabled" : "disabled"}');
      }
      return success;
    } catch (e) {
      print('❌ Error saving email alerts preference: $e');
      return false;
    }
  }

  /// Check if notifications should be shown
  /// Returns true if push notifications are enabled
  bool shouldShowNotification() {
    return pushNotificationsEnabled;
  }

  /// Check if email alerts should be shown
  /// Returns true if both push notifications and email alerts are enabled
  bool shouldShowEmailAlert() {
    return pushNotificationsEnabled && emailAlertsEnabled;
  }
}



