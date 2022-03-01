import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jasper/waiting_widget.dart';
import 'constants.dart';

class PasswordUpdate extends StatefulWidget {
  final String initEmail;

  PasswordUpdate({@required this.initEmail});

  @override
  _PasswordUpdateState createState() => _PasswordUpdateState();
}

class _PasswordUpdateState extends State<PasswordUpdate> {
  final InputBorder _focusedInputBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.blueAccent, width: 10 / 6));
  final InputBorder _unfocusedInputBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.blueGrey[100], width: 10 / 6));
  bool _isLoading;
  String _emailError;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _textEditingController = TextEditingController();

  void _onBack() {
    Navigator.of(context).pop();
  }

  void _toggleIsLoading() {
    _isLoading = !_isLoading;
    if (mounted) {
      setState(() {});
    }
  }

  String _getEmailErrorMsg(String txt) {
    if (EmailValidator.validate(txt)) {
      return null;
    }
    return kEmailErrors[0];
  }

  Future<void> _showMsg([String msg]) {
    return showDialog(
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

  bool _weHaveAnError() {
    return _emailError != null;
  }

  Future<void> _sendPasswordResetLink() async {
    if (widget.initEmail.isNotEmpty &&
        widget.initEmail != _textEditingController.text.trim()) {
      _showMsg('Please enter the email linked to this account.');
    } else {
      String errorMsg;
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _textEditingController.text.trim())
          .catchError((error) => errorMsg = error.code);
      if (errorMsg == kNotFoundError) {
        _showMsg(kEmailErrors[2]);
      } else if (errorMsg != null) {
        _showMsg();
      } else {
        _showMsg('Great success. A reset email has been sent to this address.')
            .then((_) {
          if (mounted) {
            _onBack();
          }
        });
      }
    }
  }

  Color _buttonColor() {
    if (_weHaveAnError()) {
      return Colors.blueGrey[100];
    }
    return Colors.blueAccent;
  }

  void _hideKeypad() {
    WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
  }

  @override
  void initState() {
    super.initState();
    _isLoading = false;
    _emailError = widget.initEmail.isEmpty ? kEmailErrors[0] : null;
    _textEditingController.text = widget.initEmail;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _hideKeypad,
      child: Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            elevation: 0.0,
            backgroundColor: Colors.blueAccent,
            title: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                  onPressed: _onBack,
                ),
                Text(
                  'Reset password',
                  style:
                      TextStyle(color: Colors.white, fontSize: kTitleFontSize),
                )
              ],
            ),
          ),
          body: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 17.5),
            child: Column(
              children: [
                SizedBox(height: 10 / 3),
                Padding(
                  padding: EdgeInsets.only(bottom: 17.5),
                  child: Form(
                    key: _formKey,
                    child: TextFormField(
                      enabled: !_isLoading,
                      controller: _textEditingController,
                      validator: (_) {
                        return _emailError;
                      },
                      autofocus: true,
                      cursorColor: Colors.blueAccent,
                      onChanged: (String txt) {
                        txt = txt.trim();
                        final String emailError = _getEmailErrorMsg(txt);
                        if (_emailError != emailError) {
                          _emailError = emailError;
                          if (!_weHaveAnError()) {
                            _formKey.currentState.validate();
                          }
                          setState(() {});
                        }
                      },
                      style: TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                          hintText: 'Email',
                          hintStyle: TextStyle(
                              color: Colors.black87.withOpacity(1 / 3)),
                          border: _focusedInputBorder,
                          enabledBorder: _unfocusedInputBorder,
                          focusedBorder: _focusedInputBorder),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FlatButton(
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.all(Radius.circular(10 / 3))),
                    onPressed: () async {
                      if (_isLoading) {
                        return;
                      }
                      if (_formKey.currentState.validate()) {
                        _toggleIsLoading();
                        await _sendPasswordResetLink();
                        _toggleIsLoading();
                      }
                    },
                    child: Text(
                      'Send link to update password',
                      style: TextStyle(color: Colors.white),
                    ),
                    color: _buttonColor(),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: WaitingWidget(
                      color: Colors.blueAccent,
                      isLoading: _isLoading,
                    ),
                  ),
                )
              ],
            ),
          )),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _textEditingController.dispose();
  }
}
