import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';

/// Whether the server can be reached right now.
///
/// It asks the server itself instead of the phone's network state: a phone on
/// Wi-Fi with no internet behind it is offline for this app. Any HTTP answer,
/// even an error status, proves the path works; only a failure to get one (or
/// a timeout) means offline.
class ConnectivityMonitor {
  ConnectivityMonitor({
    Future<bool> Function()? probe,
    this.interval = const Duration(seconds: 30),
  }) : _probe = probe ?? _probeSupabase;

  final Future<bool> Function() _probe;
  final Duration interval;

  /// True while the server is reachable. Starts optimistic so the bar does not
  /// flash on every launch.
  final ValueNotifier<bool> online = ValueNotifier<bool>(true);

  Timer? _timer;
  bool _checking = false;
  bool _disposed = false;

  void start() {
    if (_timer != null || _disposed) return;
    check();
    _timer = Timer.periodic(interval, (_) => check());
  }

  /// Probes now. Overlapping calls collapse into one.
  Future<void> check() async {
    if (_checking || _disposed) return;
    _checking = true;
    try {
      final ok = await _probe();
      if (!_disposed) online.value = ok;
    } catch (_) {
      if (!_disposed) online.value = false;
    } finally {
      _checking = false;
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    online.dispose();
  }

  // One client for every probe, so the connection stays open: a fresh TLS
  // handshake on each check would cost more data than the check itself.
  static final http.Client _client = http.Client();

  static Future<bool> _probeSupabase() async {
    final base = Env.supabaseUrl;
    if (base.isEmpty) return true;
    try {
      await _client
          .head(Uri.parse('$base/auth/v1/health'))
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (_) {
      return false;
    }
  }
}
