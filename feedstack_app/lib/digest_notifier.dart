import 'package:flutter/material.dart';

class DigestNotifier extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onUpdate;
  final bool Function() shouldUpdate;
  final double cutoff;

  DigestNotifier(
      {@required this.child,
      @required this.onUpdate,
      @required this.cutoff,
      @required this.shouldUpdate});

  @override
  _DigestNotifierState createState() => _DigestNotifierState();
}

class _DigestNotifierState extends State<DigestNotifier> {
  @override
  Widget build(BuildContext context) {
    return NotificationListener(
      onNotification: (notification) {
        if (notification is ScrollNotification) {
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - widget.cutoff) {
            if (widget.shouldUpdate()) {
              widget.onUpdate();
            }
          }
        }
        return false;
      },
      child: widget.child,
    );
  }
}
