import 'package:flutter/material.dart';
import 'auto_fetch_service.dart';

class AppLifecycleService extends StatefulWidget {
  final Widget child;

  const AppLifecycleService({super.key, required this.child});

  @override
  State<AppLifecycleService> createState() => _AppLifecycleServiceState();
}

class _AppLifecycleServiceState extends State<AppLifecycleService>
    with WidgetsBindingObserver {
  bool _isFirstLaunch = true;
  DateTime? _backgroundTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize auto-fetch service
    AutoFetchService.instance.init();

    // Perform cold start auto-fetch after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isFirstLaunch) {
        _performColdStartAutoFetch();
        _isFirstLaunch = false;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _onAppPaused();
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _onAppPaused() {
    _backgroundTime = DateTime.now();
    debugPrint('App paused at: $_backgroundTime');
  }

  void _onAppResumed() {
    final resumeTime = DateTime.now();
    debugPrint('App resumed at: $resumeTime');

    if (_backgroundTime != null) {
      final backgroundDuration = resumeTime.difference(_backgroundTime!);
      debugPrint(
        'App was in background for: ${backgroundDuration.inMinutes} minutes',
      );

      debugPrint('Background resume auto-fetch disabled');

      _backgroundTime = null;
    }
  }

  void _performColdStartAutoFetch() {
    debugPrint('Cold start auto-fetch disabled');
    // Auto-fetch removed - no Khan Bank calls on app launch
  }


  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
