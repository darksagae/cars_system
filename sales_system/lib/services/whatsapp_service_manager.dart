import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// WhatsApp Service Manager
/// 
/// Manages the lifecycle of the bundled Node.js WhatsApp service.
/// Auto-starts the service when app starts, auto-stops when app closes.
class WhatsAppServiceManager {
  static final WhatsAppServiceManager _instance = WhatsAppServiceManager._internal();
  factory WhatsAppServiceManager() => _instance;
  WhatsAppServiceManager._internal();

  Process? _serviceProcess;
  bool _isRunning = false;
  Timer? _healthCheckTimer;
  final String _servicePort = '3001';

  /// Get the path to the bundled Node.js service directory
  Future<String> _getServiceDirectory() async {
    // Try to find bundled service in app resources
    // First, check if it's in the app's data directory
    final appDir = await getApplicationDocumentsDirectory();
    final serviceDir = Directory(path.join(appDir.path, 'whatsapp_service'));
    
    // If bundled with app, it might be in the executable directory
    final executable = Platform.resolvedExecutable;
    final executableDir = path.dirname(executable);
    
    // Check common locations
    final possiblePaths = [
      path.join(executableDir, 'whatsapp_service'),
      path.join(executableDir, 'resources', 'whatsapp_service'),
      path.join(executableDir, '..', 'whatsapp_service'),
      serviceDir.path,
    ];

    for (final possiblePath in possiblePaths) {
      final dir = Directory(possiblePath);
      if (await dir.exists()) {
        final serverJs = File(path.join(possiblePath, 'server.js'));
        if (await serverJs.exists()) {
          return possiblePath;
        }
      }
    }

    // Fallback: use relative path from current working directory
    final currentDir = Directory.current.path;
    final fallbackPath = path.join(currentDir, 'whatsapp_service');
    return fallbackPath;
  }

  /// Get Node.js executable path
  Future<String?> _getNodeExecutable() async {
    // First, try system Node.js
    try {
      final result = await Process.run('which', ['node'], runInShell: true);
      if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
        return result.stdout.toString().trim();
      }
    } catch (e) {
      // Continue to bundled Node.js
    }

    // Try bundled Node.js
    final serviceDir = await _getServiceDirectory();
    final bundledNodePaths = [
      path.join(serviceDir, 'node', 'bin', 'node'),
      path.join(serviceDir, 'node.exe'), // Windows
      path.join(serviceDir, 'runtime', 'node'),
    ];

    for (final nodePath in bundledNodePaths) {
      final nodeFile = File(nodePath);
      if (await nodeFile.exists()) {
        // Make executable on Linux/Mac
        if (Platform.isLinux || Platform.isMacOS) {
          try {
            await Process.run('chmod', ['+x', nodePath]);
          } catch (e) {
            // Ignore chmod errors
          }
        }
        return nodePath;
      }
    }

    return null;
  }

  /// Check if the service is running
  Future<bool> isServiceRunning() async {
    if (_serviceProcess != null && _isRunning) {
      // Check if process is still alive
      try {
        final exitCode = await _serviceProcess!.exitCode.timeout(
          const Duration(milliseconds: 100),
          onTimeout: () => -1,
        );
        if (exitCode != null) {
          // Process has exited
          _isRunning = false;
          _serviceProcess = null;
          return false;
        }
        return true;
      } catch (e) {
        return _isRunning;
      }
    }
    return false;
  }

  /// Start the WhatsApp service
  Future<bool> startService() async {
    if (await isServiceRunning()) {
      print('✅ WhatsApp service already running');
      return true;
    }

    try {
      final serviceDir = await _getServiceDirectory();
      final serviceDirFile = Directory(serviceDir);
      
      if (!await serviceDirFile.exists()) {
        print('❌ WhatsApp service directory not found: $serviceDir');
        return false;
      }

      // Check if server.js exists
      final serverJs = File(path.join(serviceDir, 'server.js'));
      if (!await serverJs.exists()) {
        print('❌ server.js not found in: $serviceDir');
        return false;
      }

      // Get Node.js executable
      final nodeExecutable = await _getNodeExecutable();
      if (nodeExecutable == null) {
        print('❌ Node.js not found. Please install Node.js or bundle it with the app.');
        return false;
      }

      print('🚀 Starting WhatsApp service...');
      print('   Node.js: $nodeExecutable');
      print('   Service dir: $serviceDir');

      // Start the service
      _serviceProcess = await Process.start(
        nodeExecutable,
        ['server.js'],
        workingDirectory: serviceDir,
        mode: ProcessStartMode.detached,
        runInShell: Platform.isWindows,
      );

      // Monitor process
      _serviceProcess!.exitCode.then((exitCode) {
        print('⚠️ WhatsApp service exited with code: $exitCode');
        _isRunning = false;
        _serviceProcess = null;
        
        // Optionally restart if it crashed
        if (exitCode != 0) {
          print('🔄 Service crashed, attempting restart in 5 seconds...');
          Future.delayed(const Duration(seconds: 5), () {
            if (!_isRunning) {
              startService();
            }
          });
        }
      });

      _isRunning = true;
      
      // Wait a bit for service to start
      await Future.delayed(const Duration(seconds: 2));
      
      // Verify it's running
      final isRunning = await _checkHealth();
      if (isRunning) {
        print('✅ WhatsApp service started successfully');
        _startHealthCheck();
        return true;
      } else {
        print('⚠️ Service started but health check failed');
        return false;
      }
    } catch (e) {
      print('❌ Failed to start WhatsApp service: $e');
      _isRunning = false;
      _serviceProcess = null;
      return false;
    }
  }

  /// Stop the WhatsApp service
  Future<void> stopService() async {
    if (_serviceProcess == null) {
      return;
    }

    try {
      print('🛑 Stopping WhatsApp service...');
      _stopHealthCheck();
      
      // Try graceful shutdown
      if (Platform.isWindows) {
        _serviceProcess!.kill();
      } else {
        // Send SIGTERM for graceful shutdown
        _serviceProcess!.kill(ProcessSignal.sigterm);
        
        // Wait up to 5 seconds for graceful shutdown
        try {
          await _serviceProcess!.exitCode.timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              // Force kill if still running
              _serviceProcess!.kill();
              return -1;
            },
          );
        } catch (e) {
          _serviceProcess!.kill();
        }
      }

      _isRunning = false;
      _serviceProcess = null;
      print('✅ WhatsApp service stopped');
    } catch (e) {
      print('❌ Error stopping service: $e');
      _serviceProcess?.kill();
      _isRunning = false;
      _serviceProcess = null;
    }
  }

  /// Check service health
  Future<bool> _checkHealth() async {
    try {
      final client = HttpClient();
      final request = await client
          .getUrl(Uri.parse('http://localhost:$_servicePort/api/health'))
          .timeout(const Duration(seconds: 2));
      
      final response = await request.close().timeout(const Duration(seconds: 2));
      client.close();
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Start periodic health checks
  void _startHealthCheck() {
    _stopHealthCheck();
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!await _checkHealth() && _isRunning) {
        print('⚠️ Service health check failed, restarting...');
        await stopService();
        await Future.delayed(const Duration(seconds: 2));
        await startService();
      }
    });
  }

  /// Stop health check timer
  void _stopHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }

  /// Restart the service
  Future<bool> restartService() async {
    await stopService();
    await Future.delayed(const Duration(seconds: 1));
    return await startService();
  }

  /// Initialize service (call this in main.dart)
  Future<void> initialize() async {
    print('🔧 Initializing WhatsApp Service Manager...');
    
    // Try to start the service
    await startService();
  }

  /// Cleanup (call this when app exits)
  Future<void> cleanup() async {
    print('🧹 Cleaning up WhatsApp Service Manager...');
    await stopService();
  }
}

