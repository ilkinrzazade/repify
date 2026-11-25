import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Shows YouTube form tutorials inside the app, so the user can return
/// with the back arrow instead of leaving Repify.
class VideoTutorialScreen extends StatefulWidget {
  final String exercise;
  final Uri url;

  const VideoTutorialScreen({
    super.key,
    required this.exercise,
    required this.url,
  });

  @override
  State<VideoTutorialScreen> createState() => _VideoTutorialScreenState();
}

class _VideoTutorialScreenState extends State<VideoTutorialScreen> {
  late final WebViewController controller;
  int progress = 0;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) {
            if (mounted) setState(() => progress = value);
          },
          // Stay inside the app: block "open in YouTube app" (intent://) links.
          onNavigationRequest: (request) => request.url.startsWith('http')
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
        ),
      )
      ..loadRequest(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.exercise} · video'),
        bottom: progress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(value: progress / 100),
              )
            : null,
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
