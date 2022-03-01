import 'package:flutter/material.dart';
import 'package:jasper/waiting_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'constants.dart';

class WebDoc extends StatefulWidget {
  final String title;
  final String initialUrl;

  WebDoc({@required this.title, @required this.initialUrl});

  @override
  _WebDocState createState() => _WebDocState();
}

class _WebDocState extends State<WebDoc> {
  bool _hasFinishedBooting;

  @override
  void initState() {
    super.initState();
    _hasFinishedBooting = false;
  }

  void _onBack() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.blueAccent,
          automaticallyImplyLeading: false,
          elevation: 0.0,
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
                widget.title,
                style: TextStyle(color: Colors.white, fontSize: kTitleFontSize),
              )
            ],
          ),
        ),
        body: Stack(
          children: [
            WebView(
              onPageFinished: (_) {
                _hasFinishedBooting = true;
                if (mounted) {
                  setState(() {});
                }
              },
              initialUrl: widget.initialUrl,
              javascriptMode: JavascriptMode.unrestricted,
              gestureNavigationEnabled: false,
            ),
            _hasFinishedBooting
                ? Container()
                : Align(
                    alignment: Alignment.center,
                    child: WaitingWidget(
                      isLoading: true,
                      color: Colors.blueAccent,
                    ),
                  ),
          ],
        ));
  }
}
