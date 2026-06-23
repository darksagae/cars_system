import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/supabase_service.dart';
import 'services/whatsapp_queue_processor.dart';
import 'services/email_queue_processor.dart';
import 'services/background_service.dart';
import 'services/notification_service.dart';
import 'services/notification_preferences_service.dart';
import 'services/invoice_sync_service.dart';
import 'services/machine_management_service.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF8FAFC),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    await SupabaseService.initialize();

    try {
      await NotificationPreferencesService().initialize();
    } catch (e) {
      debugPrint('Warning: Error initializing notification preferences: $e');
    }

    try {
      await NotificationService().initialize();
      await NotificationService().requestPermissions();
    } catch (e) {
      debugPrint('Warning: Error initializing notifications: $e');
    }

    if (SupabaseService.isAuthenticated) {
      try {
        WhatsAppQueueProcessor().start();
        EmailQueueProcessor().start();
        BackgroundService().start();

        InvoiceSyncService().syncAllInvoices().then((count) {
          if (count > 0) debugPrint('Synced $count invoice(s) on startup');
        }).catchError((e) {
          debugPrint('Warning: Error syncing invoices on startup: $e');
        });
      } catch (e) {
        debugPrint('Warning: Error starting queue processors: $e');
      }
    }

    // Connect to relay server (loads saved URL from SharedPreferences)
    try {
      MachineManagementService().loadAndConnect();
    } catch (e) {
      debugPrint('Warning: Error connecting to relay: $e');
    }
  } catch (e, stackTrace) {
    debugPrint('Critical error during initialization: $e\n$stackTrace');
  }

  runApp(const NSBMotorsMobileApp());
}

class NSBMotorsMobileApp extends StatelessWidget {
  const NSBMotorsMobileApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => MachineManagementService()),
      ],
      child: MaterialApp(
        title: 'NSB Motors',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/login': (context) => const LoginScreen(),
        },
        home: const AuthWrapper(),
      ),
    );
  }

  ThemeData _buildTheme() {
    const canvas = Color(0xFFF8FAFC);
    const surface = Color(0xFFFFFFFF);
    const ink = Color(0xFF0F172A);
    const secondary = Color(0xFF64748B);
    const border = Color(0xFFE2E8F0);
    const accent = Color(0xFF1D4ED8);
    const accentLight = Color(0xFFEFF6FF);

    final base = GoogleFonts.plusJakartaSansTextTheme().apply(
      bodyColor: ink,
      displayColor: ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.light,
        primary: accent,
        secondary: const Color(0xFF3B82F6),
        surface: surface,
        background: canvas,
        onPrimary: Colors.white,
        onSurface: ink,
      ),
      scaffoldBackgroundColor: canvas,
      textTheme: base,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: ink,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: ink),
        actionsIconTheme: const IconThemeData(color: ink),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(color: secondary, fontSize: 14),
        hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: const BorderSide(color: accent),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFF1F5F9),
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) =>
            states.contains(MaterialState.selected) ? accent : Colors.white),
        trackColor: MaterialStateProperty.resolveWith((states) =>
            states.contains(MaterialState.selected)
                ? accent.withOpacity(0.4)
                : border),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: accentLight,
        labelStyle: GoogleFonts.plusJakartaSans(color: accent, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    // AUTH DISABLED — bypass login and go straight to HomeScreen
    if (!WhatsAppQueueProcessor().isRunning) {
      WhatsAppQueueProcessor().start();
      EmailQueueProcessor().start();
      BackgroundService().start();
      MachineManagementService().loadAndConnect();
    }
    return const HomeScreen();
  }
}
