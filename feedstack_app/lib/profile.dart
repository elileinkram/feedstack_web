import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:jasper/banner_icon.dart';
import 'package:jasper/perspective_panel.dart';
import 'package:jasper/post.dart';
import 'package:jasper/profile_bar.dart';
import 'package:jasper/user_head.dart';
import 'package:jasper/user_posts.dart';
import 'package:jasper/waiting_widget.dart';
import 'constants.dart';
import 'human.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart'
    as ext;

class Profile extends StatefulWidget {
  final String profilePhoto;
  final String coverPhoto;
  final String username;
  final String uid;
  final String heroTag;
  final dynamic numberOfIthReactions;
  final bool comesWithUserSnap;
  final int initialIndex;
  final int reactionSelected;
  final String targetReaction;
  final Map<String, dynamic> newPost;

  Profile(
      {@required this.profilePhoto,
      @required this.coverPhoto,
      this.newPost,
      @required this.username,
      @required this.uid,
      this.heroTag,
      this.numberOfIthReactions,
      @required this.comesWithUserSnap,
      @required this.initialIndex,
      @required this.reactionSelected,
      this.targetReaction});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with SingleTickerProviderStateMixin {
  final Map<String, bool> _thereIsNothingLeftIn = Map<String, bool>()
    ..addAll(
        {kDefaultProfileTabs.first: false, kDefaultProfileTabs.last: false});

  String _profilePhoto;
  String _coverPhoto;
  String _username;
  final double _reactionPanelHeight = 36.0 * (1 + 1 / 3);
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  final Map<String, int> _preLengths = {
    kDefaultProfileTabs.first: 0,
    kDefaultProfileTabs.last: 0
  };

  TabController _tabController;
  bool _isRefreshing;
  int _reactionSelected;
  dynamic _numberOfIthReactions;
  final List<Map<String, dynamic>> _uploads = List<Map<String, dynamic>>();

  final List<Map<String, dynamic>> _postSnapshots =
      List<Map<String, dynamic>>();
  final List<Map<String, dynamic>> _reactionSnapshots =
      List<Map<String, dynamic>>();
  final Set<String> _postIDs = Set<String>();
  final Set<String> _reactionIDs = Set<String>();

  bool get _isClient {
    return Human.uid == widget.uid;
  }

  List<Widget> get _tabs {
    return [
      Tab(icon: null, text: 'Posts'),
      Tab(icon: null, text: 'Emojis'),
    ];
  }

  void _onBack() {
    Navigator.of(context).pop();
  }

  File get _fProfilePhoto {
    if (_isClient) {
      return Human.fProfilePhoto;
    }
    return null;
  }

  File get _fCoverPhoto {
    if (_isClient) {
      return Human.fCoverPhoto;
    }
    return null;
  }

  Map<String, dynamic> _getPostFromSnap(DocumentSnapshot ds, String tabLabel) {
    final Map<String, dynamic> post = Map<String, dynamic>();
    final Map<String, dynamic> data = ds.data();
    post['seen'] = data['seen'];
    post['reactionSelected'] = data['reactionSelected'];
    post['numberOfComments'] = data['numberOfComments'];
    post['authorUID'] = data['authorUID'];
    post['coverPhoto'] = data['coverPhoto'];
    post['bookmark'] = data['bookmark'];
    post['caption'] = data['caption'];
    post['username'] = data['username'];
    post['image'] = data['image'];
    if (tabLabel == kDefaultProfileTabs.last) {
      post['reactionTime'] =
          data['reactionTime'] ?? DateTime.now().millisecondsSinceEpoch;
    }
    post['profilePhoto'] = data['profilePhoto'];
    post['postID'] = ds.id;
    post['key'] = UniqueKey();
    return post;
  }

  bool _alreadyHasPost(Set set, DocumentSnapshot ds) {
    return set.contains(ds.id);
  }

  void _populatePosts(
    List<Map<String, dynamic>> list,
    Set<String> set,
    QuerySnapshot qs,
    String label,
  ) {
    if (qs == null) {
      return null;
    }
    _preLengths[label] = qs.docs.length;
    final List<DocumentSnapshot> snapshots = qs.docs;
    if (snapshots.length < kDefaultPostLimit) {
      if (_thereIsNothingLeftIn[label] == false) {
        _thereIsNothingLeftIn[label] = true;
        if (mounted) {
          setState(() {});
        }
      }
    } else {
      if (_thereIsNothingLeftIn[label] == true) {
        _thereIsNothingLeftIn[label] = false;
        if (mounted) {
          setState(() {});
        }
      }
    }
    for (int i = 0; i < snapshots.length; i++) {
      final DocumentSnapshot snapshot = snapshots[i];
      if (_alreadyHasPost(set, snapshot) || _shouldPass(snapshot, label)) {
        continue;
      }
      final String postID = snapshot.id;
      list.add(_getPostFromSnap(snapshot, label));
      set.add(postID);
    }
  }

  bool _shouldPass(DocumentSnapshot snapshot, String label) {
    if (Human.hasDeleted.contains(snapshot.id)) {
      return true;
    }
    if (Human.hasBeenBlockedBy.contains(snapshot.get('authorUID'))) {
      return true;
    }
    if (Human.hasBlocked.contains(snapshot.get('authorUID')) &&
        (widget.uid != snapshot.get('authorUID') ||
            label == kDefaultProfileTabs.last)) {
      return true;
    }
    return false;
  }

  Future<QuerySnapshot> _getPosts(
      int numberOfPosts, String label, List<Map<String, dynamic>> posts) async {
    final String orderBy =
        label == kDefaultProfileTabs.first ? 'bookmark' : 'reactionTime';
    final int isLessThan = posts.isEmpty
        ? DateTime.now().millisecondsSinceEpoch
        : posts.last[orderBy];
    if (label == kDefaultProfileTabs.last) {
      final int reactionSelected = _getActionSelected();
      if (reactionSelected >= 0 && reactionSelected <= 2) {
        _reactionSelected = reactionSelected;
        return FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .collection('reactions')
            .orderBy(orderBy, descending: true)
            .where(orderBy, isLessThan: isLessThan)
            .where('reactionSelected', isEqualTo: _reactionSelected)
            .limit(kDefaultPostLimit)
            .get()
            .catchError((error) => print(error));
      }
      return null;
    } else {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(Human.uid)
          .collection('home')
          .where('authorUID', isEqualTo: widget.uid)
          .where(orderBy, isLessThan: isLessThan)
          .orderBy(orderBy, descending: true)
          .limit(kDefaultPostLimit)
          .get();
    }
  }

  bool get _shouldLoadTargetReaction {
    return widget.targetReaction != null;
  }

  bool _hasBooted(int bootCount) {
    int maxBootCount =
        _shouldLoadUserSnapshot ? kProfileBootCount : kProfileBootCount - 1;
    if (_shouldLoadTargetReaction) {
      maxBootCount = maxBootCount + 1;
    }
    return bootCount == maxBootCount;
  }

  void _endBoot() {
    _hasFinishedBooting = true;
    if (mounted) {
      setState(() {});
    }
  }

  bool _hasFinishedBooting;

  Future<DocumentSnapshot> _getUserSnapshot() async {
    final DocumentSnapshot ds = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .get()
        .catchError((error) => print(error));
    return ds;
  }

  bool get _shouldLoadUserSnapshot {
    return !widget.comesWithUserSnap && !_isClient;
  }

  void _unpackUser(DocumentSnapshot ds) {
    if (ds == null) {
      return;
    }
    final Map<String, dynamic> data = ds.data();
    _profilePhoto = data['profilePhoto'];
    _coverPhoto = data['coverPhoto'];
    _username = data['username'];
    _numberOfIthReactions = data['numberOfIthReactions'];
  }

  void _unpackTargetReaction(DocumentSnapshot ds) {
    if (ds == null) {
      return;
    }
    if (_numberOfIthReactions[widget.reactionSelected.toString()] == 0) {
      _numberOfIthReactions[widget.reactionSelected.toString()] = 1;
    }
    _getListFromLabel(kDefaultProfileTabs.last)
        .add(_getPostFromSnap(ds, kDefaultProfileTabs.last));
    _getSetFromLabel(kDefaultProfileTabs.last).add(ds.id);
  }

  List<Map<String, dynamic>> _getListFromLabel(String label) {
    if (label == kDefaultProfileTabs.first) {
      return _postSnapshots;
    }
    return _reactionSnapshots;
  }

  Set<String> _getSetFromLabel(String label) {
    if (label == kDefaultProfileTabs.first) {
      return _postIDs;
    }
    return _reactionIDs;
  }

  Future<DocumentSnapshot> _getTargetReaction() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(Human.uid)
        .collection('home')
        .doc(widget.targetReaction)
        .get()
        .catchError((error) => print(error));
  }

  void _bootUp() async {
    int bootCount = 0;
    _getPosts(kDefaultPostLimit, kDefaultProfileTabs.first,
            _getListFromLabel(kDefaultProfileTabs.first))
        .then((QuerySnapshot qs) async {
      _populatePosts(
          _getListFromLabel(kDefaultProfileTabs.first),
          _getSetFromLabel(kDefaultProfileTabs.first),
          qs,
          kDefaultProfileTabs.first);
      if (_hasBooted(++bootCount)) {
        _endBoot();
      }
    });
    if (_shouldLoadUserSnapshot) {
      final DocumentSnapshot ds = await _getUserSnapshot();
      _unpackUser(ds);
      ++bootCount;
    }
    if (_shouldLoadTargetReaction) {
      final DocumentSnapshot ds = await _getTargetReaction();
      _unpackTargetReaction(ds);
      ++bootCount;
    }
    _getPosts(kDefaultPostLimit, kDefaultProfileTabs.last,
            _getListFromLabel(kDefaultProfileTabs.last))
        .then((QuerySnapshot qs) async {
      _populatePosts(
        _getListFromLabel(kDefaultProfileTabs.last),
        _getSetFromLabel(kDefaultProfileTabs.last),
        qs,
        kDefaultProfileTabs.last,
      );
      if (_hasBooted(++bootCount)) {
        _endBoot();
      }
    });
  }

  bool _hasPosts() {
    if (!_hasFinishedBooting || _uploads.isNotEmpty) {
      return true;
    }
    return _getListFromLabel(kDefaultProfileTabs.first).isNotEmpty;
  }

  bool _hasReactions() {
    if (!_hasFinishedBooting) {
      return true;
    }
    final List<String> emojiList = _getEmojiList();
    for (int i = 0; i < emojiList.length; i++) {
      if (emojiList[i] != null) {
        return true;
      }
    }
    return false;
  }

  bool _digestHasChangedSinceUpdate(int preLength, int postLength) {
    return preLength != postLength;
  }

  Future<void> _redigest(String label) async {
    final int preLength = _preLengths[label];
    final QuerySnapshot postQuery =
        await _getPosts(kDefaultPostLimit, label, _getListFromLabel(label))
            .catchError((error) => print(error));
    final int postLength = _preLengths[label];
    if (postQuery == null ||
        _digestHasChangedSinceUpdate(preLength, postLength)) {
      return;
    }
    _populatePosts(
        _getListFromLabel(label), _getSetFromLabel(label), postQuery, label);
  }

  void _onActionChanged(int index) {
    _reactionSelected = index;
    if (mounted) {
      setState(() {});
      _refreshKey.currentState.show().catchError((error) => print(error));
    }
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) {
      return null;
    }
    _isRefreshing = true;
    setState(() {});
    DocumentSnapshot ds;
    if (!_isClient) {
      ds = await _getUserSnapshot();
    }
    final QuerySnapshot qs1 =
        await _getPosts(kDefaultPostLimit, kDefaultProfileTabs.first, []);
    final QuerySnapshot qs2 =
        await _getPosts(kDefaultPostLimit, kDefaultProfileTabs.last, []);
    if (qs1 != null) {
      _uploads.clear();
      _getListFromLabel(kDefaultProfileTabs.first).clear();
      _getSetFromLabel(kDefaultProfileTabs.first).clear();
    }
    if (qs2 != null) {
      _getListFromLabel(kDefaultProfileTabs.last).clear();
      _getSetFromLabel(kDefaultProfileTabs.last).clear();
    }
    _populatePosts(
        _getListFromLabel(kDefaultProfileTabs.first),
        _getSetFromLabel(kDefaultProfileTabs.first),
        qs1,
        kDefaultProfileTabs.first);
    _populatePosts(
      _getListFromLabel(kDefaultProfileTabs.last),
      _getSetFromLabel(kDefaultProfileTabs.last),
      qs2,
      kDefaultProfileTabs.last,
    );
    _unpackUser(ds);
    _isRefreshing = false;
    if (mounted) {
      setState(() {});
    }
  }

  void _refreshProfile() {
    if (mounted) {
      setState(() {});
    }
  }

  void _tabListener() {
    if (_tabController.previousIndex != _tabController.index) {
      _refreshProfile();
    }
  }

  List<String> _getEmojiList() {
    final List<String> emojiList = List<String>();
    for (int i = 0; i < _numberOfIthReactions.length; i++) {
      if (_numberOfIthReactions[i.toString()] > 0) {
        emojiList.add(kEmojis[i]);
      } else {
        emojiList.add(null);
      }
    }
    return emojiList;
  }

  Future<void> _onMicroRefresh() async {
    if (_isRefreshing) {
      return;
    }
    _isRefreshing = true;
    setState(() {});
    final QuerySnapshot qs2 =
        await _getPosts(kDefaultPostLimit, kDefaultProfileTabs.last, []);
    if (qs2 != null) {
      _getListFromLabel(kDefaultProfileTabs.last).clear();
      _getSetFromLabel(kDefaultProfileTabs.last).clear();
    }
    _populatePosts(
      _getListFromLabel(kDefaultProfileTabs.last),
      _getSetFromLabel(kDefaultProfileTabs.last),
      qs2,
      kDefaultProfileTabs.last,
    );
    _isRefreshing = false;
    if (mounted) {
      setState(() {});
    }
  }

  int _getActionSelected() {
    final List<String> emojiList = _getEmojiList();
    final String emoji = kEmojis[_reactionSelected];
    if (emojiList.contains(emoji)) {
      return _reactionSelected;
    } else {
      int i = 0;
      for (i = 0; i < emojiList.length; i++) {
        if (emojiList[i] != null) {
          break;
        }
      }
      if (i == emojiList.length) {
        return -1;
      } else {
        if (_hasFinishedBooting && _isOnPage(1)) {
          if (_isRefreshing || _reactionSelected == i) {
          } else {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (_isRefreshing || _reactionSelected == i) {
              } else {
                _onActionChanged(i);
              }
            });
          }
        }
      }
      return i;
    }
  }

  bool _isOnPage(int index) {
    return _tabController.index == index;
  }

  @override
  void initState() {
    super.initState();
    if (widget.newPost != null) {
      _uploads.add({
        'postID': widget.newPost['postID'],
        'seen': false,
        'numberOfComments': 0
      });
    }
    _isRefreshing = false;
    if (_isClient) {
      _numberOfIthReactions = Human.numberOfIthReactions;
    } else {
      _numberOfIthReactions = widget.numberOfIthReactions;
    }
    _profilePhoto = widget.profilePhoto;
    _coverPhoto = widget.coverPhoto;
    _username = widget.username;
    _hasFinishedBooting = false;
    _tabController = TabController(
        length: _tabs.length, vsync: this, initialIndex: widget.initialIndex);
    _tabController.addListener(_tabListener);
    _reactionSelected = widget.reactionSelected;
    _bootUp();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.blueAccent,
        child: WillPopScope(
          onWillPop: () async {
            if (_tabController.index != 0 || _tabController.indexIsChanging) {
              _tabController.animateTo(0,
                  duration: Duration(milliseconds: 1000 ~/ 3));
              return false;
            } else {
              return true;
            }
          },
          child: Material(
            color: Color(kDefaultBackgroundColor),
            child: RefreshIndicator(
              backgroundColor: Color(kDefaultBackgroundColor),
              color: Colors.blueAccent,
              key: _refreshKey,
              onRefresh: _onMicroRefresh,
              notificationPredicate: (_) => false,
              child: ext.NestedScrollViewRefreshIndicator(
                backgroundColor: Color(kDefaultBackgroundColor),
                onRefresh: _onRefresh,
                notificationPredicate: (ScrollNotification n) {
                  if (_isRefreshing) {
                    return false;
                  }
                  return true;
                },
                color: Colors.blueAccent,
                child: ext.NestedScrollView(
                    headerSliverBuilder:
                        (BuildContext context, bool innerBoxIsScrolled) {
                      return <Widget>[
                        SliverAppBar(
                          automaticallyImplyLeading: false,
                          backgroundColor: Colors.blueAccent,
                          floating: false,
                          pinned: true,
                          titleSpacing: 0.0,
                          title: ProfileBar(
                              refreshProfile: _refreshProfile,
                              expandedHeight:
                                  MediaQuery.of(context).size.height * 0.4215,
                              uid: widget.uid,
                              username: _isClient ? Human.username : _username,
                              isClient: _isClient),
                          flexibleSpace: FlexibleSpaceBar(
                            background: UserHead(
                              heroTag: widget.heroTag,
                              fCoverPhoto: _fCoverPhoto,
                              fProfilePhoto: _fProfilePhoto,
                              onBack: _onBack,
                              expandedHeight:
                                  MediaQuery.of(context).size.height * 0.4215,
                              profilePhoto: _isClient
                                  ? Human.profilePhoto
                                  : _profilePhoto,
                              coverPhoto:
                                  _isClient ? Human.coverPhoto : _coverPhoto,
                            ),
                          ),
                          expandedHeight:
                              MediaQuery.of(context).size.height * 0.4215,
                          bottom: TabBar(
                            controller: _tabController,
                            indicatorColor: Colors.blueGrey[50],
                            tabs: _tabs,
                          ),
                        ),
                      ];
                    },
                    body: Stack(
                      children: [
                        TabBarView(
                          controller: _tabController,
                          children: [
                            Stack(
                              children: [
                                UserPosts(
                                    showReactionPanel: true,
                                    inBetweeners: widget.newPost != null &&
                                            !Human.hasDeleted.contains(
                                                widget.newPost['postID']) &&
                                            _uploads.isNotEmpty
                                        ? Padding(
                                            key: widget.newPost['key'],
                                            padding: EdgeInsets.only(
                                                top: kPanelPadding,
                                                left: kPanelPadding,
                                                right: kPanelPadding),
                                            child: Hero(
                                              tag: widget.newPost['key']
                                                  .toString(),
                                              child: Post(
                                                showReactionPanel: true,
                                                isUpload: true,
                                                loadMorePosts: () async => null,
                                                shouldLoadMorePosts: () =>
                                                    false,
                                                index: 0,
                                                snapshots: _postSnapshots,
                                                uploads: _uploads,
                                                isInsideComments: false,
                                                heroTag: widget.newPost['key']
                                                    .toString(),
                                                refreshParent: _refreshProfile,
                                                coverPhoto: Human.coverPhoto,
                                                reactionSelected:
                                                    kNullActionValue,
                                                postID:
                                                    widget.newPost['postID'],
                                                elevation: 0.0,
                                                caption:
                                                    widget.newPost['caption'],
                                                bookmark:
                                                    widget.newPost['bookmark'],
                                                image: widget.newPost['image'],
                                                profilePhoto:
                                                    Human.profilePhoto,
                                                radius: kPanelPadding,
                                                authorUID: Human.uid,
                                                username: Human.username,
                                              ),
                                            ),
                                          )
                                        : Container(),
                                    isRefreshing: _isRefreshing,
                                    refreshProfile: _refreshProfile,
                                    index: 0,
                                    thereIsNothingLeft: _thereIsNothingLeftIn[
                                        kDefaultProfileTabs.first],
                                    tabLabel: kDefaultProfileTabs.first,
                                    redigest: _redigest,
                                    tabController: _tabController,
                                    postSnapshots: _postSnapshots),
                                _hasPosts()
                                    ? Container()
                                    : Material(
                                        color: Colors.white,
                                        child: Center(
                                          child: BannerIcon(
                                            msg: 'No posts to show',
                                            emoticon: '¯\\_(ツ)_/¯',
                                          ),
                                        ),
                                      ),
                                !Human.hasBeenBlockedBy.contains(widget.uid)
                                    ? Container()
                                    : Material(
                                        color: Colors.white,
                                        child: Center(
                                          child: BannerIcon(
                                            msg: 'This user has blocked you',
                                            emoticon: '(︶ω︶)',
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                            Stack(
                              children: [
                                UserPosts(
                                    showReactionPanel: false,
                                    isRefreshing: _isRefreshing,
                                    inBetweeners: Stack(
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(
                                              left: kPanelPadding,
                                              right: kPanelPadding,
                                              top: kPanelPadding),
                                          child: !_hasFinishedBooting
                                              ? Container()
                                              : PerspectivePanel(
                                                  username: widget.username,
                                                  emojis: _getEmojiList(),
                                                  unselectedOpacity: 1 / 6,
                                                  panelHeight:
                                                      _reactionPanelHeight,
                                                  fontSize:
                                                      _reactionPanelHeight *
                                                          0.45,
                                                  backgroundColor:
                                                      Colors.blueGrey[50],
                                                  elevation: 0,
                                                  radius: kPanelPadding / 2,
                                                  onActionChanged:
                                                      _onActionChanged,
                                                  reactionSelected:
                                                      _getActionSelected(),
                                                ),
                                        ),
                                        Positioned.fill(
                                            child: !_isRefreshing
                                                ? Container()
                                                : Material(
                                                    color: Colors.transparent,
                                                  ))
                                      ],
                                    ),
                                    refreshProfile: _refreshProfile,
                                    index: 1,
                                    thereIsNothingLeft: _thereIsNothingLeftIn[
                                        kDefaultProfileTabs.last],
                                    tabLabel: kDefaultProfileTabs.last,
                                    redigest: _redigest,
                                    tabController: _tabController,
                                    postSnapshots: _reactionSnapshots),
                                _hasReactions()
                                    ? Container()
                                    : Material(
                                        color: Colors.white,
                                        child: Center(
                                          child: BannerIcon(
                                            msg: 'No posts to show',
                                            emoticon: '¯\\_(ツ)_/¯',
                                          ),
                                        ),
                                      ),
                                !Human.hasBeenBlockedBy.contains(widget.uid)
                                    ? Container()
                                    : Material(
                                        color: Colors.white,
                                        child: Center(
                                          child: BannerIcon(
                                            msg: 'This user has blocked you',
                                            emoticon: '(︶ω︶)',
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                          ],
                        ),
                        _hasFinishedBooting
                            ? Container()
                            : Positioned.fill(
                                child: Material(
                                  color: Color(kDefaultBackgroundColor),
                                  child: Material(
                                    color: Colors.white,
                                    child: Center(
                                        child: WaitingWidget(
                                      isLoading: true,
                                      color: Colors.blueAccent,
                                    )),
                                  ),
                                ),
                              ),
                      ],
                    )),
              ),
            ),
          ),
        ));
  }

  @override
  void dispose() {
    super.dispose();
    _tabController?.dispose();
  }
}
