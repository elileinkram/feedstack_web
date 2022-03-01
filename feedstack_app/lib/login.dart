import 'dart:async';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jasper/constants.dart';
import 'package:jasper/human.dart';
import 'package:jasper/qna.dart';
import 'package:jasper/sign_in.dart';
import 'package:jasper/waiting_widget.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:jasper/web_doc.dart';
import 'loading_page.dart';

class Login extends StatefulWidget {
  final PageController pageController;
  final void Function(bool forward) navigateToPage;

  Login({@required this.pageController, @required this.navigateToPage});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool _obscurePassword;
  bool _isLoading;
  final Map<String, String> _userData = {
    'email': '',
    'username': '',
    'password': ''
  };

  String _getEmailErrorMsg(String txt) {
    _userData['email'] = txt;
    if (EmailValidator.validate(txt)) {
      return null;
    }
    return kEmailErrors[0];
  }

  String _getPasswordErrorMsg(String txt) {
    _userData['password'] = txt;
    if (txt.length < kPasswordMinLength) {
      return kPasswordError;
    }
    return null;
  }

  String _getUsernameErrorMsg(String txt) {
    _userData['username'] = txt;
    if (!RegExp(r"^[a-zA-Z0-9_]*$").hasMatch(txt)) {
      return kUsernameErrors['content'];
    }
    if (txt.length < 3) {
      return kUsernameErrors['length'];
    }
    return null;
  }

  IconData _passwordIcon() {
    if (_obscurePassword) {
      return Icons.visibility;
    }
    return Icons.visibility_off;
  }

  void _toggleVisibility() {
    _obscurePassword = !_obscurePassword;
    setState(() {});
  }

  void _hideKeypad() {
    WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
  }

  void _onPageChanged(int currentIndex) {
    _hideKeypad();
  }

  void _navigateToSignInPage() {
    Navigator.of(context)
        .push(CupertinoPageRoute(builder: (BuildContext context) {
      return SignIn();
    })).catchError((error) => print(error));
    _hideKeypad();
    _scheduleJump(1000 ~/ 9);
  }

  void _scheduleJump(int milliseconds) {
    Timer(Duration(milliseconds: milliseconds), () {
      widget.pageController.jumpTo(0.0);
    });
  }

  void _showErrorMsg([String msg]) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10 * 2 / 3))),
            content: Text(msg ?? kDefaultErrorMsg),
            actions: [
              FlatButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Okay',
                  style: TextStyle(color: Colors.blueAccent),
                ),
              )
            ],
          );
        }).catchError((error) => print(error));
  }

  void _toggleLoadingIndicator() {
    _isLoading = !_isLoading;
    if (mounted) {
      setState(() {});
    }
  }

  Future<String> _getToken() async {
    FirebaseMessaging firebaseMessaging = FirebaseMessaging();
    final String token =
        await firebaseMessaging.getToken().catchError((error) => print(error));
    return token;
  }

  Future<void> _createAccount(
      String email, String password, String username) async {
    if (username.trim().toLowerCase() == kAppName) {
      _showErrorMsg('Someone else is already using this username.');
      return;
    }
    final String token = await _getToken();
    final HttpsCallable makeUserAndProfile = CloudFunctions.instance
        .getHttpsCallable(functionName: 'makeUserAndProfile');
    final HttpsCallableResult result = await makeUserAndProfile.call({
      'email': email,
      'password': password,
      'username': username,
      'token': token,
    }).catchError((error) => print(error));
    if (result == null) {
      _showErrorMsg();
    } else {
      final int data = result.data;
      if (data == -2) {
        _showErrorMsg('Someone else is already using this username.');
      } else if (data == -1) {
        _showErrorMsg(kEmailErrors[1]);
      } else if (data == 0) {
        _showErrorMsg();
      } else {
        final UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password)
            .catchError((error) => print(error));
        if (userCredential == null) {
          _showErrorMsg();
        } else {
          Human.hasJustCreatedAccount = true;
          if (mounted) {
            _navigateToLoadingPage();
          }
        }
      }
    }
  }

  void _navigateToLoadingPage() {
    Navigator.of(context)
        .pushAndRemoveUntil(
            CupertinoPageRoute(
                builder: (BuildContext context) {
                  return LoadingPage();
                },
                fullscreenDialog: true),
            (_) => false)
        .catchError((error) => print(error));
  }

  void _launchPrivacyPolicy() async {
    Navigator.of(context)
        .push(CupertinoPageRoute(builder: (BuildContext context) {
      return WebDoc(title: 'Privacy policy', initialUrl: kPrivacyPolicyURL);
    })).catchError((error) => print(error));
  }

  @override
  void initState() {
    super.initState();
    _obscurePassword = true;
    _isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Color(kDefaultDarkBackgroundColor),
      child: SafeArea(
        child: GestureDetector(
          onTap: _hideKeypad,
          child: Stack(
            children: [
              PageView(
                onPageChanged: _onPageChanged,
                physics: NeverScrollableScrollPhysics(),
                controller: widget.pageController,
                children: [
                  Qna(
                    isLoading: _isLoading,
                    buttonTxt: 'Next',
                    suffixIcons: [
                      Icon(
                        Icons.email,
                        color: Colors.white,
                      )
                    ],
                    getErrorMsg: [_getEmailErrorMsg],
                    q: 'Create a new account',
                    // q: 'Connect your email',
                    onNext: () async {
                      widget.navigateToPage(true);
                    },
                    maxFieldLengths: [null],
                    hintFields: ['Email'],
                    obscureFields: [false],
                    numberOfFields: 1,
                    bottomWidget: Container(),
                  ),
                  Qna(
                    numberOfFields: 1,
                    onBack: () {
                      widget.navigateToPage(false);
                    },
                    isLoading: _isLoading,
                    buttonTxt: 'Next',
                    suffixIcons: [
                      IconButton(
                        icon: Icon(_passwordIcon(), color: Colors.white),
                        onPressed: _toggleVisibility,
                      )
                    ],
                    maxFieldLengths: [null],
                    getErrorMsg: [_getPasswordErrorMsg],
                    q: 'Secure your account',
                    onNext: () {
                      widget.navigateToPage(true);
                    },
                    hintFields: ['Password'],
                    obscureFields: [_obscurePassword],
                    bottomWidget: Container(),
                  ),
                  Qna(
                    numberOfFields: 1,
                    onBack: () {
                      if (_isLoading) {
                        return;
                      }
                      widget.navigateToPage(false);
                    },
                    isLoading: _isLoading,
                    maxFieldLengths: [kUsernameMaxLength],
                    buttonTxt: 'Create account',
                    suffixIcons: [
                      Icon(
                        Icons.person,
                        color: Colors.white,
                      )
                    ],
                    getErrorMsg: [_getUsernameErrorMsg],
                    q: 'Choose a username',
                    onNext: () async {
                      if (_isLoading) {
                        return;
                      }
                      _toggleLoadingIndicator();
                      await _createAccount(_userData['email'],
                          _userData['password'], _userData['username']);
                      _toggleLoadingIndicator();
                    },
                    hintFields: ['Username'],
                    obscureFields: [false],
                    bottomWidget: Expanded(
                      child: Column(
                        children: [
                          SizedBox(height: kPanelPadding * 2.5),
                          GestureDetector(
                            onTap: _launchPrivacyPolicy,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'By creating an account you agree to our',
                                  style: TextStyle(
                                      color: Colors.blueGrey[50],
                                      fontSize: 14.0 * (1 - 1 / 30)),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 10 / 4.5),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Privacy Policy',
                                      style: TextStyle(
                                        fontSize: 14.0 * (1 - 1 / 30),
                                        color: Colors.blueGrey[50],
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    Text(
                                      '.',
                                      style: TextStyle(
                                        fontSize: 14.0 * (1 - 1 / 30),
                                        color: Colors.blueGrey[50],
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                          Expanded(
                            child: !_isLoading
                                ? Container()
                                : Align(
                                    alignment: Alignment.center,
                                    child: WaitingWidget(
                                      isLoading: _isLoading,
                                      color: Colors.white,
                                    )),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: 10 * 2 / 3),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FlatButton(
                                disabledColor: Colors.transparent,
                                child: Container(),
                                onPressed: null,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 10 * 2 / 3),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FlatButton(
                    child: Text(
                      'Already have an account?',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: _navigateToSignInPage,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
