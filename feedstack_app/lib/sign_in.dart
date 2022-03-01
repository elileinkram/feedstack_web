import 'package:cloud_functions/cloud_functions.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jasper/constants.dart';
import 'package:jasper/password_update.dart';
import 'package:jasper/qna.dart';
import 'package:jasper/waiting_widget.dart';
import 'loading_page.dart';

class SignIn extends StatefulWidget {
  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  bool _isLoading;
  bool _obscurePassword;
  final Map<String, String> _userData = {
    'emailOrUsername': '',
    'password': '',
  };

  String _getEmailOrUsernameErrorMsg(String txt) {
    _userData['emailOrUsername'] = txt;
    return null;
  }

  String _getPasswordErrorMsg(String txt) {
    _userData['password'] = txt;
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

  bool _isEmail(String txt) {
    return EmailValidator.validate(txt);
  }

  Future<String> _getEmailFromUsername(String username, String password) async {
    final HttpsCallable getEmailFromUsername = CloudFunctions.instance
        .getHttpsCallable(functionName: 'getEmailFromUsername');
    final HttpsCallableResult result = await getEmailFromUsername
        .call({'username': username, 'password': password}).catchError(
            (error) => print(error));
    if (result == null) {
      return null;
    }
    return result.data;
  }

  void _toggleLoadingIndicator() {
    _isLoading = !_isLoading;
    if (mounted) {
      setState(() {});
    }
  }

  void _prepAccount(String emailOrUsername, String password) async {
    _toggleLoadingIndicator();
    final bool isEmail = _isEmail(emailOrUsername);
    if (isEmail) {
      final String email = emailOrUsername;
      await _signIn(email, password, isEmail);
    } else {
      final String username = emailOrUsername;
      final String email = await _getEmailFromUsername(username, password);
      if (email == null) {
        _showErrorMsg(_errorLabel(isEmail));
      } else {
        await _signIn(email, password, isEmail);
      }
    }
    _toggleLoadingIndicator();
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

  String _errorLabel(bool isEmail) {
    final String label = isEmail ? 'Email' : 'Username';
    return '$label or password is incorrect.';
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

  Future<void> _signIn(String email, String password, bool isEmail) async {
    final UserCredential userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password)
        .catchError((error) => print(error));
    if (userCredential == null) {
      _showErrorMsg(_errorLabel(isEmail));
    } else {
      final String uid = userCredential.user.uid;
      final String token = await _getToken();
      if (token == null) {
        _showErrorMsg();
      }
      _updateUserToken(uid, token);
      if (mounted) {
        _navigateToLoadingPage();
      }
    }
  }

  void _updateUserToken(String uid, String token) {
    final HttpsCallable updateUserToken = CloudFunctions.instance
        .getHttpsCallable(functionName: 'updateUserToken');
    updateUserToken
        .call({'token': token, 'uid': uid}).catchError((error) => print(error));
  }

  Future<String> _getToken() async {
    FirebaseMessaging firebaseMessaging = FirebaseMessaging();
    final String token =
        await firebaseMessaging.getToken().catchError((error) => print(error));
    return token;
  }

  void _navigateToPasswordUpdatePage() {
    Navigator.of(context)
        .push(CupertinoPageRoute(builder: (BuildContext context) {
      return PasswordUpdate(
        initEmail: '',
      );
    }));
  }

  @override
  void initState() {
    super.initState();
    _isLoading = false;
    _obscurePassword = true;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Color(kDefaultDarkBackgroundColor),
      child: SafeArea(
        child: Stack(
          children: [
            Qna(
              onBack: () {
                Navigator.of(context).pop();
              },
              isLoading: _isLoading,
              buttonTxt: 'Sign In',
              suffixIcons: [
                null,
                IconButton(
                  icon: Icon(_passwordIcon(), color: Colors.white),
                  onPressed: _toggleVisibility,
                )
              ],
              getErrorMsg: [_getEmailOrUsernameErrorMsg, _getPasswordErrorMsg],
              q: 'Welcome back',
              onNext: () async {
                if (_isLoading) {
                  return;
                }
                _prepAccount(
                    _userData['emailOrUsername'], _userData['password']);
              },
              maxFieldLengths: [null, null],
              hintFields: ['Username or email', 'Password'],
              obscureFields: [false, _obscurePassword],
              numberOfFields: 2,
              bottomWidget: Expanded(
                child: Column(
                  children: [
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
                          child: Text(
                            'Forgot password?',
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: _navigateToPasswordUpdatePage,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
