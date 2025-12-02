# Notification Issues Analysis & Fix Suggestions

## Problem Summary
Push notifications and email alerts are not working on mobile devices when PDFs are sent from client machines to Supabase. The toggles in the settings screen are not functional.

## Root Causes Identified

### 1. Settings Screen - Push Notifications Toggle (CRITICAL)
**Location**: `nsb_motors_mobile/lib/screens/settings_screen.dart` (lines 102-107)

**Issues**:
- ❌ Hardcoded value `true` - doesn't reflect actual user preference
- ❌ Empty callback `(value) {}` - doesn't save the preference
- ❌ Not reading from SharedPreferences on load
- ❌ Not persisting user choice

**Current Code**:
```dart
_buildSwitchItem(
  'Push Notifications',
  'Receive notifications for client updates',
  true,  // ❌ Hardcoded
  (value) {},  // ❌ Empty callback
),
```

### 2. Settings Screen - Email Alerts Toggle (CRITICAL)
**Location**: `nsb_motors_mobile/lib/screens/settings_screen.dart` (lines 108-113)

**Issues**:
- ❌ Hardcoded value `false` - doesn't reflect actual user preference
- ❌ Empty callback `(value) {}` - doesn't save the preference
- ❌ Not reading from SharedPreferences on load
- ❌ Not persisting user choice

**Current Code**:
```dart
_buildSwitchItem(
  'Email Alerts',
  'Get email alerts for system events',
  false,  // ❌ Hardcoded
  (value) {},  // ❌ Empty callback
),
```

### 3. WhatsApp Queue Processor - Missing Preference Check
**Location**: `nsb_motors_mobile/lib/services/whatsapp_queue_processor.dart` (line 67)

**Issues**:
- ✅ Shows notifications when new messages are detected
- ❌ Doesn't check if push notifications are enabled before showing
- ❌ Always shows notifications regardless of user preference

**Current Code**:
```dart
await NotificationService().show('WhatsApp message queued', 'Tap to open and send');
// ❌ No check for push notification preference
```

### 4. Email Queue Processor - Missing Notifications & Realtime
**Location**: `nsb_motors_mobile/lib/services/email_queue_processor.dart`

**Issues**:
- ❌ No notifications shown when emails are queued
- ❌ No realtime subscription (only polling every 10 seconds)
- ❌ Doesn't check notification preferences
- ❌ Slower detection compared to WhatsApp (10s polling vs instant realtime)

**Current Implementation**:
- Only uses polling (line 36: `Timer.periodic(pollInterval, ...)`)
- No realtime subscription like WhatsApp queue processor
- No notification when email is detected

### 5. Missing Notification Preference Service
**Issue**:
- No centralized service to manage notification preferences
- Each component would need to check SharedPreferences individually
- No consistent way to enable/disable notifications

## Fix Strategy

### Fix 1: Create Notification Preferences Service
Create a service to manage notification preferences centrally.

**File**: `nsb_motors_mobile/lib/services/notification_preferences_service.dart`

**Responsibilities**:
- Save/load push notification preference
- Save/load email alerts preference
- Provide getters for current state

### Fix 2: Update Settings Screen
- Convert to StatefulWidget to manage toggle states
- Load preferences on init
- Save preferences when toggles change
- Use NotificationPreferencesService

### Fix 3: Update WhatsApp Queue Processor
- Check push notification preference before showing notifications
- Only show if enabled

### Fix 4: Update Email Queue Processor
- Add realtime subscription for instant detection (like WhatsApp)
- Show notifications when emails are queued
- Check push notification preference before showing
- Check email alerts preference for email-specific notifications

### Fix 5: Add Email Alerts Logic
- When email alerts are enabled, show additional notifications for email events
- When disabled, only show push notifications (if enabled)

## Implementation Priority

1. **HIGH**: Fix settings screen toggles (Fix 1 & 2)
   - Users can't control notifications without this
   
2. **HIGH**: Add preference checks to queue processors (Fix 3 & 4)
   - Notifications won't respect user preferences without this
   
3. **MEDIUM**: Add realtime subscription to email queue (Fix 4)
   - Improves responsiveness from 10s polling to instant
   
4. **LOW**: Add email alerts specific logic (Fix 5)
   - Nice-to-have feature enhancement

## Expected Behavior After Fixes

### When Push Notifications = ON:
- ✅ WhatsApp messages: Show notification when PDF is queued
- ✅ Email messages: Show notification when email is queued
- ✅ Instant detection via realtime subscriptions

### When Push Notifications = OFF:
- ❌ No notifications shown
- ✅ Queue processors still work (process messages)
- ✅ WhatsApp/Email apps still open automatically

### When Email Alerts = ON:
- ✅ Additional email-specific notifications
- ✅ Email processing status updates

### When Email Alerts = OFF:
- ❌ No email-specific notifications
- ✅ Push notifications still work (if enabled)

## Testing Checklist

- [ ] Toggle push notifications ON/OFF and verify notifications appear/disappear
- [ ] Toggle email alerts ON/OFF and verify behavior
- [ ] Send PDF from client → verify notification appears (if enabled)
- [ ] Send email from client → verify notification appears (if enabled)
- [ ] Verify preferences persist after app restart
- [ ] Verify realtime subscriptions work for both queues
- [ ] Test with app in foreground
- [ ] Test with app in background
- [ ] Test with app closed (background processing)



