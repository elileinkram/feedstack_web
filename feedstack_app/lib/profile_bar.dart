import 'package:clipboard/clipboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:jasper/settings_page.dart';
import 'package:status_alert/status_alert.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'constants.dart';
import 'human.dart';
import 'notification_page.dart';

class ProfileBar extends StatefulWidget {
  final String username;
  final String uid;
  final double expandedHeight;
  final bool isClient;
  final VoidCallback refreshProfile;

  ProfileBar(
      {@required this.username,
      @required this.uid,
      @required this.expandedHeight,
      @required this.isClient,
      @required this.refreshProfile});

  @override
  _ProfileBarState createState() => _ProfileBarState();
}

class _ProfileBarState extends State<ProfileBar> {
  bool _isFollowing() {
    return Human.following.contains(widget.uid);
  }

  final UniqueKey _visibilityKey = UniqueKey();

  bool _scheduleUpdate;

  void _setHumanFollowing(int value) {
    Human.peopleToFollow[widget.uid] = value;
  }

  void _onBack() {
    Navigator.of(context).pop();
  }

  Future<bool> _canUnfollow() {
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
                  text: 'unfollow ',
                  style: TextStyle(
                      color: Colors.black87,
                      fontSize: kTitleFontSize,
                      fontWeight: FontWeight.w300),
                ),
                TextSpan(
                  text: _getUsername(),
                  style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: kTitleFontSize,
                      fontWeight: FontWeight.w400),
                ),
                TextSpan(
                  text: '.',
                  style: TextStyle(
                      color: Colors.black87, fontSize: kTitleFontSize),
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

  String _buttonTxt() {
    if (Human.hasBlocked.contains(widget.uid)) {
      return 'Unblock';
    }
    if (_isFollowing()) {
      return 'Following';
    }
    return 'Follow';
  }

  void _updateFollowers() {
    final List<String> followingUsers = Human.peopleToFollow.keys.toList();
    for (int i = 0; i < followingUsers.length; i++) {
      final String userUID = followingUsers[i];
      final int followCount = Human.peopleToFollow[userUID];
      if (followCount == 0) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(userUID)
            .collection('followers')
            .doc(Human.uid)
            .delete()
            .catchError((error) => print(error));
      } else if (followCount == 1) {
        _followUser(userUID);
      }
    }
    Human.peopleToFollow = Map<String, int>();
  }

  void _followUser(String userUID) {
    if (Human.hasBlocked.contains(userUID)) {
      return;
    }
    final HttpsCallable followUser =
        CloudFunctions.instance.getHttpsCallable(functionName: 'followUser');
    followUser.call({'uid': Human.uid, 'userUID': userUID}).catchError(
        (error) => print(error));
  }

  void _navigateToSettingsPage() {
    Navigator.of(context)
        .push(CupertinoPageRoute(builder: (BuildContext context) {
      return SettingsPage(
        expandedHeight: widget.expandedHeight,
      );
    })).then((_) {
      widget.refreshProfile();
    }).catchError((error) => print(error));
  }

  bool _hasAlreadyUpdated() {
    return !Human.peopleToFollow.containsKey(widget.uid);
  }

  bool _isOutOfSight(VisibilityInfo info) {
    return info.visibleFraction == 0.0;
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (_isOutOfSight(info) && _scheduleUpdate && !_hasAlreadyUpdated()) {
      _scheduleUpdate = false;
      _updateFollowers();
    }
  }

  void _unfollow() {
    Human.following.remove(widget.uid);
    _setHumanFollowing(0);
    Human.followingCount--;
  }

  String _getUsername() {
    return widget.isClient ? Human.username : widget.username;
  }

  void _follow() {
    Human.following.add(widget.uid);
    _setHumanFollowing(1);
    Human.followingCount++;
  }

  void _navigateToNotificationPage() {
    Navigator.of(context)
        .push(CupertinoPageRoute(builder: (BuildContext context) {
      return NotificationPage();
    })).then((_) {
      widget.refreshProfile();
    });
  }

  Future<void> _showErrorMsg([String msg]) {
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
              ),
            ],
          );
        }).catchError((error) => print(error));
  }

  Future<bool> _canBlock(String label) {
    return showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(kPanelPadding))),
            title: Text('${label[0].toUpperCase() + label.substring(1)} user'),
            content: Text('Are you sure you want to $label this user?'),
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

  @override
  void initState() {
    super.initState();
    _scheduleUpdate = false;
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      onVisibilityChanged: _onVisibilityChanged,
      key: _visibilityKey,
      child: Row(
        children: [
          SizedBox(width: NavigationToolbar.kMiddleSpacing),
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: _onBack,
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _getUsername(),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white, fontSize: kTitleFontSize),
                  ),
                ),
                SizedBox(width: NavigationToolbar.kMiddleSpacing),
                if (widget.isClient)
                  Row(
                    children: [
                      IconButton(
                        onPressed: _navigateToNotificationPage,
                        icon: Icon(
                          Feather.bell,
                          color: Human.numberOfUnreadNotifications != null &&
                                  Human.numberOfUnreadNotifications > 0
                              ? Colors.white
                              : Colors.white.withOpacity(2 / 3),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Ionicons.ios_settings,
                          color: Colors.white,
                          size: 20 + 10 * 2 / 3,
                        ),
                        onPressed: _navigateToSettingsPage,
                      ),
                      SizedBox(width: NavigationToolbar.kMiddleSpacing),
                    ],
                  )
                else
                  Row(
                    children: [
                      Human.hasBeenBlockedBy.contains(widget.uid) &&
                              !Human.hasBlocked.contains(widget.uid)
                          ? FlatButton(
                              color: Colors.redAccent,
                              shape: StadiumBorder(),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onPressed: () async {
                                final bool canBlock =
                                    await _canBlock('block') ?? false;
                                if (canBlock) {
                                  Human.hasBlocked.add(widget.uid);
                                  final bool hasRemovedFromFollowing =
                                      Human.following.remove(widget.uid);
                                  if (hasRemovedFromFollowing) {
                                    Human.followingCount--;
                                  }
                                  widget.refreshProfile();
                                  final HttpsCallable blockUser =
                                      CloudFunctions.instance.getHttpsCallable(
                                          functionName: 'blockUser');
                                  blockUser.call({
                                    'userID': widget.uid,
                                    'uid': Human.uid
                                  }).catchError((error) => print(error));
                                  StatusAlert.show(
                                    context,
                                    margin: EdgeInsets.all(100 * 2 / 3),
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(kPanelPadding)),
                                    title: 'Blocked',
                                    duration: Duration(milliseconds: 1500),
                                    configuration:
                                        IconConfiguration(icon: Icons.block),
                                  );
                                }
                              },
                              child: Text(
                                'Block',
                                style: TextStyle(
                                  fontSize: kTitleFontSize * 0.875,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : FlatButton(
                              color: Colors.blueAccent,
                              shape: StadiumBorder(),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              height: 100 / 3,
                              onPressed: () async {
                                if (Human.hasBlocked.contains(widget.uid)) {
                                  final bool canUnblock =
                                      await _canBlock('unblock') ?? false;
                                  if (canUnblock) {
                                    Human.hasBlocked.remove(widget.uid);
                                    widget.refreshProfile();
                                    final HttpsCallable unblockUser =
                                        CloudFunctions
                                            .instance
                                            .getHttpsCallable(
                                                functionName: 'unblockUser');
                                    unblockUser.call({
                                      'userID': widget.uid,
                                      'uid': Human.uid
                                    }).catchError((error) => print(error));
                                    StatusAlert.show(
                                      context,
                                      margin: EdgeInsets.all(100 * 2 / 3),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(kPanelPadding)),
                                      title: 'Unblocked',
                                      duration: Duration(milliseconds: 1500),
                                      configuration:
                                          IconConfiguration(icon: Icons.done),
                                    );
                                  }
                                } else {
                                  _scheduleUpdate = true;
                                  if (_isFollowing()) {
                                    final bool canUnfollow =
                                        await _canUnfollow() ?? false;
                                    if (canUnfollow) {
                                      _unfollow();
                                    }
                                  } else {
                                    if (Human.followingCount >= 10000) {
                                      _showErrorMsg(
                                          'You can\'t follow more than 10,000 people.');
                                    } else {
                                      _follow();
                                    }
                                  }
                                  if (mounted) {
                                    setState(() {});
                                  }
                                }
                              },
                              child: Text(
                                _buttonTxt(),
                                style: TextStyle(
                                  fontSize: kTitleFontSize * 0.875,
                                  color: Color(kDefaultBackgroundColor),
                                ),
                              ),
                            ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _showUserOptions,
                          child: SizedBox(
                            height: 200.0,
                            child: Padding(
                                padding: EdgeInsets.only(
                                    left: NavigationToolbar.kMiddleSpacing *
                                        0.875,
                                    right: NavigationToolbar.kMiddleSpacing *
                                        (1 + 1 / 3)),
                                child: Icon(
                                  Entypo.dots_three_vertical,
                                  size: 15.0,
                                  color: Human.hasBeenBlockedBy
                                          .contains(widget.uid)
                                      ? Colors.white
                                      : Colors.blueGrey[50],
                                )),
                          ),
                        ),
                      )
                    ],
                  )
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showUserOptions() {
    bool hasBlockedUser = false;
    bool hasCopiedID = false;
    bool hasUnblockedUser = false;
    Color backgroundColor = Human.hasBlocked.contains(widget.uid)
        ? Colors.blueAccent
        : Colors.redAccent;
    String title = Human.hasBlocked.contains(widget.uid)
        ? 'Unblock this user'
        : 'Block this user';
    bool hasTapped = false;
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SizedBox(
            height: 180.0,
            width: double.infinity,
            child: Material(
                color: Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(child: Container()),
                    Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal:
                                kPanelPadding * (1 + 1 / 3) * (1 + 1 / 9) +
                                    kPanelPadding * (1 + 1 / 3)),
                        child: Column(
                          children: [
                            Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: FlatButton(
                                      shape: StadiumBorder(),
                                      height: 36.0,
                                      color: backgroundColor,
                                      onPressed: () async {
                                        if (hasTapped) {
                                          return;
                                        }
                                        hasTapped = true;
                                        if (Human.hasBlocked
                                            .contains(widget.uid)) {
                                          final bool canUnblock =
                                              await _canBlock('unblock') ??
                                                  false;
                                          if (canUnblock) {
                                            hasUnblockedUser = true;
                                            Human.hasBlocked.remove(widget.uid);
                                            widget.refreshProfile();
                                            final HttpsCallable unblockUser =
                                                CloudFunctions.instance
                                                    .getHttpsCallable(
                                                        functionName:
                                                            'unblockUser');
                                            unblockUser.call({
                                              'userID': widget.uid,
                                              'uid': Human.uid
                                            }).catchError(
                                                (error) => print(error));
                                          }
                                        } else {
                                          final bool canBlock =
                                              await _canBlock('block') ?? false;
                                          if (canBlock) {
                                            hasBlockedUser = true;
                                            Human.hasBlocked.add(widget.uid);
                                            final bool hasRemovedFromFollowing =
                                                Human.following
                                                    .remove(widget.uid);
                                            if (hasRemovedFromFollowing) {
                                              Human.followingCount--;
                                            }
                                            widget.refreshProfile();
                                            final HttpsCallable blockUser =
                                                CloudFunctions.instance
                                                    .getHttpsCallable(
                                                        functionName:
                                                            'blockUser');
                                            blockUser.call({
                                              'userID': widget.uid,
                                              'uid': Human.uid
                                            }).catchError(
                                                (error) => print(error));
                                          }
                                        }
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(
                                        title,
                                        style: TextStyle(color: Colors.white),
                                      )),
                                ),
                                SizedBox(height: 10 / 3),
                              ],
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: FlatButton(
                                  height: 36.0,
                                  shape: StadiumBorder(),
                                  color: Colors.blueGrey[100],
                                  onPressed: () {
                                    if (hasTapped) {
                                      return;
                                    }
                                    hasTapped = true;
                                    hasCopiedID = true;
                                    FlutterClipboard.copy(widget.uid)
                                        .catchError((error) => print(error));
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(
                                    'Copy ID to clipboard',
                                    style: TextStyle(color: Colors.white),
                                  )),
                            ),
                          ],
                        )),
                    Expanded(child: Container()),
                    IconButton(
                        icon: Icon(
                          Icons.arrow_downward,
                          color: Colors.blueGrey[200],
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        }),
                    SizedBox(
                      height: 10 / 3,
                    )
                  ],
                )),
          );
        }).then((_) {
      if (hasBlockedUser) {
        StatusAlert.show(
          context,
          margin: EdgeInsets.all(100 * 2 / 3),
          borderRadius: BorderRadius.all(Radius.circular(kPanelPadding)),
          title: 'Blocked',
          duration: Duration(milliseconds: 1500),
          configuration: IconConfiguration(icon: Icons.block),
        );
      } else if (hasCopiedID) {
        StatusAlert.show(
          context,
          margin: EdgeInsets.all(100 * 2 / 3),
          borderRadius: BorderRadius.all(Radius.circular(kPanelPadding)),
          title: 'Copied',
          duration: Duration(milliseconds: 1500),
          configuration: IconConfiguration(icon: Icons.copy),
        );
      } else if (hasUnblockedUser) {
        StatusAlert.show(
          context,
          margin: EdgeInsets.all(100 * 2 / 3),
          borderRadius: BorderRadius.all(Radius.circular(kPanelPadding)),
          title: 'Unblocked',
          duration: Duration(milliseconds: 1500),
          configuration: IconConfiguration(icon: Icons.done),
        );
      }
    }).catchError((error) => print(error));
  }

  @override
  void dispose() {
    super.dispose();
    if (widget.isClient) {
      return;
    }
    _updateFollowers();
  }
}

