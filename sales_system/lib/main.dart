import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'widgets/desktop_frame.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/glass_login_screen.dart';
import 'screens/root_gate.dart';
import 'providers/sales_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/vehicle_provider.dart';
import 'providers/demand_letter_provider.dart';
import 'providers/payment_reminder_provider.dart';
import 'providers/theme_provider.dart';
import 'widgets/glass_liquid_theme.dart';
import 'services/remote_command_executor.dart';
import 'services/pairing_service.dart';
import 'services/heartbeat_service.dart';
import 'services/whatsapp_service_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database factory for Linux/Desktop
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  
  // Initialize remote command system only if device is paired
  try {
    final paired = await PairingService().isPaired();
    if (paired) {
      await RemoteCommandExecutor().initialize();
      await HeartbeatService().start(interval: const Duration(seconds: 20));
    } else {
      print('Remote commands disabled until pairing is approved.');
    }
  } catch (e) {
    print('Warning: Could not initialize remote command system: $e');
    // Continue app startup even if remote commands fail
  }
  
  // Initialize WhatsApp service manager (auto-start service)
  try {
    await WhatsAppServiceManager().initialize();
    print('✅ WhatsApp service manager initialized');
  } catch (e) {
    print('Warning: Could not initialize WhatsApp service manager: $e');
    // Continue app startup even if WhatsApp service fails
    // App will fallback to manual WhatsApp method
  }
  
  // Initialize window settings for all desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    doWhenWindowReady(() {
      const initialSize = Size(1280, 800);
      appWindow.minSize = const Size(1024, 640);
      appWindow.size = initialSize;
      appWindow.alignment = Alignment.center;
      // Don't set title here - let DesktopFrame handle it visually
      // Setting title here can cause native title bar to appear
      appWindow.show();
    });
  }

  runApp(const SalesSystemApp());
}

class SalesSystemApp extends StatefulWidget {
  const SalesSystemApp({super.key});

  @override
  State<SalesSystemApp> createState() => _SalesSystemAppState();
}

class _SalesSystemAppState extends State<SalesSystemApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Cleanup WhatsApp service when app closes
    WhatsAppServiceManager().cleanup();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.detached || state == AppLifecycleState.paused) {
      // App is closing or being suspended
      WhatsAppServiceManager().cleanup();
    }
  }

  @override
  Widget build(BuildContext context) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()..setTheme('modern_glass')),
            ChangeNotifierProvider(create: (_) => SalesProvider()),
            ChangeNotifierProvider(create: (_) => CustomerProvider()),
            ChangeNotifierProvider(create: (_) => InvoiceProvider()),
            ChangeNotifierProvider(create: (_) => PaymentProvider()),
            ChangeNotifierProvider(create: (_) => VehicleProvider()),
            ChangeNotifierProvider(create: (_) => DemandLetterProvider()),
            ChangeNotifierProvider(create: (_) => PaymentReminderProvider()),
          ],
      child: MaterialApp(
        title: 'NSB Motors Ug',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: GlassLiquidTheme.accentBlue,
          scaffoldBackgroundColor: GlassLiquidTheme.currentBackground,
          textTheme: GoogleFonts.poppinsTextTheme(
            ThemeData.dark().textTheme,
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
          colorScheme: ColorScheme.fromSeed(
            seedColor: GlassLiquidTheme.accentBlue,
            brightness: Brightness.dark,
            primary: GlassLiquidTheme.accentBlue,
            secondary: GlassLiquidTheme.accentGreen,
            surface: GlassLiquidTheme.glassPrimary,
            background: GlassLiquidTheme.currentBackground,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: GlassLiquidTheme.accentBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(GlassLiquidTheme.radiusMedium),
              ),
              elevation: 0,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: GlassLiquidTheme.glassPrimary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GlassLiquidTheme.radiusMedium),
              borderSide: BorderSide(color: GlassLiquidTheme.glassBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GlassLiquidTheme.radiusMedium),
              borderSide: BorderSide(color: GlassLiquidTheme.glassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GlassLiquidTheme.radiusMedium),
              borderSide: BorderSide(color: GlassLiquidTheme.accentBlue, width: 2),
            ),
          ),
        ),
        builder: (context, child) {
          // Wrap entire app in DesktopFrame to show custom title bar on Windows
          return DesktopFrame(
            title: 'NSB Motors Ug',
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const RootGate(),
      ),
    );
  }
}