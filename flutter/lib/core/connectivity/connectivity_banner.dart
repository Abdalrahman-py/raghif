import 'dart:async';

import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import 'connectivity_monitor.dart';

/// A thin bar across the top of every screen showing whether the app can reach
/// the server: amber while offline, green for a moment when it comes back,
/// nothing the rest of the time.
class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({
    super.key,
    required this.monitor,
    required this.child,
  });

  final ConnectivityMonitor monitor;
  final Widget child;

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  bool _showRestored = false;
  Timer? _restoredTimer;

  @override
  void initState() {
    super.initState();
    widget.monitor.online.addListener(_changed);
  }

  @override
  void didUpdateWidget(ConnectivityBanner old) {
    super.didUpdateWidget(old);
    if (old.monitor != widget.monitor) {
      old.monitor.online.removeListener(_changed);
      widget.monitor.online.addListener(_changed);
    }
  }

  void _changed() {
    _restoredTimer?.cancel();
    if (widget.monitor.online.value) {
      setState(() => _showRestored = true);
      _restoredTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showRestored = false);
      });
    } else {
      setState(() => _showRestored = false);
    }
  }

  @override
  void dispose() {
    _restoredTimer?.cancel();
    widget.monitor.online.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offline = !widget.monitor.online.value;
    final visible = offline || _showRestored;
    final media = MediaQuery.of(context);
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: visible
              ? Material(
                  key: Key(
                    offline ? 'connectivity-offline' : 'connectivity-back',
                  ),
                  color: offline
                      ? const Color(0xFFB45309)
                      : const Color(0xFF15803D),
                  child: SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: media.padding.top + 6,
                        bottom: 6,
                        left: 12,
                        right: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            offline ? Icons.cloud_off : Icons.cloud_done,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              offline
                                  ? Strings.connectionOffline
                                  : Strings.connectionRestored,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        // While the bar is showing it already covers the status bar, so the
        // screen below must not pad for it a second time.
        Expanded(
          child: MediaQuery(
            data: visible ? media.removePadding(removeTop: true) : media,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
