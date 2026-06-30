import 'package:flutter/foundation.dart';

/// Full-screen lock state when admin bans or locks a sales machine.
class MachineLockService extends ChangeNotifier {
  MachineLockService._();
  static final MachineLockService instance = MachineLockService._();

  bool _locked = false;
  String _message = 'You are temporarily banned. Contact NSB Motors administrator.';

  bool get isLocked => _locked;
  String get message => _message;

  void lock(String message) {
    final trimmed = message.trim();
    if (trimmed.isNotEmpty) _message = trimmed;
    _locked = true;
    notifyListeners();
  }

  void unlock() {
    _locked = false;
    notifyListeners();
  }
}
