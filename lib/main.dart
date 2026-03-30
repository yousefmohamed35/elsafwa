import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ElsafwaelgeologyApp());
}

class ElsafwaelgeologyApp extends StatelessWidget {
  const ElsafwaelgeologyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'elsafwaelgeology',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const WebViewScreen(),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _webViewController;
  double _loadingProgress = 0.0;
  bool _isLoading = true;
  bool _hasLoadedSuccessfully = false;
  final String _initialUrl = 'https://elsafwaelgeology.anmka.com/';

  @override
  void initState() {
    super.initState();
    _initializeWebViewController();
    _initializeScreenProtector();
  }

  void _initializeWebViewController() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('🚀 Page started loading: $url');
            debugPrint('📋 Request headers: X-App-Source: anmka');
            if (mounted) {
              setState(() {
                _loadingProgress = 0.0;
                _isLoading = true;
              });
            }
          },
          onPageFinished: (url) {
            debugPrint('✅ Page finished loading: $url');
            if (mounted) {
              setState(() {
                _loadingProgress = 1.0;
                _isLoading = false;
                _hasLoadedSuccessfully = true;
              });
            }
          },
          onWebResourceError: (error) {
            debugPrint('❌ WebView Error: ${error.description}');
            if (!_hasLoadedSuccessfully) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            }
          },
          onNavigationRequest: (request) async {
            final url = request.url;
            debugPrint('🧭 Navigation request: $url');

            // Handle Android Intent URLs specially
            if (url.startsWith('intent://')) {
              try {
                // Parse the intent URL to extract the actual scheme and package
                // Format: intent://...#Intent;scheme=SCHEME;package=PACKAGE;end
                final intentMatch = RegExp(
                  r'intent://(.+)#Intent;scheme=([^;]+);package=([^;]+);end',
                ).firstMatch(url);

                if (intentMatch != null) {
                  final scheme = intentMatch.group(2);
                  final packageName = intentMatch.group(3);
                  final path = intentMatch.group(1);

                  // Try the app-specific scheme first (e.g., fb-messenger://)
                  final appUrl = '$scheme://$path';
                  debugPrint('🔄 Trying app URL: $appUrl');

                  try {
                    final uri = Uri.parse(appUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                      debugPrint('✅ Opened with app scheme: $appUrl');
                      return NavigationDecision.prevent;
                    }
                  } catch (e) {
                    debugPrint('⚠️ App scheme failed, trying package: $e');
                  }

                  // If app scheme fails, try opening the package directly
                  final marketUrl = 'market://details?id=$packageName';
                  try {
                    final uri = Uri.parse(marketUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                      debugPrint('✅ Opened Play Store for: $packageName');
                    }
                  } catch (e) {
                    debugPrint('❌ Could not open app or Play Store: $e');
                  }
                }
              } catch (e) {
                debugPrint('❌ Error parsing intent URL: $e');
              }
              return NavigationDecision.prevent;
            }

            // Check if it's an external URL scheme (WhatsApp, tel, mailto, etc.)
            if (url.startsWith('whatsapp://') ||
                url.startsWith('tel:') ||
                url.startsWith('mailto:') ||
                url.startsWith('sms:') ||
                url.startsWith('fb://') ||
                url.startsWith('fb-messenger://') ||
                url.startsWith('instagram://') ||
                url.startsWith('twitter://') ||
                url.startsWith('tg://')) {
              // Try to launch the external app
              try {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                  debugPrint('✅ Opened external app: $url');
                } else {
                  debugPrint('❌ Cannot launch: $url');
                }
              } catch (e) {
                debugPrint('❌ Error launching URL: $e');
              }
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );

    // Android-specific: YouTube HTML5 playback can fail in WebView unless
    // we relax the "requires user gesture" policy.
    if (_webViewController.platform is AndroidWebViewController) {
      (_webViewController.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _webViewController.loadRequest(
      Uri.parse(_initialUrl),
      headers: {
        'X-App-Source': 'anmka', // <-- الهيدر اللي بيتأكد منه السيرفر
      },
    );

    // Print header when app opens
    debugPrint('🔧 WebView initialized');
    debugPrint('📋 Headers being sent: X-App-Source: anmka');
    debugPrint('🌐 Loading URL: $_initialUrl');
  }

  /// Initialize screen protection on Android/iOS
  Future<void> _initializeScreenProtector() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        debugPrint('🛡️ Enabling Android screen protection...');
        await ScreenProtector.protectDataLeakageOn();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        debugPrint('🛡️ Enabling iOS screenshot prevention...');
        await ScreenProtector.preventScreenshotOn();
      }
    } catch (e) {
      debugPrint('❌ ScreenProtector init error: $e');
    }
  }

  void _refreshWebView() {
    debugPrint('🔄 Refreshing WebView...');
    if (mounted) {
      setState(() {
        _loadingProgress = 0.0;
        _isLoading = true;
        _hasLoadedSuccessfully = false;
      });
    }
    _webViewController.reload();
  }

  @override
  void dispose() {
    // Disable screen protection when leaving
    if (defaultTargetPlatform == TargetPlatform.android) {
      ScreenProtector.protectDataLeakageOff();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      ScreenProtector.preventScreenshotOff();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _refreshWebView();
          },
          child: Stack(
            children: [
              WebViewWidget(controller: _webViewController),
              if (_isLoading && _loadingProgress < 1.0)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: _loadingProgress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue[700]!,
                    ),
                    minHeight: 3,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
