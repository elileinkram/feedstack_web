import 'package:clipboard/clipboard.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:jasper/human.dart';
import 'package:jasper/loading_page.dart';
import 'package:jasper/password_update.dart';
import 'package:jasper/profile_update.dart';
import 'package:jasper/waiting_widget.dart';
import 'package:jasper/web_doc.dart';
import 'package:status_alert/status_alert.dart';
import 'constants.dart';

class SettingsPage extends StatefulWidget {
  final double expandedHeight;

  SettingsPage({@required this.expandedHeight});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final List<String> _settingsOptions = [
    'Update profile',
    'Privacy policy',
    'Reset password'
  ];

  bool _isLoading;

  void _updateProfile(BuildContext context) {
    Navigator.of(context)
        .push(CupertinoPageRoute(builder: (BuildContext context) {
      return ProfileUpdate(
        expandedHeight: this.widget.expandedHeight,
      );
    })).catchError((error) => print(error));
  }

  void _launchPrivacyPolicy(BuildContext context) async {
    Navigator.of(context)
        .push(CupertinoPageRoute(builder: (BuildContext context) {
      return WebDoc(title: 'Privacy policy', initialUrl: kPrivacyPolicyURL);
    })).catchError((error) => print(error));
  }

  void _navigateToUpdatePasswordPage(BuildContext context) {
    Navigator.of(context)
        .push(CupertinoPageRoute(builder: (BuildContext context) {
      return PasswordUpdate(
        initEmail: Human.email,
      );
    })).catchError((error) => print(error));
  }

  void _onBack(BuildContext context) {
    Navigator.of(context).pop();
  }

  List<Function> get _settingsFunctions {
    return [
      _updateProfile,
      _launchPrivacyPolicy,
      _navigateToUpdatePasswordPage
    ];
  }

  void _toggleIsLoading() {
    _isLoading = !_isLoading;
    if (mounted) {
      setState(() {});
    }
  }

  void _initHuman() {
    Human.user = null;
    Human.profilePhoto = null;
    Human.username = null;
    Human.uid = null;
    Human.email = null;
    Human.coverPhoto = null;
    Human.following = null;
    Human.hasDownloaded = null;
    Human.hasBlocked = null;
    Human.hasBeenBlockedBy = null;
    Human.hasDeleted = null;
    Human.myChannels = null;
    Human.recentUserSearches = null;
    Human.recentChannelSearches = null;
    Human.fProfilePhoto = null;
    Human.fCoverPhoto = null;
    Human.userActions = null;
    Human.reactionsToHave = null;
    Human.peopleToFollow = null;
    Human.actionsToTake = null;
    Human.channelsToDownload = null;
    Human.numberOfIthReactions = null;
    Human.followingCount = null;
    Human.followerCount = null;
    Human.hasJustCreatedAccount = null;
    Human.numberOfUnreadNotifications = null;
    Human.numberOfChannels = null;
  }

  Future<bool> _canLogout() {
    return showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10 * 2 / 3))),
            content: RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: 'Are you sure you want to ',
                  style: TextStyle(
                      color: Colors.black87, fontSize: kTitleFontSize),
                ),
                TextSpan(
                  text: 'logout?',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: kTitleFontSize,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ]),
            ),
            actions: [
              FlatButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: Text(
                  'No',
                  style: TextStyle(color: Colors.blueAccent),
                ),
              ),
              FlatButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: Text(
                  'Yes',
                  style: TextStyle(color: Colors.blueAccent),
                ),
              )
            ],
          );
        }).catchError((error) => print(error));
  }

  void _updateUserToken(String uid, String token) {
    final HttpsCallable updateUserToken = CloudFunctions.instance
        .getHttpsCallable(functionName: 'updateUserToken');
    updateUserToken
        .call({'uid': uid, 'token': token}).catchError((error) => print(error));
  }

  Future<void> _logout() async {
    bool thereIsAnError = false;
    await FirebaseAuth.instance
        .signOut()
        .catchError((_) => thereIsAnError = true);
    await FirebaseMessaging()
        .deleteInstanceID()
        .catchError((_) => thereIsAnError = true);
    _updateUserToken(Human.uid, null);
    if (thereIsAnError) {
      _showErrorMsg();
    } else {
      _initHuman();
      if (mounted) {
        _navigateToEntrance();
      }
    }
  }

  void _navigateToEntrance() {
    Navigator.of(context).pushAndRemoveUntil(
        CupertinoPageRoute(
            builder: (BuildContext context) {
              return LoadingPage();
            },
            fullscreenDialog: true),
        (route) => false);
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

  @override
  void initState() {
    super.initState();
    _isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.blueAccent,
      child: SafeArea(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.white,
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
                  onPressed: () => this._onBack(context),
                ),
                Text(
                  'Settings',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: kTitleFontSize,
                      fontWeight: FontWeight.w500),
                )
              ],
            ),
          ),
          body: Column(
            children: [
              Material(
                color: Color(kDefaultBackgroundColor).withOpacity(0.5),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List<Widget>.generate(_settingsOptions.length,
                        (int index) {
                      return ListTile(
                        onTap: () => _settingsFunctions[index](context),
                        title: Text(
                          _settingsOptions[index],
                          style: TextStyle(color: Colors.black87),
                        ),
                        trailing: Icon(
                          Icons.keyboard_arrow_right,
                          color: Colors.black87.withOpacity(3 / 4),
                        ),
                      );
                    })),
              ),
              Expanded(
                  child: Align(
                alignment: Alignment.center,
                child: WaitingWidget(
                  color: Colors.blueAccent,
                  isLoading: _isLoading,
                ),
              )),
              Padding(
                padding: EdgeInsets.only(bottom: 10 * 2 / 3),
                child: FlatButton(
                  onPressed: () async {
                    if (_isLoading) {
                      return;
                    }
                    bool canLogout = await _canLogout();
                    canLogout = canLogout ?? false;
                    if (!canLogout) {
                      return;
                    }
                    _toggleIsLoading();
                    await _logout();
                    _toggleIsLoading();
                  },
                  child: Text(
                    'Logout',
                    style: TextStyle(
                        color: Colors.black87.withOpacity(1 / 3),
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Material(
                color: Color(kDefaultBackgroundColor).withOpacity(0.5),
                child: ListTile(
                  dense: true,
                  onTap: () {
                    FlutterClipboard.copy(Human.uid)
                        .catchError((error) => print(error));
                    StatusAlert.show(context,
                        margin: EdgeInsets.all(100 * 2 / 3),
                        borderRadius:
                            BorderRadius.all(Radius.circular(kPanelPadding)),
                        title: 'Copied',
                        duration: Duration(milliseconds: 1500),
                        configuration: IconConfiguration(icon: Icons.copy));
                  },
                  title: Center(
                    child: Text(
                      Human.uid ?? '',
                      style: TextStyle(
                          fontSize: 14.5,
                          color: Colors.blueGrey[100].withOpacity(2 / 3)),
                      textAlign: TextAlign.center,
                    ),
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
