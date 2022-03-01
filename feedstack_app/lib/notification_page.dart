import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jasper/constants.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart'
    as ext;
import 'package:jasper/human.dart';
import 'package:jasper/waiting_widget.dart';
import 'banner_icon.dart';
import 'notification_list.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with SingleTickerProviderStateMixin {
  void _onBack() {
    Navigator.of(context).pop();
  }

  final List<Map<String, dynamic>> _unreadSnapshots =
      List<Map<String, dynamic>>();
  final List<Map<String, dynamic>> _readSnapshots =
      List<Map<String, dynamic>>();
  final Set<String> _unreadIDs = Set<String>();
  final Set<String> _readIDs = Set<String>();
  bool _nothingLeftInUnread;
  bool _nothingLeftInRead;
  bool _hasFinishedBooting;

  TabController _tabController;

  final Map<String, int> _preLengths = {'unread': 0, 'read': 0};

  final List<String> _tabs = ['Unread', 'Read'];

  void _resetCollection(String label) {
    _getListFromLabel(label).clear();
    _getSetFromLabel(label).clear();
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) {
      return;
    }
    _isRefreshing = true;
    if (mounted) {
      setState(() {});
    }
    final QuerySnapshot qs1 = await _getNotifications(
        _tabs.first.toLowerCase(), kDefaultNotificationLimit);
    final QuerySnapshot qs2 = await _getNotifications(
        _tabs.last.toLowerCase(), kDefaultNotificationLimit);
    if (qs1 != null) {
      _resetCollection(_tabs.first.toLowerCase());
      if (qs1.docs.length < kDefaultNotificationLimit) {
        _nothingLeftInUnread = true;
      } else {
        _nothingLeftInUnread = false;
      }
    }
    if (qs2 != null) {
      _resetCollection(_tabs.last.toLowerCase());
      if (qs2.docs.length < kDefaultNotificationLimit) {
        _nothingLeftInRead = true;
      } else {
        _nothingLeftInRead = false;
      }
    }
    _populateNotifications(qs1, _tabs.first.toLowerCase());
    _populateNotifications(qs2, _tabs.last.toLowerCase());
    _isRefreshing = false;
    if (mounted) {
      setState(() {});
    }
  }

  List<Map<String, dynamic>> _getListFromLabel(String label) {
    if (label == _tabs.first.toLowerCase()) {
      return _unreadSnapshots;
    }
    return _readSnapshots;
  }

  Set<String> _getSetFromLabel(String label) {
    if (label == _tabs.first.toLowerCase()) {
      return _unreadIDs;
    }
    return _readIDs;
  }

  bool _alreadyHasPost(DocumentSnapshot snapshot, String label) {
    return _getSetFromLabel(label).contains(snapshot.id);
  }

  void _populateNotifications(QuerySnapshot qs, String label) {
    if (qs == null) {
      return;
    }
    _preLengths[label] = qs.docs.length;
    final List<DocumentSnapshot> snapshots = qs.docs;
    for (int i = 0; i < snapshots.length; i++) {
      final DocumentSnapshot snapshot = snapshots[i];
      if (_alreadyHasPost(snapshot, label) ||
          Human.hasBlocked.contains(snapshot.id.split(' ')[0])) {
        continue;
      }
      _getListFromLabel(label).add(_getNotificationFromSnap(snapshot, label));
      _getSetFromLabel(label).add(snapshot.id);
    }
  }

  Map<String, dynamic> _getNotificationFromSnap(
      DocumentSnapshot ds, String tabLabel) {
    final Map<String, dynamic> notification = Map<String, dynamic>();
    final Map<String, dynamic> data = ds.data();
    notification['reactionSelected'] = data['reactionSelected'];
    notification['bookmark'] = data['bookmark'];
    notification['isReaction'] = notification['reactionSelected'] != null;
    notification['notificationID'] = ds.id;
    notification['uid'] = ds.id.split(' ')[0];
    if (notification['isReaction']) {
      notification['postID'] = ds.id.split(' ')[1];
    }
    notification['seen'] = data['seen'];
    notification['username'] = data['username'];
    notification['coverPhoto'] = data['coverPhoto'];
    notification['profilePhoto'] = data['profilePhoto'];
    notification['key'] = UniqueKey();
    return notification;
  }

  bool _isRefreshing;

  Future<bool> _onWillPop() async {
    if (_tabController.index == 1 || _tabController.indexIsChanging) {
      _tabController.animateTo(0, duration: Duration(milliseconds: 1000 ~/ 3));
      return false;
    }
    return true;
  }

  Future<QuerySnapshot> _getNotifications(String label, int limit) {
    final List<Map<String, dynamic>> notifications = _getListFromLabel(label);
    Query qs = FirebaseFirestore.instance
        .collection('users')
        .doc(Human.uid)
        .collection('notifications')
        .orderBy('bookmark', descending: true)
        .where('bookmark',
            isLessThan: notifications.isEmpty || _isRefreshing
                ? DateTime.now().millisecondsSinceEpoch
                : notifications.last['bookmark'])
        .limit(limit);
    if (label == _tabs.first.toLowerCase()) {
      qs = qs.where('seen', isEqualTo: false);
    } else {
      qs = qs.where('seen', isEqualTo: true);
    }
    return qs.get().catchError((error) => print(error));
  }

  void _endBoot() {
    _hasFinishedBooting = true;
    if (mounted) {
      setState(() {});
    }
  }

  bool _hasChangedSinceUpdate(int preLength, int postLength) {
    return preLength != postLength;
  }

  Future<void> _loadMoreNotifications(String label) async {
    final int preLength = _preLengths[label];
    final QuerySnapshot qs =
        await _getNotifications(label, kDefaultNotificationLimit);
    final int postLength = _preLengths[label];
    if (qs == null || _hasChangedSinceUpdate(preLength, postLength)) {
      return;
    }
    if (qs.docs.length < kDefaultNotificationLimit) {
      if (label == _tabs.first.toLowerCase()) {
        _nothingLeftInUnread = true;
      } else {
        _nothingLeftInRead = true;
      }
    }
    _populateNotifications(qs, label);
    if (mounted) {
      setState(() {});
    }
  }

  void _bootUp() {
    int bootCount = 0;
    _getNotifications(_tabs.first.toLowerCase(), kDefaultNotificationLimit)
        .then((QuerySnapshot qs) {
      _populateNotifications(qs, _tabs.first.toLowerCase());
      if (_hasBooted(++bootCount)) {
        _endBoot();
      }
      if (qs != null) {
        if (qs.docs.length < kDefaultNotificationLimit) {
          _nothingLeftInUnread = true;
        }
      }
    });
    _getNotifications(_tabs.last.toLowerCase(), kDefaultNotificationLimit)
        .then((QuerySnapshot qs) {
      _populateNotifications(qs, _tabs.last.toLowerCase());
      if (_hasBooted(++bootCount)) {
        _endBoot();
      }
      if (qs != null) {
        if (qs.docs.length < kDefaultNotificationLimit) {
          _nothingLeftInRead = true;
        }
      }
    });
  }

  bool _hasBooted(int bootCount) {
    return bootCount == kNotificationBootCount;
  }

  bool _hasNotifications(String label) {
    return _getListFromLabel(label).isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _isRefreshing = false;
    _tabController = TabController(vsync: this, length: _tabs.length);
    _nothingLeftInUnread = false;
    _nothingLeftInRead = false;
    _hasFinishedBooting = false;
    _bootUp();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
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
                  elevation: 0.0,
                  automaticallyImplyLeading: false,
                  backgroundColor: Colors.blueAccent,
                  forceElevated: innerBoxIsScrolled,
                  pinned: true,
                  floating: true,
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
                        'Notifications',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: kTitleFontSize),
                      )
                    ],
                  ),
                  bottom: TabBar(
                    controller: _tabController,
                    tabs: List<Widget>.generate(_tabs.length, (int index) {
                      return Tab(
                        text: _tabs[index],
                      );
                    }),
                    indicatorColor: Colors.blueGrey[50],
                  ),
                )
              ];
            },
            body: Stack(
              children: [
                Material(
                  color: Color(kDefaultBackgroundColor),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      Stack(
                        children: [
                          NotificationList(
                            isRefreshing: _isRefreshing,
                            nothingLeftInside: _nothingLeftInUnread,
                            tabLabel: _tabs.first.toLowerCase(),
                            snapshots: _unreadSnapshots,
                            updateList: _loadMoreNotifications,
                          ),
                          _hasNotifications(_tabs.first.toLowerCase())
                              ? Container()
                              : Material(
                                  color: Colors.white,
                                  child: Center(
                                    child: BannerIcon(
                                      msg: 'No new notifications to see',
                                      emoticon: '(▀̿̿Ĺ̯̿▀̿ ̿)',
                                    ),
                                  ),
                                )
                        ],
                      ),
                      Stack(
                        children: [
                          NotificationList(
                            isRefreshing: _isRefreshing,
                            nothingLeftInside: _nothingLeftInRead,
                            tabLabel: _tabs.last.toLowerCase(),
                            snapshots: _readSnapshots,
                            updateList: _loadMoreNotifications,
                          ),
                          _hasNotifications(_tabs.last.toLowerCase())
                              ? Container()
                              : Material(
                                  color: Colors.white,
                                  child: Center(
                                    child: BannerIcon(
                                      msg: 'No other notifications to see',
                                      emoticon: '(▀̿̿Ĺ̯̿▀̿ ̿)',
                                    ),
                                  ),
                                )
                        ],
                      )
                    ],
                  ),
                ),
                _hasFinishedBooting
                    ? Container()
                    : Positioned.fill(
                        child: Material(
                          color: Colors.white,
                          child: Center(
                              child: WaitingWidget(
                            isLoading: true,
                            color: Colors.blueAccent,
                          )),
                        ),
                      ),
              ],
            )),
      ),
    );
  }
}
