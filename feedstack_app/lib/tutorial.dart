// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:jasper/waiting_widget.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'constants.dart';
//
// class Tutorial extends StatefulWidget {
//   @override
//   _TutorialState createState() => _TutorialState();
// }
//
// class _TutorialState extends State<Tutorial> {
//   Future<void> _onBack() async {
//     final WebViewController controller = await _controller.future;
//     if (await controller.canGoBack()) {
//       controller.goBack();
//     } else {
//       if (mounted) {
//         Navigator.of(context).pop();
//       }
//     }
//   }
//
//   void _onForward() async {
//     final WebViewController controller = await _controller.future;
//     if (await controller.canGoForward()) {
//       controller.goForward();
//     }
//   }
//
//   final Completer<WebViewController> _controller =
//       Completer<WebViewController>();
//
//   bool _hasFinishedBooting;
//
//   @override
//   void initState() {
//     super.initState();
//     _hasFinishedBooting = false;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async {
//         await _onBack();
//         return false;
//       },
//       child: Scaffold(
//           resizeToAvoidBottomInset: false,
//           appBar: AppBar(
//             backgroundColor: Colors.blueAccent,
//             automaticallyImplyLeading: false,
//             elevation: 0.0,
//             title: Row(
//               children: [
//                 IconButton(
//                   icon: Icon(
//                     Icons.arrow_back,
//                     color: Colors.white,
//                   ),
//                   onPressed: () {
//                     Navigator.of(context).pop();
//                   },
//                 ),
//                 Text(
//                   'ReadMe',
//                   style:
//                       TextStyle(color: Colors.white, fontSize: kTitleFontSize),
//                 ),
//                 Expanded(
//                   child: Container(),
//                 ),
//                 IconButton(
//                   icon: Icon(
//                     Icons.keyboard_arrow_left,
//                     color: Colors.white,
//                   ),
//                   onPressed: _onBack,
//                 ),
//                 IconButton(
//                   icon: Icon(
//                     Icons.keyboard_arrow_right,
//                     color: Colors.white,
//                   ),
//                   onPressed: _onForward,
//                 )
//               ],
//             ),
//           ),
//           body: Stack(
//             children: [
//               WebView(
//                 onPageFinished: (_) {
//                   _hasFinishedBooting = true;
//                   if (mounted) {
//                     setState(() {});
//                   }
//                 },
//                 initialUrl: kGithubRepoURL,
//                 javascriptMode: JavascriptMode.unrestricted,
//                 onWebViewCreated: (WebViewController webViewController) {
//                   _controller.complete(webViewController);
//                 },
//                 gestureNavigationEnabled: true,
//               ),
//               _hasFinishedBooting
//                   ? Container()
//                   : Align(
//                       alignment: Alignment.center,
//                       child: WaitingWidget(
//                         isLoading: true,
//                         color: Colors.blueAccent,
//                       ),
//                     ),
//             ],
//           )),
//     );
//   }
// }
