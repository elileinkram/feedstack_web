import 'package:flutter/material.dart';
import 'package:jasper/playground.dart';
import 'constants.dart';

class PostPage extends StatefulWidget {
  @override
  _PostPageState createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  void _onBack() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
          backgroundColor: Colors.blueAccent,
          elevation: 0.0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
                onPressed: this._onBack,
              ),
              Text(
                'New post',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: kTitleFontSize,
                    fontWeight: FontWeight.w500),
              )
            ],
          )),
      body: Material(
        color: Color(kDefaultBackgroundColor),
        child: ListView(
          children: [
            SizedBox(height: kPanelPadding * (1 + 1 / 3)),
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: kPanelPadding * (1 + 1 / 3)),
              child: Playground(
                fontSize: kTitleFontSize,
              ),
            )
          ],
        ),
      ),
    );
  }
}
