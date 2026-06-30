import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/invoice.dart';
import '../models/invoice_type.dart';
import '../screens/glass_login_screen.dart';
import '../screens/invoice_form_screen.dart';
import '../services/invoice_service.dart';
import 'exchange_rate_sync_service.dart';
import 'mv_database_sync_service.dart';
import 'system_settings_sync_service.dart';
import 'auth_service.dart';
import 'cloud_api_service.dart';
import 'cloud_sync_notifier.dart';
import 'invoice_pdf_sync.dart';
import 'machine_lock_service.dart';
import 'session_timeout_service.dart';

/// Polls cloud admin commands and executes them on this desktop.
class CloudCommandService {
  CloudCommandService._();
  static final CloudCommandService instance = CloudCommandService._();

  bool _processing = false;

  Future<void> pollAndExecute() async {
    if (_processing) return;
    _processing = true;
    try {
      final data = await CloudApiService().fetchPendingCommands();

      if (data != null) {
        if (data['machineRevoked'] == true) {
          await _handleMachineRevoked();
          return;
        }

        if (data['banned'] == true) {
          MachineLockService.instance.lock(
            data['message']?.toString() ??
                'You are temporarily banned. Contact NSB Motors administrator.',
          );
        } else if (MachineLockService.instance.isLocked) {
          MachineLockService.instance.unlock();
        }

        final commands = (data['commands'] as List<dynamic>?) ?? [];
        for (final raw in commands) {
          if (raw is! Map) continue;
          await _execute(Map<String, dynamic>.from(raw));
        }
      }

      await CloudApiService().syncInvoicesFromCloud();
      await SystemSettingsSyncService.instance.syncFromCloud();
    } finally {
      _processing = false;
    }
  }

  Future<void> _handleMachineRevoked() async {
    final username = await AuthService().getCurrentUser();
    if (username != null && username.isNotEmpty) {
      await AuthService().clearMachineBinding(username);
    }
    SessionTimeoutService.instance.stopSession();
    await CloudApiService().logoutCloud();
    await AuthService().clearCurrentUser();
    _navigateToLogin();
  }

  Future<void> _execute(Map<String, dynamic> cmd) async {
    final id = (cmd['id'] as num?)?.toInt();
    if (id == null) return;
    final command = cmd['command']?.toString() ?? '';
    final payload = cmd['payload'] is Map
        ? Map<String, dynamic>.from(cmd['payload'] as Map)
        : <String, dynamic>{};

    try {
      switch (command) {
        case 'lock_screen':
          MachineLockService.instance.lock(
            payload['message']?.toString() ??
                'You are temporarily banned. Contact NSB Motors administrator.',
          );
          await CloudApiService().ackCommand(id);
          break;
        case 'unlock_screen':
          MachineLockService.instance.unlock();
          await CloudApiService().ackCommand(id);
          break;
        case 'clear_local_data':
          await DatabaseHelper().clearAllSalesData();
          await CloudApiService().ackCommand(id);
          break;
        case 'delete_local_invoice':
          final number = payload['invoiceNumber']?.toString().trim() ?? '';
          if (number.isNotEmpty) {
            await _deleteLocalInvoice(number);
          }
          await CloudApiService().ackCommand(id);
          break;
        case 'push_invoice':
          final number = payload['invoiceNumber']?.toString().trim() ?? '';
          if (number.isNotEmpty) {
            await CloudApiService().syncInvoicesFromCloud();
            var invoice = await InvoiceService().getInvoiceByNumber(number);
            if (invoice != null) {
              if (invoice.isFinalized) {
                await _unlockInvoiceEdit(invoice, openEditor: false);
                invoice = await InvoiceService().getInvoiceByNumber(number);
              }
              if (invoice != null) {
                await _openInvoiceEditor(invoice);
              }
            }
          }
          await CloudApiService().ackCommand(id);
          break;
        case 'generate_invoice':
        case 'ensure_invoice_pdf':
          final number = payload['invoiceNumber']?.toString().trim() ?? '';
          final finalize = command == 'generate_invoice'
              ? payload['finalize'] != false
              : payload['finalize'] == true;
          if (number.isNotEmpty) {
            final ok = await _generateInvoiceRemote(number, finalize: finalize);
            await CloudApiService().ackCommand(
              id,
              status: ok ? 'completed' : 'failed',
              result: ok ? null : 'PDF generation, finalize, or upload failed',
            );
          } else {
            await CloudApiService().ackCommand(id, status: 'failed', result: 'Missing invoiceNumber');
          }
          break;
        case 'unlock_invoice_edit':
          final number = payload['invoiceNumber']?.toString().trim() ?? '';
          final openEditor = payload['openEditor'] != false;
          if (number.isNotEmpty) {
            await CloudApiService().syncInvoicesFromCloud();
            final invoice = await InvoiceService().getInvoiceByNumber(number);
            if (invoice != null) {
              await _unlockInvoiceEdit(invoice, openEditor: openEditor);
            }
          }
          await CloudApiService().ackCommand(id);
          break;
        case 'logout_user':
          SessionTimeoutService.instance.stopSession();
          final logoutUser = await AuthService().getCurrentUser();
          if (logoutUser != null && logoutUser.isNotEmpty) {
            await AuthService().clearMachineBinding(logoutUser);
          }
          await CloudApiService().logoutCloud();
          await AuthService().clearCurrentUser();
          _navigateToLogin();
          await CloudApiService().ackCommand(id);
          break;
        case 'sync_mv_database':
          final url = payload['pdfUrl']?.toString() ?? '';
          final month = payload['month']?.toString() ?? '';
          if (url.isNotEmpty && month.isNotEmpty) {
            final result = await MvDatabaseSyncService.instance.syncFromUrl(
              fileUrl: url,
              month: month,
              recordCount: (payload['recordCount'] as num?)?.toInt(),
            );
            await CloudApiService().ackCommand(id, result: result);
          } else {
            await CloudApiService().ackCommand(id, status: 'failed', result: 'Missing pdfUrl or month');
          }
          break;
        case 'update_exchange_rates':
          final tax = (payload['taxRate'] as num?)?.toDouble();
          final cnf = (payload['cnfRate'] as num?)?.toDouble();
          if (tax != null && tax > 0) {
            await ExchangeRateSyncService.instance.applyRates(
              taxRate: tax,
              cnfRate: cnf ?? tax,
              taxRateLocked: payload['taxRateLocked'] != false,
              cnfRateLocked: payload['cnfRateLocked'] == true,
            );
            if (payload['version'] != null) {
              await CloudApiService().setLocalSettingsVersion(payload['version'].toString());
            }
            await CloudApiService().ackCommand(id);
          } else {
            await CloudApiService().ackCommand(id, status: 'failed', result: 'Invalid tax rate');
          }
          break;
        default:
          await CloudApiService().ackCommand(id, status: 'failed', result: 'Unknown command: $command');
      }
    } catch (e) {
      await CloudApiService().ackCommand(id, status: 'failed', result: e.toString());
    }
  }

  Future<void> _deleteLocalInvoice(String invoiceNumber) async {
    final invoice = await InvoiceService().getInvoiceByNumber(invoiceNumber);
    final id = invoice?.id;
    if (id == null) return;

    final db = await DatabaseHelper().database;
    await db.transaction((txn) async {
      await txn.delete('invoice_items', where: 'invoiceId = ?', whereArgs: [id]);
      await txn.delete('payments', where: 'invoiceId = ?', whereArgs: [id]);
      await txn.delete('invoices', where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Pull cloud invoice, generate PDF, upload, optionally finalize (web-triggered flow).
  Future<bool> _generateInvoiceRemote(String invoiceNumber, {bool finalize = true}) async {
    if (!finalize && await CloudApiService().isInvoicePdfOnCloud(invoiceNumber)) {
      return true;
    }

    await CloudApiService().syncInvoicesFromCloud();
    var invoice = await InvoiceService().getInvoiceByNumber(invoiceNumber);
    if (invoice == null) {
      print('generate_invoice: $invoiceNumber not found locally after sync');
      return false;
    }

    if (!finalize && await CloudApiService().isInvoicePdfOnCloud(invoiceNumber)) {
      return true;
    }

    try {
      final path = await InvoicePdfSync.saveAndRecord(invoice);
      final err = await InvoicePdfSync.uploadForInvoice(invoice, path: path);
      if (err != null) {
        print('generate_invoice upload failed: $err');
        return false;
      }

      if (finalize && invoice.id != null) {
        await InvoiceService().setInvoiceFinalized(invoice.id!);
        invoice = await InvoiceService().getInvoiceByNumber(invoiceNumber);
        if (invoice != null) {
          await CloudApiService().syncInvoiceToCloud(invoice);
        }
      }

      CloudSyncNotifier.instance.notifyInvoicesSynced();
      return await CloudApiService().isInvoicePdfOnCloud(invoiceNumber);
    } catch (e) {
      print('generate_invoice error: $e');
      return false;
    }
  }

  Future<void> _unlockInvoiceEdit(Invoice invoice, {bool openEditor = true}) async {
    if (invoice.id == null) return;
    final db = await DatabaseHelper().database;
    await db.update(
      'invoices',
      {
        'isFinalized': 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [invoice.id],
    );
    final unlocked = invoice.copyWith(isFinalized: false);
    await CloudApiService().syncInvoiceToCloud(unlocked);
    CloudSyncNotifier.instance.notifyInvoicesSynced();
    if (openEditor) {
      final fresh = await InvoiceService().getInvoiceByNumber(invoice.invoiceNumber);
      if (fresh != null) {
        await _openInvoiceEditor(fresh);
      }
    }
  }

  Future<void> _openInvoiceEditor(Invoice invoice) async {
    final nav = SessionTimeoutService.navigatorKey.currentState;
    if (nav == null) return;
    await nav.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => InvoiceFormScreen(invoice: invoice, type: InvoiceType.invoice),
      ),
    );
  }

  void _navigateToLogin() {
    final nav = SessionTimeoutService.navigatorKey.currentState;
    if (nav == null) return;
    nav.pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: (_) => const GlassLoginScreen()),
      (_) => false,
    );
  }
}
