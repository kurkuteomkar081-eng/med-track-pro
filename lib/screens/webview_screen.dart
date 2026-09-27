import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../constants/app_constants.dart';
import '../services/connectivity_service.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/offline_screen.dart';

class WebViewScreen extends StatefulWidget {
  final String initialUrl;

  const WebViewScreen({
    super.key,
    this.initialUrl = AppConstants.targetUrl,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  final ConnectivityService _connectivityService = ConnectivityService();
  StreamSubscription<bool>? _connectivitySubscription;

  bool _isLoading = true;
  double _loadingProgress = 0.0;
  bool _isOffline = false;
  bool _isRetrying = false;
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _initWebViewController();
  }

  void _initConnectivity() {
    _connectivityService.initialize();
    _connectivitySubscription = _connectivityService.connectionStatusStream.listen((hasInternet) {
      if (mounted) {
        if (!hasInternet) {
          setState(() {
            _isOffline = true;
            _isLoading = false;
          });
        } else if (_isOffline) {
          // Auto-reconnect when internet returns
          _reloadPage();
        }
      }
    });
  }

  void _initWebViewController() {
    // Platform-specific initialization parameters
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller = WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress / 100.0;
              });
            }
          },
          onPageStarted: (String url) {
            debugPrint('[WebView] Page started loading: $url');
            if (mounted) {
              setState(() {
                _isLoading = true;
                _isOffline = false;
              });
            }
          },
          onPageFinished: (String url) {
            debugPrint('[WebView] Page finished loading: $url');
            if (mounted) {
              setState(() {
                _isLoading = false;
                _loadingProgress = 1.0;
              });
            }
            // Inject pull-to-refresh gesture listener
            controller.runJavaScript(AppConstants.pullToRefreshJs);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('[WebView] WebResourceError: ${error.errorCode}, ${error.description}');
            // Main frame errors indicate failure to load the primary webpage
            if (error.isForMainFrame ?? true) {
              if (mounted) {
                setState(() {
                  _isOffline = true;
                  _isLoading = false;
                });
              }
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // Allow all navigation within app or target domain
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterPullToRefresh',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message == 'refresh') {
            _reloadPage();
          }
        },
      );

    // Android-specific optimizations
    if (controller.platform is AndroidWebViewController) {
      final androidController = controller.platform as AndroidWebViewController;
      AndroidWebViewController.enableDebugging(false);
      androidController.setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller;
    _loadInitialUrl();
  }

  Future<void> _loadInitialUrl() async {
    final hasInternet = await _connectivityService.checkInternetAccess();
    if (!hasInternet) {
      if (mounted) {
        setState(() {
          _isOffline = true;
          _isLoading = false;
        });
      }
      return;
    }

    _controller.loadRequest(Uri.parse(widget.initialUrl));
  }

  Future<void> _reloadPage() async {
    setState(() {
      _isRetrying = true;
    });

    final hasInternet = await _connectivityService.checkInternetAccess();
    if (!hasInternet) {
      if (mounted) {
        setState(() {
          _isOffline = true;
          _isLoading = false;
          _isRetrying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No internet connection. Please check your network.'),
            duration: AppConstants.snackBarDuration,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isOffline = false;
        _isLoading = true;
        _isRetrying = false;
      });
    }

    try {
      final currentUrl = await _controller.currentUrl();
      if (currentUrl == null || currentUrl.isEmpty || currentUrl == 'about:blank') {
        await _controller.loadRequest(Uri.parse(widget.initialUrl));
      } else {
        await _controller.reload();
      }
    } catch (_) {
      await _controller.loadRequest(Uri.parse(widget.initialUrl));
    }
  }

  /// Handles Android physical & gesture Back Button navigation
  Future<void> _handleBackPress() async {
    if (await _controller.canGoBack()) {
      // Navigate backward in WebView history
      await _controller.goBack();
    } else {
      // User is at root of web history: double press to exit
      final now = DateTime.now();
      if (_lastBackPressed == null ||
          now.difference(_lastBackPressed!) > AppConstants.exitWarningWindow) {
        _lastBackPressed = now;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit MedTrack Pro'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        SystemNavigator.pop();
      }
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        await _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            titleSpacing: 16,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.health_and_safety_rounded,
                    size: 20,
                    color: AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.home_outlined, color: AppConstants.textPrimary),
                tooltip: 'Home',
                onPressed: () {
                  _controller.loadRequest(Uri.parse(widget.initialUrl));
                },
              ),
              IconButton(
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, color: AppConstants.textPrimary),
                tooltip: 'Refresh',
                onPressed: _isLoading ? null : () => _reloadPage(),
              ),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(3.5),
              child: WebProgressIndicator(
                progress: _loadingProgress,
                isVisible: _isLoading && !_isOffline,
              ),
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Stack(
            children: [
              // WebView Widget
              if (!_isOffline)
                RefreshIndicator(
                  color: AppConstants.primaryColor,
                  backgroundColor: Colors.white,
                  onRefresh: _reloadPage,
                  child: WebViewWidget(controller: _controller),
                ),

              // Full Loading Spinner for Initial Page Load
              if (_isLoading && _loadingProgress < 0.25 && !_isOffline)
                const LoadingSpinnerOverlay(message: 'Connecting to MedTrack Pro...'),

              // Clean Offline Screen
              if (_isOffline)
                OfflineScreen(
                  onRetry: _reloadPage,
                  isRetrying: _isRetrying,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
