import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.blueAccent,
      child: Center(
        child: Icon(
          FontAwesome5Solid.align_center,
          color: Colors.white,
          size: 100 * 2 / 3,
        ),
      ),
    );
  }
}

