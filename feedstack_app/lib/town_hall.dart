import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:jasper/constants.dart';
import 'package:jasper/home.dart';
import 'package:jasper/human.dart';
import 'package:jasper/splash_screen.dart';
import 'banner_icon.dart';
import 'channels.dart';
import 'main_actions.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart'
    as ext;

class TownHall extends StatefulWidget {
  final ScrollController scrollController;

  TownHall({@required this.scrollController});

  @override
  _TownHallState createState() => _TownHallState();
}

class _TownHallState extends State<TownHall> {
  final DocumentReference _userRef =
      FirebaseFirestore.instance.collection('users').doc(Human.uid);
  final DocumentReference _hiddenRef =
      FirebaseFirestore.instance.collection('privateInfo').doc(Human.uid);

  String _currentChannel;
  bool _isRefreshing;

  final List<Map<String, dynamic>> _homeSnapshots =
      List<Map<String, dynamic>>();

  final List<Map<String, dynamic>> _trendingChannels =
      List<Map<String, dynamic>>();

  final Set<String> _homeIDs = Set<String>();
  bool _hasFinishedBooting;
  bool _thereIsNothingLeftInHome;
  StreamSubscription<DocumentSnapshot> _streamSubscription;
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();
  int _oldLength;

  Future<DocumentSnapshot> _getUserSnapshot() async {
    final DocumentSnapshot ds =
        await _userRef.get().catchError((error) => print(error));
    return ds;
  }

  Future<void> _getFollowingUsers() async {
    final QuerySnapshot qs = await _userRef
        .collection('following')
        .get()
        .catchError((error) => print(error));
    if (qs == null) {
      return;
    }
    final List<DocumentSnapshot> snapshots = qs.docs;
    for (int i = 0; i < snapshots.length; i++) {
      final DocumentSnapshot snapshot = snapshots[i];
      Human.following.add(snapshot.id);
    }
  }

  void _humanizeUser(DocumentSnapshot ds) {
    if (ds == null) {
      return;
    }
    final Map<String, dynamic> data = ds.data();
    final String profilePhoto = data['profilePhoto'];
    final String coverPhoto = data['coverPhoto'];
    final String username = data['username'];
    final dynamic numberOfIthReactions = ds.get('numberOfIthReactions');
    Human.numberOfIthReactions = numberOfIthReactions;
    Human.profilePhoto = profilePhoto;
    Human.coverPhoto = coverPhoto;
    Human.username = username;
  }

  Map<String, dynamic> _getChannelFromSnap(DocumentSnapshot ds) {
    final Map<String, dynamic> channel = Map<String, dynamic>();
    channel['channelID'] = ds.id;
    channel['bookmark'] = ds.get('bookmark');
    channel['description'] = ds.get('description');
    channel['name'] = ds.get('name');
    channel['photo'] = ds.get('photo');
    channel['code'] = ds.get('code');
    channel['lastUsed'] = ds.get('lastUsed');
    channel['key'] = UniqueKey();
    return channel;
  }

  Map<String, dynamic> _getPostFromSnap(DocumentSnapshot ds) {
    final Map<String, dynamic> post = Map<String, dynamic>();
    final Map<String, dynamic> data = ds.data();
    post['authorUID'] = data['authorUID'];
    post['numberOfComments'] = data['numberOfComments'];
    post['bookmark'] = data['bookmark'];
    post['caption'] = data['caption'];
    post['seen'] = data['seen'];
    post['username'] = data['username'];
    post['image'] = data['image'];
    post['coverPhoto'] = data['coverPhoto'];
    post['profilePhoto'] = data['profilePhoto'];
    post['postID'] = ds.id;
    post['key'] = UniqueKey();
    post['reactionSelected'] = data['reactionSelected'];
    return post;
  }

  void _populatePosts(QuerySnapshot qs) {
    if (qs == null) {
      return;
    }
    final List<DocumentSnapshot> snapshots = qs.docs;
    for (int i = 0; i < snapshots.length; i++) {
      final DocumentSnapshot snapshot = snapshots[i];
      if (_alreadyHasPost(snapshot) ||
          Human.hasDeleted.contains(snapshot.id) ||
          Human.hasBlocked.contains(snapshot.get('authorUID')) ||
          Human.hasBeenBlockedBy.contains(snapshot.get('authorUID'))) {
        continue;
      }
      _homeSnapshots.add(_getPostFromSnap(snapshot));
      _homeIDs.add(snapshot.id);
    }
  }

  bool _alreadyHasPost(DocumentSnapshot ds) {
    return _homeIDs.contains(ds.id);
  }

  Future<QuerySnapshot> _getPosts(int numberOfPosts) async {
    if (kDefaultChannelNames.contains(_currentChannel)) {
      CollectionReference ref;
      if (Human.hasJustCreatedAccount &&
          _currentChannel != kDefaultChannelNames[1]) {
        ref = FirebaseFirestore.instance.collection('posts');
      } else {
        ref = FirebaseFirestore.instance
            .collection('users')
            .doc(Human.uid)
            .collection('home');
      }
      if (_currentChannel == kDefaultChannelNames[1]) {
        return ref.parent
            .collection('feed')
            .orderBy('bookmark', descending: true)
            .limit(numberOfPosts)
            .get()
            .catchError((error) => print(error));
      } else {
        return ref
            .orderBy('numberOfIthReactions.0', descending: true)
            .where('numberOfIthReactions.0', isGreaterThan: 0)
            .limit(numberOfPosts)
            .get()
            .catchError((error) => print(error));
      }
    } else {
      return FirebaseFirestore.instance
          .collection('channels')
          .doc(_currentChannel)
          .collection('downloadedBy')
          .doc(Human.uid)
          .collection('posts')
          .orderBy('ranking', descending: true)
          .where('ranking', isGreaterThan: 0)
          .limit(numberOfPosts)
          .get()
          .catchError((error) => print(error));
    }
  }

  Future<void> _getRecentSearches(String collection) async {
    final List<DocumentSnapshot> humanList = collection == 'recentUserSearches'
        ? Human.recentUserSearches
        : Human.recentChannelSearches;
    final QuerySnapshot qs = await _userRef
        .collection(collection)
        .orderBy('lastSearched', descending: true)
        .get()
        .catchError((error) => print(error));
    if (qs == null) {
      return;
    }
    final List<DocumentSnapshot> snapshots = qs.docs;
    for (int i = 0; i < snapshots.length; i++) {
      final DocumentSnapshot snapshot = snapshots[i];
      humanList.add(snapshot);
    }
  }

  bool _hasBooted(int bootCount) {
    return bootCount == kHomeBootCount;
  }

  void _endBoot() {
    _hasFinishedBooting = true;
    _updateTownHall();
  }

  Future<void> _getHiddenSnap() async {
    final DocumentSnapshot snapshot =
        await _hiddenRef.get().catchError((error) => print(error));
    if (snapshot == null) {
      return null;
    }
    Human.numberOfChannels = snapshot.get('numberOfChannels');
    Human.numberOfUnreadNotifications =
        snapshot.get('numberOfUnreadNotifications');
    final int followerCount = snapshot.get('followerCount');
    final int followingCount = snapshot.get('followingCount');
    Human.followerCount = followerCount;
    Human.followingCount = followingCount;
  }

  Future<QuerySnapshot> _getSelectedQuery() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(Human.uid)
        .collection('channels')
        .where('isUsing', isEqualTo: true)
        .limit(1)
        .get()
        .catchError((error) => print(error));
  }

  void _populateChannels(QuerySnapshot qs) {
    if (qs == null) {
      return;
    }
    for (int i = 0; i < qs.docs.length; i++) {
      final DocumentSnapshot snapshot = qs.docs[i];
      if (Human.hasDownloaded.contains((snapshot.id))) {
        continue;
      }
      Human.hasDownloaded.add(snapshot.id);
      Human.myChannels.add({
        'name': snapshot.get('name'),
        'lastUsed': snapshot.get('lastUsed'),
        'channelID': snapshot.id,
        'bookmark': snapshot.get('bookmark'),
        'description': snapshot.get('description'),
        'photo': snapshot.get('photo'),
        'code': snapshot.get('code'),
        'key': UniqueKey(),
      });
    }
  }

  Future<QuerySnapshot> _getChannels() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(Human.uid)
        .collection('channels')
        .orderBy('lastUsed', descending: true)
        .get()
        .catchError((error) => print(error));
  }

  Future<QuerySnapshot> _getTrendingChannels() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(Human.uid)
        .collection('trending')
        .orderBy('lastUsed', descending: true)
        .limit(kDefaultTrendingLimit)
        .get()
        .catchError((error) => print(error));
  }

  Future<void> _loadChannels() async {
    final QuerySnapshot qs = await _getChannels();
    _populateChannels(qs);
  }

  void _bootUp() async {
    int bootCount = 0;
    _loadChannels().then((_) {
      if (_hasBooted(++bootCount)) {
        _endBoot();
      }
    });
    _getTrendingChannels().then((QuerySnapshot qs) {
      if (qs != null) {
        for (int i = 0; i < qs.docs.length; i++) {
          final DocumentSnapshot snapshot = qs.docs[i];
          _trendingChannels.add(_getChannelFromSnap(snapshot));
        }
      }
      if (_hasBooted(++bootCount)) {
        _endBoot();
      }
    });
    if (Human.hasJustCreatedAccount) {
      _getPosts(kDefaultPostLimit).then((QuerySnapshot qs) {
        _populatePosts(qs);
        if (qs != null) {
          _oldLength = qs.docs.length;
          if (qs.docs.length < kDefaultPostLimit) {
            _thereIsNothingLeftInHome = true;
          }
        }
        if (_hasBooted(++bootCount)) {
          _endBoot();
        }
      });
    } else {
      _getSelectedQuery().then((QuerySnapshot selectedQuery) {
        if (selectedQuery != null && selectedQuery.docs.isNotEmpty) {
          _currentChannel = selectedQuery.docs.first.id;
        }
        _getPosts(kDefaultPostLimit).then((QuerySnapshot qs) {
          _populatePosts(qs);
          if (qs != null) {
            _oldLength = qs.docs.length;
            if (qs.docs.length < kDefaultPostLimit) {
              _thereIsNothingLeftInHome = true;
            }
          }
          if (_hasBooted(++bootCount)) {
            _endBoot();
          }
        });
      });
    }
    _getHiddenSnap().then((_) {
      if (_hasBooted(++bootCount)) {
        _endBoot();
      }
    });
    _getUserSnapshot().then((DocumentSnapshot ds) async {
      _humanizeUser(ds);
      if (Human.hasJustCreatedAccount && ds != null) {
        Human.recentUserSearches.add(ds);
      }
      if (_hasBooted(++bootCount)) {
        _endBoot();
      }
    });
    if (Human.hasJustCreatedAccount) {
      if (_hasBooted(++bootCount)) {
        _endBoot();
      }
    } else {
      _getFollowingUsers().then((_) {
        if (_hasBooted(++bootCount)) {
          _endBoot();
        }
      });
    }
    if (Human.hasJustCreatedAccount) {
      if (_hasBooted(++bootCount)) {
        _endBoot();
      }
    } else {
      _getRecentSearches('recentUserSearches').then((_) {
        if (_hasBooted(++bootCount)) {
          _endBoot();
        }
      });
    }
    if (Human.hasJustCreatedAccount) {
      final DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('channels')
          .doc('In dogs we trust')
          .get()
          .catchError((error) => print(error));
      if (snapshot != null) {
        Human.recentChannelSearches.add(snapshot);
      }
      if (_hasBooted(++bootCount)) {
        _endBoot();
      }
    } else {
      _getRecentSearches('recentChannelSearches').then((_) {
        if (_hasBooted(++bootCount)) {
          _endBoot();
        }
      });
    }
    if (Human.hasJustCreatedAccount) {
      if (_hasBooted(++bootCount)) {
        _endBoot();
      }
      if (_hasBooted(++bootCount)) {
        _endBoot();
      }
    } else {
      _getHasBeenBlocked().then((_) {
        if (_hasBooted(++bootCount)) {
          _endBoot();
        }
      });
      _getHasBlocked().then((_) {
        if (_hasBooted(++bootCount)) {
          _endBoot();
        }
      });
    }
  }

  void _resetPostCollection() {
    _homeSnapshots.clear();
    _homeIDs.clear();
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) {
      return;
    }
    _isRefreshing = true;
    setState(() {});
    final QuerySnapshot qs = await _getPosts(kDefaultPostLimit);
    if (qs != null) {
      _resetPostCollection();
      _oldLength = qs.docs.length;
      if (qs.docs.length < kDefaultPostLimit) {
        _thereIsNothingLeftInHome = true;
      } else {
        _thereIsNothingLeftInHome = false;
      }
    }
    _populatePosts(qs);
    _isRefreshing = false;
    if (mounted) {
      setState(() {});
    }
  }

  bool _digestHasChangedSinceUpdate(
      int preLength, int postLength, String oldChannel, String newChannel) {
    return (preLength != postLength) || (oldChannel != newChannel);
  }

  Future<void> _updateHomeDigest() async {
    final int preLength = _oldLength;
    final String oldChannel = _currentChannel;
    final QuerySnapshot postQuery =
        await _getPosts(kDefaultPostLimit + preLength);
    final int postLength = _oldLength;
    final String newChannel = _currentChannel;
    if (postQuery == null ||
        _digestHasChangedSinceUpdate(
            preLength, postLength, oldChannel, newChannel)) {
      return;
    }
    if (postQuery.docs.length < kDefaultPostLimit + preLength) {
      _thereIsNothingLeftInHome = true;
    }
    _oldLength = postQuery.docs.length;
    _populatePosts(postQuery);
    _updateTownHall();
  }

  void _updateTownHall() {
    if (mounted) {
      setState(() {});
    }
  }

  void _updateCurrentChannel(String currentChannel, bool isTrending) async {
    this._currentChannel = currentChannel;
    if (isTrending) {
      final int index = _trendingChannels.indexWhere(
          (channel) => channel['channelID'] == this._currentChannel);
      if (index != -1) {
        _trendingChannels[index]['lastUsed'] =
            DateTime.now().millisecondsSinceEpoch;
      }
      final HttpsCallable selectTrending = CloudFunctions.instance
          .getHttpsCallable(functionName: 'selectTrending');
      selectTrending.call({
        'uid': Human.uid,
        'channelID': this._currentChannel,
      }).catchError((error) => print(error));
    } else {
      final int index = Human.myChannels.indexWhere(
          (channel) => channel['channelID'] == this._currentChannel);
      if (index != -1) {
        Human.myChannels[index]['lastUsed'] =
            DateTime.now().millisecondsSinceEpoch;
      }
      final HttpsCallable selectChannel = CloudFunctions.instance
          .getHttpsCallable(functionName: 'selectChannel');
      selectChannel.call({
        'uid': Human.uid,
        'channelID': this._currentChannel,
      }).catchError((error) => print(error));
    }
    _updateTownHall();
    _refreshKey.currentState.show().catchError((error) => print(error));
  }

  void _listenToHiddenSnap() {
    _streamSubscription = FirebaseFirestore.instance
        .collection('privateInfo')
        .doc(Human.uid)
        .snapshots()
        .listen((event) {
      if (event != null && event.exists) {
        Human.numberOfUnreadNotifications =
            event.get('numberOfUnreadNotifications');
      }
    });
  }

  Future<void> _getHasBlocked() async {
    final QuerySnapshot qs = await FirebaseFirestore.instance
        .collection('users')
        .doc(Human.uid)
        .collection('hasBlocked')
        .get()
        .catchError((error) => print(error));
    if (qs != null) {
      for (int i = 0; i < qs.docs.length; i++) {
        Human.hasBlocked.add(qs.docs[i].id);
        _homeSnapshots
            .removeWhere((element) => element['authorUID'] == qs.docs[i].id);
      }
    }
  }

  Future<void> _getHasBeenBlocked() async {
    final QuerySnapshot qs = await FirebaseFirestore.instance
        .collection('users')
        .doc(Human.uid)
        .collection('hasBeenBlockedBy')
        .get()
        .catchError((error) => print(error));
    if (qs != null) {
      for (int i = 0; i < qs.docs.length; i++) {
        Human.hasBeenBlockedBy.add(qs.docs[i].id);
        _homeSnapshots
            .removeWhere((element) => element['authorUID'] == qs.docs[i].id);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _oldLength = 0;
    _currentChannel = kDefaultChannelNames[0];
    _thereIsNothingLeftInHome = false;
    _isRefreshing = false;
    _hasFinishedBooting = false;
    _bootUp();
    _listenToHiddenSnap();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          notificationPredicate: (_) => false,
          key: _refreshKey,
          backgroundColor: Color(kDefaultBackgroundColor),
          onRefresh: _onRefresh,
          color: Colors.blueAccent,
          child: ext.NestedScrollViewRefreshIndicator(
              backgroundColor: Color(kDefaultBackgroundColor),
              notificationPredicate: (ScrollNotification n) {
                if (_isRefreshing) {
                  return false;
                }
                return true;
              },
              onRefresh: _onRefresh,
              color: Colors.blueAccent,
              child: ext.NestedScrollView(
                  headerSliverBuilder:
                      (BuildContext context, bool innerBoxIsScrolled) {
                    return [
                      SliverAppBar(
                        automaticallyImplyLeading: false,
                        backgroundColor: Colors.blueAccent,
                        forceElevated: true,
                        pinned: true,
                        floating: true,
                        titleSpacing: 0.0,
                        bottom: AppBar(
                            automaticallyImplyLeading: false,
                            titleSpacing: 0.0,
                            backgroundColor: Colors.transparent,
                            elevation: 0.0,
                            title: Stack(children: <Widget>[
                              SizedBox(
                                height: 500.0,
                                child: Channels(
                                  trendingChannels: _trendingChannels,
                                  refreshParent: _updateTownHall,
                                  currentChannel: _currentChannel,
                                  updateCurrentChannel: _updateCurrentChannel,
                                  scrollController: widget.scrollController,
                                ),
                              ),
                              !_isRefreshing
                                  ? Container()
                                  : Positioned.fill(
                                      child: Material(
                                      color: Colors.transparent,
                                    ))
                            ])),
                        title: MainActions(
                          updateTownHall: _updateTownHall,
                          scrollController: widget.scrollController,
                        ),
                      )
                    ];
                  },
                  body: Material(
                      color: Color(kDefaultBackgroundColor),
                      child: Stack(
                        children: [
                          Home(
                            isRefreshing: _isRefreshing,
                            thereIsNothingLeftInHome: _thereIsNothingLeftInHome,
                            redigest: _updateHomeDigest,
                            postSnapshots: _homeSnapshots,
                            updateTownHall: _updateTownHall,
                          ),
                          _homeSnapshots.isNotEmpty
                              ? Container()
                              : Material(
                                  color: Colors.white,
                                  child: Center(
                                    child: BannerIcon(
                                      msg: 'Feed is empty',
                                      emoticon: '๏_๏',
                                    ),
                                  ),
                                ),
                        ],
                      )))),
        ),
        _hasFinishedBooting ? Container() : SplashScreen(),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
    _streamSubscription?.cancel();
  }
}
