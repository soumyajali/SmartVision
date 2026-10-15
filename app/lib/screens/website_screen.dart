import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

const _websiteUrlPreferenceKey = 'smart_vision_website_url';
const _cameraCaptureResource = 'camera';
const _microphoneCaptureResource = 'microphone';

Uri? parseSmartVisionWebsiteUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null ||
      (uri.scheme != 'http' && uri.scheme != 'https') ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return null;
  }
  return uri;
}

class SmartVisionWebsiteScreen extends StatefulWidget {
  const SmartVisionWebsiteScreen({super.key});

  @override
  State<SmartVisionWebsiteScreen> createState() =>
      _SmartVisionWebsiteScreenState();
}

class _SmartVisionWebsiteScreenState extends State<SmartVisionWebsiteScreen> {
  late final WebViewController _webViewController;
  String _websiteUrl = '';
  Uri? _currentPageUri;
  String? _errorMessage;
  String? _statusMessage;
  int _loadingProgress = 0;
  bool _isLoading = true;

  String get _defaultWebsiteUrl {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8501';
    }
    return 'http://127.0.0.1:8501';
  }

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) {
              setState(() => _loadingProgress = progress);
            }
          },
          onPageStarted: (url) {
            if (!mounted) return;
            setState(() {
              _currentPageUri = Uri.tryParse(url);
              _errorMessage = null;
              _isLoading = true;
            });
          },
          onPageFinished: (url) {
            if (!mounted) return;
            setState(() {
              _currentPageUri = Uri.tryParse(url);
              _loadingProgress = 100;
              _isLoading = false;
            });
          },
          onWebResourceError: (error) {
            if (!mounted || error.isForMainFrame != true) return;
            setState(() {
              _isLoading = false;
              _errorMessage = error.description;
            });
          },
        ),
      );
    unawaited(_initializeWebView());
  }

  Future<void> _initializeWebView() async {
    try {
      await _webViewController.platform
          .setOnPlatformPermissionRequest(_handleWebPermissionRequest);

      if (_webViewController.platform is AndroidWebViewController) {
        final androidController =
            _webViewController.platform as AndroidWebViewController;
        await androidController.setMediaPlaybackRequiresUserGesture(false);
        await androidController.setOnShowFileSelector(_handleFileSelection);
      }

      await _restoreWebsiteAddress();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not initialize the Smart Vision website: $error';
      });
    }
  }

  Future<void> _restoreWebsiteAddress() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final savedAddress = preferences.getString(_websiteUrlPreferenceKey);
      await _loadWebsite(savedAddress ?? _defaultWebsiteUrl, persist: false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load the saved website address: $error';
      });
    }
  }

  Future<void> _loadWebsite(String address, {bool persist = true}) async {
    final uri = parseSmartVisionWebsiteUrl(address);
    if (uri == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Enter a valid website address starting with http:// or https://.';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _websiteUrl = uri.toString();
      _currentPageUri = uri;
      _errorMessage = null;
      _statusMessage = null;
      _loadingProgress = 0;
      _isLoading = true;
    });

    try {
      if (persist) {
        final preferences = await SharedPreferences.getInstance();
        await preferences.setString(_websiteUrlPreferenceKey, uri.toString());
      }
      await _webViewController.loadRequest(uri);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not open $uri: $error';
      });
    }
  }

  Future<void> _handleWebPermissionRequest(
    PlatformWebViewPermissionRequest request,
  ) async {
    final configuredUri = parseSmartVisionWebsiteUrl(_websiteUrl);
    final currentUri = _currentPageUri;
    final isTrustedPage = configuredUri != null &&
        currentUri != null &&
        configuredUri.scheme == currentUri.scheme &&
        configuredUri.host == currentUri.host &&
        configuredUri.port == currentUri.port;
    final resources = request.types.map((type) => type.name).toSet();
    const supportedResources = {
      _cameraCaptureResource,
      _microphoneCaptureResource,
    };

    if (!isTrustedPage ||
        resources.isEmpty ||
        !supportedResources.containsAll(resources)) {
      await request.deny();
      return;
    }

    try {
      final cameraGranted = !resources.contains(_cameraCaptureResource) ||
          (await Permission.camera.request()).isGranted;
      final microphoneGranted =
          !resources.contains(_microphoneCaptureResource) ||
              (await Permission.microphone.request()).isGranted;
      if (cameraGranted && microphoneGranted) {
        await request.grant();
      } else {
        await request.deny();
        if (mounted) {
          setState(() {
            _statusMessage =
                'Allow camera or microphone access in Android settings to use '
                'the website’s live camera and voice features.';
          });
        }
      }
    } catch (error) {
      await request.deny();
      if (mounted) {
        setState(() {
          _statusMessage =
              'Could not request camera or microphone access: $error';
        });
      }
    }
  }

  FileType _fileTypeForAcceptTypes(List<String> acceptTypes) {
    final normalizedTypes = acceptTypes
        .map((type) => type.trim().toLowerCase())
        .where((type) => type.isNotEmpty)
        .toList();
    if (normalizedTypes.isEmpty) return FileType.any;
    if (normalizedTypes.every((type) => type.startsWith('image/'))) {
      return FileType.image;
    }
    if (normalizedTypes.every((type) => type.startsWith('video/'))) {
      return FileType.video;
    }
    if (normalizedTypes.every((type) => type.startsWith('audio/'))) {
      return FileType.audio;
    }
    if (normalizedTypes.every((type) => type.startsWith('.'))) {
      return FileType.custom;
    }
    return FileType.any;
  }

  Future<List<String>> _handleFileSelection(FileSelectorParams params) async {
    try {
      final fileType = _fileTypeForAcceptTypes(params.acceptTypes);
      if (params.isCaptureEnabled && fileType == FileType.image) {
        final image = await ImagePicker().pickImage(source: ImageSource.camera);
        return image == null
            ? <String>[]
            : <String>[_toWebViewFileUri(image.path)];
      }
      if (params.isCaptureEnabled && fileType == FileType.video) {
        final video = await ImagePicker().pickVideo(source: ImageSource.camera);
        return video == null
            ? <String>[]
            : <String>[_toWebViewFileUri(video.path)];
      }
      if (params.mode != FileSelectorMode.open &&
          params.mode != FileSelectorMode.openMultiple) {
        return <String>[];
      }

      final extensions = params.acceptTypes
          .where((type) => type.trim().startsWith('.'))
          .map((type) => type.trim().substring(1))
          .toList();
      final result = await FilePicker.platform.pickFiles(
        type: fileType,
        allowedExtensions: fileType == FileType.custom ? extensions : null,
        allowMultiple: params.mode == FileSelectorMode.openMultiple,
      );
      return result?.files
              .map((file) => file.path)
              .whereType<String>()
              .map(_toWebViewFileUri)
              .toList() ??
          <String>[];
    } catch (error) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Could not select a file for the website: $error';
        });
      }
      rethrow;
    }
  }

  String _toWebViewFileUri(String path) => Uri.file(path).toString();

  Future<void> _showWebsiteAddressDialog() async {
    final addressController = TextEditingController(
      text: _websiteUrl.isEmpty ? _defaultWebsiteUrl : _websiteUrl,
    );
    String? validationMessage;

    final selectedAddress = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          void submit() {
            if (parseSmartVisionWebsiteUrl(addressController.text) == null) {
              setDialogState(() {
                validationMessage =
                    'Enter a valid http:// or https:// website address.';
              });
              return;
            }
            Navigator.of(dialogContext).pop(addressController.text.trim());
          }

          return AlertDialog(
            title: const Text('Connect to Smart Vision'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter the address where the Smart Vision website is running. '
                  'For a physical phone, use your computer’s LAN IP address and '
                  'keep both devices on the same Wi-Fi network.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Website URL',
                    hintText: 'http://192.168.1.20:8501',
                    errorText: validationMessage,
                  ),
                  onSubmitted: (_) => submit(),
                ),
                const SizedBox(height: 8),
                Text(
                  'Android emulator default: $_defaultWebsiteUrl',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: submit,
                child: const Text('Connect'),
              ),
            ],
          );
        },
      ),
    );
    addressController.dispose();

    if (selectedAddress != null && mounted) {
      await _loadWebsite(selectedAddress);
    }
  }

  Future<void> _handleBackNavigation() async {
    if (await _webViewController.canGoBack()) {
      await _webViewController.goBack();
      return;
    }
    await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          unawaited(_handleBackNavigation());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Smart Vision'),
          actions: [
            IconButton(
              tooltip: 'Reload website',
              onPressed: _websiteUrl.isEmpty
                  ? null
                  : () => _loadWebsite(_websiteUrl, persist: false),
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'Website connection settings',
              onPressed: _showWebsiteAddressDialog,
              icon: const Icon(Icons.settings_ethernet),
            ),
          ],
          bottom: _isLoading
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(2),
                  child: LinearProgressIndicator(
                    value: _loadingProgress == 0
                        ? null
                        : _loadingProgress / 100,
                  ),
                )
              : null,
        ),
        body: Column(
          children: [
            if (_statusMessage != null)
              MaterialBanner(
                content: Text(_statusMessage!),
                actions: [
                  TextButton(
                    onPressed: () => setState(() => _statusMessage = null),
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _webViewController),
                  if (_errorMessage != null)
                    Positioned.fill(
                      child: ColoredBox(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.wifi_off,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Smart Vision website is unavailable',
                                  style: Theme.of(context).textTheme.titleLarge,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$_errorMessage\n\nStart Streamlit on the computer '
                                  'with:\nstreamlit run app.py --server.address '
                                  '0.0.0.0 --server.port 8501\n\nFor a physical phone, '
                                  'set the Website URL to the computer’s LAN address '
                                  '(for example, http://192.168.1.20:8501).',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                Wrap(
                                  spacing: 12,
                                  children: [
                                    FilledButton(
                                      onPressed: () => _loadWebsite(
                                        _websiteUrl.isEmpty
                                            ? _defaultWebsiteUrl
                                            : _websiteUrl,
                                        persist: false,
                                      ),
                                      child: const Text('Retry'),
                                    ),
                                    OutlinedButton(
                                      onPressed: _showWebsiteAddressDialog,
                                      child: const Text('Set website URL'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
