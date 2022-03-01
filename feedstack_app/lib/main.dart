import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'loading_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]).then((_) {
    runApp(MaterialApp(
      theme: ThemeData(
          accentColor: Colors.white, accentColorBrightness: Brightness.dark),
      title: 'Feedstack',
      home: LoadingPage(),
      debugShowCheckedModeBanner: false,
    ));
  }).catchError((error) => print(error));
}
