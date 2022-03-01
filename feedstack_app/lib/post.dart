import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:hashtagable/widgets/hashtag_text.dart';
import 'package:jasper/constants.dart';
import 'package:jasper/human.dart';
import 'package:jasper/post_image.dart';
import 'package:jasper/profile.dart';
import 'package:jasper/reaction_panel.dart';
import 'package:jasper/user_face.dart';
import 'package:status_alert/status_alert.dart';
import 'dart:io';
import 'package:visibility_detector/visibility_detector.dart';

class Post extends StatefulWidget {
  final String profilePhoto;
  final String username;
  final String caption;
  final String authorUID;
  final dynamic image;
  final int bookmark;
  final double radius;
  final double elevation;
  final String postID;
  final int reactionSelected;
  final String coverPhoto;
  final VoidCallback refreshParent;
  final String heroTag;
  final bool isInsideComments;
  final List<Map<String, dynamic>> snapshots;
  final List<Map<String, dynamic>> uploads;
  final int index;
  final Future<void> Function() loadMorePosts;
  final bool Function() shouldLoadMorePosts;
  final bool isUpload;
  final bool showReactionPanel;

  Post(
      {@required this.profilePhoto,
      @required this.username,
      @required this.caption,
      @required this.authorUID,
      @required this.image,
      @required this.bookmark,
      @required this.radius,
      @required this.shouldLoadMorePosts,
      @required this.isUpload,
      @required this.elevation,
      @required this.postID,
      @required this.reactionSelected,
      @required this.coverPhoto,
      @required this.refreshParent,
      @required this.isInsideComments,
      @required this.uploads,
      @required this.snapshots,
      @required this.heroTag,
      @required this.index,
      @required this.loadMorePosts,
      @required this.showReactionPanel});

  @override
  _PostState createState() => _PostState();
}

class _PostState extends State<Post> {
  bool get _clientIsAuthor {
    return this.widget.authorUID == Human.uid;
  }

  List<Map<String, dynamic>> _theList;

  File get _fProfilePhoto {
    if (_clientIsAuthor) {
      return Human.fProfilePhoto;
    }
    return null;
  }

  String get _profilePhoto {
    if (_clientIsAuthor) {
      return Human.profilePhoto;
    }
    return widget.profilePhoto;
  }

  final UniqueKey _visibilityKey = UniqueKey();
  bool _scheduleUpdate;

  String _whenWasThisPosted;
  int _reactionSelected;

  String _getPostageTime() {
    final DateTime currentTime = DateTime.now();
    final DateTime postTime =
        DateTime.fromMillisecondsSinceEpoch(this.widget.bookmark);
    final Duration diffDuration = currentTime.difference(postTime);
    int count;
    String word;
    if (_shouldCountInNow(diffDuration)) {
      count = null;
    } else if (_shouldCountInSeconds(diffDuration)) {
      count = diffDuration.inSeconds;
      word = 'second';
    } else if (_shouldCountInMinutes(diffDuration)) {
      count = diffDuration.inMinutes;
      word = 'minute';
    } else if (_shouldCountInHours(diffDuration)) {
      count = diffDuration.inHours;
      word = 'hour';
    } else if (_shouldCountInDays(diffDuration)) {
      count = diffDuration.inDays;
      word = 'day';
    } else if (_shouldCountInMonths(diffDuration)) {
      count = diffDuration.inDays ~/ 30;
      word = 'month';
    } else {
      count = diffDuration.inDays ~/ 365;
      word = 'year';
    }
    if (count == null) {
      return 'Just now';
    }
    return "$count $word${_isPlural(count) ? 's' : ''} ago";
  }

  bool _isPlural(int count) {
    return count > 1;
  }

  bool _shouldCountInNow(Duration duration) {
    final int durationInSeconds = duration.inSeconds;
    if (_durationIsZero(durationInSeconds)) {
      return true;
    }
    return false;
  }

  bool _shouldCountInSeconds(Duration duration) {
    final int durationInMinutes = duration.inMinutes;
    if (_durationIsZero(durationInMinutes)) {
      return true;
    }
    return false;
  }

  bool _shouldCountInMinutes(Duration duration) {
    final int durationInHours = duration.inHours;
    if (_durationIsZero(durationInHours)) {
      return true;
    }
    return false;
  }

  bool _shouldCountInHours(Duration duration) {
    final int durationInDays = duration.inDays;
    if (_durationIsZero(durationInDays)) {
      return true;
    }
    return false;
  }

  bool _shouldCountInDays(Duration duration) {
    final int durationInMonths = duration.inDays ~/ 60;
    if (_durationIsZero(durationInMonths)) {
      return true;
    }
    return false;
  }

  bool _shouldCountInMonths(Duration duration) {
    final int durationInYears = duration.inDays ~/ 365;
    if (_durationIsZero(durationInYears)) {
      return true;
    }
    return false;
  }

  bool _durationIsZero(int duration) {
    return duration == 0;
  }

  void _changeAction(bool actionValueIsNotNull) async {
    final DocumentReference docRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postID)
        .collection('reactions')
        .doc(Human.uid);
    if (actionValueIsNotNull) {
      _makeReaction(
        widget.postID,
      );
    } else {
      _unmakeReaction(docRef);
    }
  }

  void _unmakeReaction(DocumentReference docRef) {
    docRef.delete().catchError((error) => print(error));
  }

  void _makeReaction(String postID) {
    final HttpsCallable makeReaction =
        CloudFunctions.instance.getHttpsCallable(functionName: 'makeReaction');
    makeReaction.call({
      'uid': Human.uid,
      'postID': postID,
      'reactionSelected': Human.userActions[widget.postID]
    }).catchError((error) => print(error));
  }

  bool _actionValueIsNotNull() {
    return Human.userActions[widget.postID] != kNullActionValue;
  }

  bool _isOutOfSight(VisibilityInfo info) {
    return info.visibleFraction == 0.0;
  }

  bool _isInSight(VisibilityInfo info) {
    return info.visibleFraction == 1.0;
  }

  bool _hasAlreadyUpdated() {
    return !Human.reactionsToHave.containsKey(widget.postID);
  }

  bool _hasPushedToSeen() {
    return _theList[widget.index]['seen'] != null &&
        _theList[widget.index]['seen'] == true;
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (_isInSight(info) && !_hasPushedToSeen() && !_clientIsAuthor) {
      _pushPostToSeen();
    } else if (_isOutOfSight(info) &&
        _scheduleUpdate &&
        !_hasAlreadyUpdated()) {
      _processAction();
    }
  }

  void _pushPostToSeen() async {
    _theList[widget.index]['seen'] = true;
    final HttpsCallable pushPostToSeen = CloudFunctions.instance
        .getHttpsCallable(functionName: 'pushPostToSeen');
    pushPostToSeen.call({'uid': Human.uid, 'postID': widget.postID}).catchError(
        (error) => print(error));
  }

  void _processAction() {
    _scheduleUpdate = false;
    Human.reactionsToHave.remove(widget.postID);
    final bool actionValueIsNotNull = _actionValueIsNotNull();
    _changeAction(actionValueIsNotNull);
  }

  bool _isAlreadySelected(int reactionSelected) {
    return _getActionSelected() == reactionSelected;
  }

  void _onActionChanged(int reactionSelected) {
    _scheduleUpdate = true;
    final int userAction = _getActionSelected();
    if (userAction == reactionSelected) {
      Human.numberOfIthReactions[reactionSelected.toString()] =
          Human.numberOfIthReactions[reactionSelected.toString()] - 1;
    }
    if (userAction < 0) {
      Human.numberOfIthReactions[reactionSelected.toString()] =
          Human.numberOfIthReactions[reactionSelected.toString()] + 1;
    } else if (userAction != reactionSelected) {
      Human.numberOfIthReactions[userAction.toString()] =
          Human.numberOfIthReactions[userAction.toString()] - 1;
      Human.numberOfIthReactions[reactionSelected.toString()] =
          Human.numberOfIthReactions[reactionSelected.toString()] + 1;
    }
    Human.reactionsToHave[widget.postID] = Human.userActions[widget.postID] =
        _isAlreadySelected(reactionSelected)
            ? kNullActionValue
            : reactionSelected;
    setState(() {});
  }

  int _getActionSelected() {
    return Human.userActions[widget.postID] ?? _reactionSelected;
  }

  String get _username {
    if (_clientIsAuthor) {
      return Human.username;
    }
    return widget.username;
  }

  void _navigateToProfilePage() {
    final bool comesWithUserSnap = _clientIsAuthor;
    Navigator.of(context)
        .push(CupertinoPageRoute(builder: (BuildContext context) {
      return Profile(
        comesWithUserSnap: comesWithUserSnap,
        uid: widget.authorUID,
        initialIndex: 0,
        reactionSelected: 0,
        username: widget.username,
        profilePhoto: widget.profilePhoto,
        coverPhoto: widget.coverPhoto,
      );
    })).then((_) {
      widget.refreshParent();
    }).catchError((error) => print(error));
  }

  String get _numberOfCommentsTxt {
    final int numberOfComments = _theList[widget.index]['numberOfComments'];
    if (numberOfComments > 1000) {
      return '${((numberOfComments / 1000).round())}K Comments';
    }
    return '$numberOfComments Comments';
  }

  Future<bool> _canReport() {
    return showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(kPanelPadding))),
            title: Text('Is this post inappropriate?'),
            content: Text(
                'We will review this report within 24 hours and if deemed inappropriate the post will be immediately removed. We may also take action against the author of the post.'),
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

  Future<bool> _canDelete() {
    return showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(kPanelPadding))),
            title: Text('Delete post?'),
            content:
                Text('Are you sure you want to permanently delete this post?'),
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

  // void _navigateToCommentsSection() {
  //   Navigator.of(context)
  //       .push(
  //     CupertinoPageRoute(
  //         builder: (BuildContext context) {
  //           return PostPages(
  //             isUpload: widget.isUpload,
  //             shouldLoadMorePosts: widget.shouldLoadMorePosts,
  //             loadMorePosts: widget.loadMorePosts,
  //             initialPage: widget.index,
  //             uploads: widget.uploads ?? List<Map<String, dynamic>>(),
  //             snapshots: widget.snapshots ?? List<Map<String, dynamic>>(),
  //           );
  //         },
  //         fullscreenDialog: false),
  //   )
  //       .then((_) {
  //     widget.refreshParent();
  //   }).catchError((error) => print(error));
  // }

  @override
  void initState() {
    super.initState();
    if (widget.isUpload) {
      _theList = widget.uploads;
    } else {
      _theList = widget.snapshots;
    }
    _scheduleUpdate = false;
    _reactionSelected = widget.reactionSelected ?? kNullActionValue;
    _whenWasThisPosted = _getPostageTime();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      onVisibilityChanged: _onVisibilityChanged,
      key: _visibilityKey,
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(widget.radius)),
        child: Material(
          color: Colors.white,
          elevation: widget.elevation,
          borderRadius: BorderRadius.all(Radius.circular(widget.radius)),
          child: InkWell(
              onTap: null,
              // onTap: widget.isInsideComments ? null : _navigateToCommentsSection,
              child: Stack(
                children: [
                  Column(
                    children: [
                      Padding(
                          padding: EdgeInsets.only(
                              left: kPanelPadding * (1 + 1 / 3),
                              right: kPanelPadding * (1 + 1 / 3),
                              top: kPanelPadding * (1 + 1 / 3)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: _navigateToProfilePage,
                                    child: UserFace(
                                      elevation: 10 / 9,
                                      fProfilePhoto: _fProfilePhoto,
                                      iconSize: kPostFaceRadius * 2 / 3,
                                      profilePhoto: _profilePhoto,
                                      radius: kPostFaceRadius,
                                    ),
                                  ),
                                  SizedBox(width: kPanelPadding * 0.875),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: GestureDetector(
                                                  onTap: _navigateToProfilePage,
                                                  child: Text(
                                                    _username,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                        color: Colors.black87,
                                                        fontSize: 14.5,
                                                        fontWeight:
                                                            FontWeight.w400),
                                                  )),
                                            ),
                                            SizedBox(width: 100 / 3)
                                          ],
                                        ),
                                        Text(
                                          _whenWasThisPosted,
                                          style: TextStyle(
                                              color: Colors.blueGrey[100],
                                              fontSize: 12.0,
                                              fontWeight: FontWeight.w400),
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal:
                                        kPanelPadding / ((10 / 3) / 0.875),
                                    vertical: kPanelPadding * (1 + 1 / 9)),
                                child: HashTagText(
                                  text: widget.caption,
                                  decorateAtSign: true,
                                  decoratedStyle: TextStyle(
                                      color: Colors.blueAccent,
                                      fontSize: 19.5,
                                      fontWeight: FontWeight.w400),
                                  basicStyle: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 19.5,
                                      fontWeight: FontWeight.w400),
                                  onTap: (String txt) {
                                    _showErrorMsg('Coming soon...');
                                  },
                                ),
                              ),
                            ],
                          )),
                      widget.image == null
                          ? Container()
                          : PostImage(
                              image: widget.image,
                              heroTag: widget.heroTag,
                            ),
                      !widget.showReactionPanel
                          ? Container()
                          : Column(
                              children: [
                                SizedBox(
                                  height: 1.7,
                                  width: double.infinity,
                                  child: Material(
                                      color: Colors.blueGrey[50]
                                          .withOpacity(1 / 3)),
                                ),
                                ClipRRect(
                                    borderRadius: BorderRadius.only(
                                        bottomRight:
                                            Radius.circular(widget.radius),
                                        bottomLeft:
                                            Radius.circular(widget.radius)),
                                    child: Stack(
                                      children: [
                                        ReactionPanel(
                                          emojis: kEmojis,
                                          unselectedOpacity: 1 / 4.5,
                                          panelHeight: 52.5,
                                          fontSize: 18.75,
                                          backgroundColor: Colors.white,
                                          elevation: 10 / 3,
                                          radius: 0.0,
                                          onActionChanged: _onActionChanged,
                                          reactionSelected:
                                              _getActionSelected(),
                                        ),
                                        !widget.isInsideComments
                                            ? Container()
                                            : Positioned.fill(
                                                child: Material(
                                                  color: Colors.white,
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      SizedBox(
                                                          width: kPanelPadding *
                                                              (1.8)),
                                                      Text(
                                                        _numberOfCommentsTxt,
                                                        style: TextStyle(
                                                            fontSize: 12.5,
                                                            color: Colors
                                                                .blueAccent,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                      ],
                                    )),
                              ],
                            )
                    ],
                  ),
                  Positioned.fill(
                      child: Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: Icon(
                        Entypo.dots_three_vertical,
                        size: 15.0,
                        color: Colors.blueGrey[50],
                      ),
                      onPressed: _showPostOptions,
                    ),
                  ))
                ],
              )),
        ),
      ),
    );
  }

  void _showPostOptions() {
    bool hasLodgedReport = false;
    bool hasDeletedPost = false;
    bool hasTapped = false;
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SizedBox(
            height: Human.uid != widget.authorUID ? 120.0 : 180.0,
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
                            widget.authorUID != Human.uid
                                ? Container()
                                : Column(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: FlatButton(
                                            height: 36.0,
                                            shape: StadiumBorder(),
                                            color: Colors.redAccent,
                                            onPressed: () async {
                                              if (hasTapped) {
                                                return;
                                              }
                                              hasTapped = true;
                                              final bool canDelete =
                                                  await _canDelete() ?? false;
                                              if (canDelete) {
                                                hasDeletedPost = true;
                                                Human.hasDeleted
                                                    .add(widget.postID);
                                                if (widget.isUpload) {
                                                  widget.uploads.removeWhere(
                                                      (element) =>
                                                          element['postID'] ==
                                                          widget.postID);
                                                } else {
                                                  widget.snapshots.removeWhere(
                                                      (element) =>
                                                          element['postID'] ==
                                                          widget.postID);
                                                }
                                                widget.refreshParent();
                                                final HttpsCallable deletePost =
                                                    CloudFunctions.instance
                                                        .getHttpsCallable(
                                                            functionName:
                                                                'deletePost');
                                                deletePost.call({
                                                  'postID': widget.postID,
                                                }).catchError(
                                                    (error) => print(error));
                                              }
                                              Navigator.of(context).pop();
                                            },
                                            child: Text(
                                              'Delete this post',
                                              style: TextStyle(
                                                  color: Colors.white),
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
                                  onPressed: () async {
                                    if (hasTapped) {
                                      return;
                                    }
                                    hasTapped = true;
                                    final bool canReport =
                                        await _canReport() ?? false;
                                    if (canReport) {
                                      hasLodgedReport = true;
                                      final HttpsCallable reportPost =
                                          CloudFunctions.instance
                                              .getHttpsCallable(
                                                  functionName: 'reportPost');
                                      reportPost.call({
                                        'postID': widget.postID,
                                        'uid': Human.uid
                                      }).catchError((error) => print(error));
                                    }
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(
                                    'Report as inappropriate',
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
      if (hasLodgedReport) {
        StatusAlert.show(
          context,
          margin: EdgeInsets.all(100 * 2 / 3),
          borderRadius: BorderRadius.all(Radius.circular(kPanelPadding)),
          title: 'Reported',
          duration: Duration(milliseconds: 1500),
          configuration: IconConfiguration(icon: Icons.flag),
        );
      } else if (hasDeletedPost) {
        StatusAlert.show(
          context,
          margin: EdgeInsets.all(100 * 2 / 3),
          borderRadius: BorderRadius.all(Radius.circular(kPanelPadding)),
          title: 'Deleted',
          duration: Duration(milliseconds: 1500),
          configuration: IconConfiguration(icon: Icons.delete),
        );
      }
    });
  }

  @override
  void dispose() {
    if (_scheduleUpdate && !_hasAlreadyUpdated()) {
      _scheduleUpdate = false;
      _processAction();
    }
    super.dispose();
  }
}
