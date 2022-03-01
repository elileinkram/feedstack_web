import 'package:flutter/material.dart';

class WaitingWidget extends StatelessWidget {
  final bool isLoading;
  final Color color;

  WaitingWidget({@required this.isLoading, @required this.color});

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: this.isLoading,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(this.color),
      ),
    );
  }
}
