import 'package:flutter/material.dart';

class FrumWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onLifecycleChanged;

  FrumWidget({@required this.child, @required this.onLifecycleChanged});

  @override
  _FrumWidgetState createState() => _FrumWidgetState();
}

class _FrumWidgetState extends State<FrumWidget> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      widget.onLifecycleChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
