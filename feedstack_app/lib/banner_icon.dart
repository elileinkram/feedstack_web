import 'package:flutter/material.dart';

class BannerIcon extends StatelessWidget {
  final String msg;
  final String emoticon;

  BannerIcon({@required this.msg, @required this.emoticon});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          this.emoticon,
          style: TextStyle(
              color: Colors.black87,
              fontStyle: FontStyle.italic,
              fontSize: 27.5),
        ),
        SizedBox(height: 12.5),
        Text(
          this.msg,
          style: TextStyle(
              color: Colors.black87,
              fontSize: 15.0,
              fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}
