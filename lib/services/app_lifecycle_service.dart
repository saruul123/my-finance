import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'auto_fetch_service.dart';
import '../providers/settings_provider.dart';

class AppLifecycleService extends StatefulWidget {
  final Widget child;
  
  const AppLifecycleService({
    super.key,
    required this.child,
  });

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
      debugPrint('App was in background for: ${backgroundDuration.inMinutes} minutes');
      
      if (AutoFetchService.instance.shouldAutoFetch()) {
        debugPrint('Performing background resume auto-fetch...');
        _performAutoFetch(isBackgroundResume: true);
      } else {
        debugPrint('Skipping auto-fetch (last sync too recent)');
      }
      
      _backgroundTime = null;
    }
  }

  void _performColdStartAutoFetch() {
    debugPrint('Performing cold start auto-fetch...');
    _performAutoFetch(isAppLaunch: true);
  }

  void _performAutoFetch({bool isAppLaunch = false, bool isBackgroundResume = false}) async {
    if (!mounted) return;
    
    try {
      // Check if Khan Bank is configured
      final settingsProvider = context.read<SettingsProvider>();
      if (!settingsProvider.khanBankEnabled ||
          settingsProvider.khanBankUsername.isEmpty ||
          settingsProvider.khanBankPassword.isEmpty) {
        debugPrint('Auto-fetch skipped: Khan Bank not configured');
        return;
      }

      // Perform the fetch
      final success = await AutoFetchService.instance.fetchTransactions(
        context,
        showLoading: false, // Silent background fetch
      );

      if (success) {
        debugPrint('Auto-fetch successful');
      } else {
        debugPrint('Auto-fetch failed: ${AutoFetchService.instance.lastError}');
      }
    } catch (e) {
      debugPrint('Auto-fetch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}