import 'package:flutter/widgets.dart';

/// يستدعي onResumed عندما يعود المستخدم إلى التطبيق بعد أن خرج منه
/// (مثلًا بعد فتح المتصفح لإتمام الدفع).
class AppResumeListener extends StatefulWidget {
  final VoidCallback onResumed;
  final Widget child;

  const AppResumeListener({
    super.key,
    required this.onResumed,
    required this.child,
  });

  @override
  State<AppResumeListener> createState() => _AppResumeListenerState();
}

class _AppResumeListenerState extends State<AppResumeListener>
    with WidgetsBindingObserver {
  bool _wasInBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _wasInBackground = true;
    } else if (state == AppLifecycleState.resumed && _wasInBackground) {
      _wasInBackground = false;
      widget.onResumed();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
