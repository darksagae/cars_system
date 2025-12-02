import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'services/supabase_service.dart';
import 'services/whatsapp_queue_processor.dart';
import 'services/email_queue_processor.dart';
import 'services/background_service.dart';
import 'services/notification_service.dart';
import 'services/notification_preferences_service.dart';
import 'services/invoice_sync_service.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Supabase
    await SupabaseService.initialize();

    // Initialize notification preferences
    try {
      await NotificationPreferencesService().initialize();
    } catch (e) {
      print('⚠️ Error initializing notification preferences: $e');
      // Continue - preferences will use defaults
    }

    // Notifications (Android 13+ requires runtime permission)
    try {
      await NotificationService().initialize();
      await NotificationService().requestPermissions();
      // Emit a test notification so we can confirm OS delivery
      await NotificationService().show('NSB Motors', 'Notifications enabled');
    } catch (e) {
      print('⚠️ Error initializing notifications: $e');
      // Continue - notifications may not work but app should still run
    }
    
    // Debug: Check initial auth state
    print('🔐 Initial auth check:');
    print('   Has session: ${SupabaseService.currentSession != null}');
    print('   Has user: ${SupabaseService.currentUser != null}');
    print('   Is authenticated: ${SupabaseService.isAuthenticated}');
    
    // Note: Using Realtime subscriptions for instant notifications
    // Works when app is open or in background (not force-closed)

    // Start queue processors if authenticated
    if (SupabaseService.isAuthenticated) {
      try {
        WhatsAppQueueProcessor().start();
        EmailQueueProcessor().start();
        BackgroundService().start(); // Keep app alive for instant WhatsApp opening
        
        // Sync invoices in background (non-blocking)
        InvoiceSyncService().syncAllInvoices().then((count) {
          if (count > 0) {
            print('✅ Synced $count invoice(s) on startup');
          }
        }).catchError((e) {
          print('⚠️ Error syncing invoices on startup: $e');
        });
        
        print('✅ WhatsApp and Email queue processors started');
      } catch (e) {
        print('⚠️ Error starting queue processors: $e');
        // Continue - app should still work
      }
    }
  } catch (e, stackTrace) {
    print('❌ Critical error during initialization: $e');
    print('Stack trace: $stackTrace');
    // Still run the app - let user see error screen if needed
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
      ],
      child: MaterialApp(
        title: 'NSB Motors Mobile',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          primaryColor: const Color(0xFF3B82F6),
          scaffoldBackgroundColor: const Color(0xFF1A1A1A),
          appBarTheme: AppBarTheme(
            backgroundColor: const Color(0xFF2A2A2A),
            elevation: 0,
            titleTextStyle: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          textTheme: GoogleFonts.poppinsTextTheme(
            Theme.of(context).textTheme,
          ).apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3B82F6),
            brightness: Brightness.dark,
          ),
        ),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/login': (context) => const LoginScreen(),
        },
        home: const AuthWrapper(),
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
    // Check current session first (immediate check)
    final currentAuth = SupabaseService.isAuthenticated;
    
    return StreamBuilder<AuthState>(
      stream: SupabaseService.authStateChanges,
      initialData: null,
      builder: (context, snapshot) {
        // Use current auth state if stream hasn't emitted yet
        final hasAuthData = snapshot.hasData;
        final authState = snapshot.data;
        
        // Determine authentication status
        bool isAuthenticated = currentAuth;
        if (hasAuthData && authState != null) {
          isAuthenticated = authState.session != null;
        }
        
        // Always show login if not authenticated
        if (!isAuthenticated) {
          return const LoginScreen();
        }
        
        // Show home if authenticated
        // Start queue processor if not already running
        if (isAuthenticated && !WhatsAppQueueProcessor().isRunning) {
          WhatsAppQueueProcessor().start();
          EmailQueueProcessor().start();
          BackgroundService().start(); // Keep app alive for instant WhatsApp opening
          
          // Sync invoices in background (non-blocking)
          InvoiceSyncService().syncAllInvoices().then((count) {
            if (count > 0) {
              print('✅ Synced $count invoice(s) on login');
            }
          }).catchError((e) {
            print('⚠️ Error syncing invoices on login: $e');
          });
        } else if (!isAuthenticated && WhatsAppQueueProcessor().isRunning) {
          WhatsAppQueueProcessor().stop();
          EmailQueueProcessor().stop();
          BackgroundService().stop();
        }
        
        return const HomeScreen();
      },
    );
  }
}

// Background callback is now in background_service.dart