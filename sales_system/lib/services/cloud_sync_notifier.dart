import 'package:flutter/foundation.dart';

/// Notifies UI when cloud sync updates local invoice data.
class CloudSyncNotifier extends ChangeNotifier {
  CloudSyncNotifier._();
  static final CloudSyncNotifier instance = CloudSyncNotifier._();

  int _generation = 0;
  int get generation => _generation;

  void notifyInvoicesSynced() {
    _generation++;
    notifyListeners();
  }
}
