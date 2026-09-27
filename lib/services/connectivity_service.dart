import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();

  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  StreamSubscription? _subscription;
  bool _hasConnection = true;

  bool get hasConnection => _hasConnection;

  /// Initializes connectivity listeners
  void initialize() {
    _checkInitialStatus();

    // Listen to network interface changes
    _subscription = _connectivity.onConnectivityChanged.listen((dynamic result) async {
      // In connectivity_plus v6+, result is List<ConnectivityResult>
      bool isConnected = false;
      if (result is List<ConnectivityResult>) {
        isConnected = result.any((r) => r != ConnectivityResult.none);
      } else if (result is ConnectivityResult) {
        isConnected = result != ConnectivityResult.none;
      }

      if (isConnected) {
        final hasInternet = await checkInternetAccess();
        _updateStatus(hasInternet);
      } else {
        _updateStatus(false);
      }
    });
  }

  Future<void> _checkInitialStatus() async {
    final hasInternet = await checkInternetAccess();
    _updateStatus(hasInternet);
  }

  void _updateStatus(bool status) {
    if (_hasConnection != status) {
      _hasConnection = status;
      _connectionStatusController.add(status);
      debugPrint('[ConnectivityService] Connection status changed: $status');
    }
  }

  /// Verifies active internet reachability with a fast socket lookup
  Future<bool> checkInternetAccess() async {
    try {
      final lookupTarget = 'gigantic-med-track-pro.base44.app';
      final result = await InternetAddress.lookup(lookupTarget)
          .timeout(const Duration(seconds: 4));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        _hasConnection = true;
        return true;
      }
    } catch (_) {
      // Fallback check to generic DNS
      try {
        final fallback = await InternetAddress.lookup('1.1.1.1')
            .timeout(const Duration(seconds: 3));
        if (fallback.isNotEmpty && fallback[0].rawAddress.isNotEmpty) {
          _hasConnection = true;
          return true;
        }
      } catch (_) {
        // No internet access
      }
    }
    _hasConnection = false;
    return false;
  }

  void dispose() {
    _subscription?.cancel();
    _connectionStatusController.close();
  }
}
