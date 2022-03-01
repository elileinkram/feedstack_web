import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jasper/town_hall.dart';
import 'constants.dart';
import 'human.dart';
import 'login.dart';
import 'splash_screen.dart';
import 'frum_widget.dart';

class LoadingPage extends StatefulWidget {
  @override
  _LoadingPageState createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  int _currentIndex;
  final PageController _pageController = PageController();

  Future<User> _getUser() async {
    await Firebase.initializeApp().catchError((error) => print(error));
    return FirebaseAuth.instance.currentUser;
  }

  bool _isLoggedIn(User user) {
    return user != null;
  }

  void _updateIndex(int index) {
    _currentIndex = index;
  }

  void _navigateToLoginPage() {
    _updateIndex(2);
    if (mounted) {
      setState(() {});
    }
  }

  void _navigateToMainPage() {
    _updateIndex(1);
    if (mounted) {
      setState(() {});
    }
  }

  void _formUser(User user) {
    Human.user = user;
    Human.email = user.email;
    Human.uid = user.uid;
    Human.following = Set<String>();
    Human.hasDownloaded = Set<String>();
    Human.hasBlocked = Set<String>();
    Human.hasBeenBlockedBy = Set<String>();
    Human.hasDeleted = Set<String>();
    Human.myChannels = List<Map<String, dynamic>>();
    Human.recentChannelSearches = List<DocumentSnapshot>();
    Human.recentUserSearches = List<DocumentSnapshot>();
    Human.actionsToTake = Map<String, int>();
    Human.channelsToDownload = Map<String, int>();
    Human.peopleToFollow = Map<String, int>();
    Human.reactionsToHave = Map<String, int>();
    Human.userActions = Map<String, int>();
    Human.hasJustCreatedAccount = Human.hasJustCreatedAccount ?? false;
    if (mounted) {
      setState(() {});
    }
  }

  bool _showMainPage() {
    return Human.uid != null;
  }

  bool _countdownHasEnded;

  void _beginCountdown() {
    Timer(Duration(milliseconds: 10000 ~/ 3), () {
      if (!_countdownHasEnded) {
        _countdownHasEnded = true;
        if (!_hasRedirected()) {
          _redirectUser(Human.user);
        }
      }
    });
  }

  bool _hasRedirected() {
    return _currentIndex != 0;
  }

  void _redirectUser(User user) {
    if (_isLoggedIn(user)) {
      _navigateToMainPage();
    } else {
      _navigateToLoginPage();
    }
  }

  bool _actionValueIsNotNull(int value) {
    return value != kNullActionValue;
  }

  void _changeAction(
      String postID, int reactionSelected, bool actionValueIsNotNull) async {
    final DocumentReference docRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(postID)
        .collection('reactions')
        .doc(Human.uid);
    if (actionValueIsNotNull) {
      _makeReaction(postID, reactionSelected);
    } else {
      _unmakeReaction(docRef);
    }
  }

  void _unmakeReaction(DocumentReference docRef) {
    docRef.delete().catchError((error) => print(error));
  }

  void _makeReaction(String postID, int reactionSelected) {
    final HttpsCallable makeReaction =
        CloudFunctions.instance.getHttpsCallable(functionName: 'makeReaction');
    makeReaction.call({
      'uid': Human.uid,
      'postID': postID,
      'reactionSelected': reactionSelected
    }).catchError((error) => print(error));
  }

  void _updateReactions() {
    final List<String> postIDs = Human.reactionsToHave.keys.toList();
    for (int i = 0; i < postIDs.length; i++) {
      final String postID = postIDs[i];
      final int reactionSelected = Human.reactionsToHave[postID];
      final bool actionValueIsNotNull = _actionValueIsNotNull(reactionSelected);
      _changeAction(postID, reactionSelected, actionValueIsNotNull);
    }
    if (Human.reactionsToHave.isNotEmpty) {
      Human.reactionsToHave = Map<String, int>();
    }
  }

  void _processActions() {
    if (!_showMainPage()) {
      return;
    }
    _updateReactions();
    _updateFollowers();
    _updateDownloads();
  }

  String _newCurrentChannel() {
    Human.myChannels.sort((a, b) => b['lastUsed'] - a['lastUsed']);
    if (Human.myChannels.isEmpty) {
      return null;
    }
    return Human.myChannels.first['channelID'];
  }

  void _installChannel(String channelID) {
    final HttpsCallable installChannel = CloudFunctions.instance
        .getHttpsCallable(functionName: 'installChannel');
    installChannel.call({'uid': Human.uid, 'channelID': channelID}).catchError(
        (error) => print(error));
  }

  void _uninstallChannel(String channelID) {
    final HttpsCallable uninstallChannel = CloudFunctions.instance
        .getHttpsCallable(functionName: 'uninstallChannel');
    uninstallChannel.call({
      'uid': Human.uid,
      'channelID': channelID,
      'newChannelID': _newCurrentChannel(),
    }).catchError((error) => print(error));
  }

  void _updateDownloads() {
    final List<String> downloadChannels =
        Human.channelsToDownload.keys.toList();
    for (int i = 0; i < downloadChannels.length; i++) {
      final String channelID = downloadChannels[i];
      final bool shouldDownload = Human.channelsToDownload[channelID] == 1;
      if (shouldDownload) {
        _installChannel(channelID);
      } else {
        _uninstallChannel(channelID);
      }
    }
    if (Human.channelsToDownload.isNotEmpty) {
      Human.channelsToDownload = Map<String, int>();
    }
  }

  void _updateFollowers() {
    final List<String> followingUsers = Human.peopleToFollow.keys.toList();
    for (int i = 0; i < followingUsers.length; i++) {
      final String userUID = followingUsers[i];
      final int followVal = Human.peopleToFollow[userUID];
      if (followVal == 0) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(userUID)
            .collection('followers')
            .doc(Human.uid)
            .delete()
            .catchError((error) => print(error));
      } else if (followVal == 1) {
        _followUser(userUID);
      }
    }
    if (Human.peopleToFollow.isNotEmpty) {
      Human.peopleToFollow = Map<String, int>();
    }
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

  void _navigatePage(bool forward) {
    if (forward) {
      _pageController
          .nextPage(
              duration: Duration(milliseconds: 1000 ~/ 3),
              curve: Curves.fastOutSlowIn)
          .catchError((error) => print(error));
    } else {
      _pageController
          .previousPage(
              duration: Duration(milliseconds: 1000 ~/ 3),
              curve: Curves.fastOutSlowIn)
          .catchError((error) => print(error));
    }
  }

  Future<bool> _onWillPop() async {
    _navigatePage(false);
    if (_scrollController.hasClients) {
      _scrollController
          .animateTo(0,
              duration: Duration(milliseconds: 1000 ~/ 3),
              curve: Curves.fastOutSlowIn)
          .catchError((error) => print(error));
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _countdownHasEnded = false;
    _beginCountdown();
    _updateIndex(0);
    _getUser().then((User user) async {
      if (_isLoggedIn(user)) {
        _formUser(user);
      }
      if (_countdownHasEnded) {
        _redirectUser(user);
      }
    }).catchError((error) => print(error));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: FrumWidget(
          onLifecycleChanged: _processActions,
          child: IndexedStack(
            index: _currentIndex,
            children: <Widget>[
              SplashScreen(),
              !_showMainPage()
                  ? Container()
                  : TownHall(
                      scrollController: _scrollController,
                    ),
              Login(
                  pageController: _pageController,
                  navigateToPage: _navigatePage),
            ],
          )),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }
}
