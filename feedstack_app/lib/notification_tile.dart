import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jasper/human.dart';
import 'package:jasper/profile.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'constants.dart';

class NotificationTile extends StatefulWidget {
  final String profilePhoto;
  final String username;
  final double elevation;
  final String emoji;
  final bool seen;
  final String notificationID;
  final int bookmark;
  final String postID;
  final int reactionSelected;
  final String coverPhoto;
  final String uid;
  final bool isReaction;
  final String heroTag;

  NotificationTile({
    @required this.profilePhoto,
    @required this.username,
    @required this.elevation,
    @required this.emoji,
    @required this.seen,
    @required this.notificationID,
    @required this.bookmark,
    @required this.postID,
    @required this.reactionSelected,
    @required this.coverPhoto,
    @required this.uid,
    @required this.isReaction,
    @required this.heroTag,
  });

  @override
  _NotificationTileState createState() => _NotificationTileState();
}

class _NotificationTileState extends State<NotificationTile> {
  final UniqueKey _visibilityKey = UniqueKey();
  bool _hasPushedToSeen;
  String _whenWasThisPosted;

  bool _isInSight(VisibilityInfo info) {
    return info.visibleFraction == 1.0;
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!widget.seen && _isInSight(info) && !_hasPushedToSeen) {
      _hasPushedToSeen = true;
      _pushNotificationToSeen();
    }
  }

  void _pushNotificationToSeen() {
    final HttpsCallable pushNotificationToSeen = CloudFunctions.instance
        .getHttpsCallable(functionName: 'pushNotificationToSeen');
    pushNotificationToSeen.call({
      'notificationID': widget.notificationID,
      'uid': Human.uid
    }).catchError((error) => print(error));
  }

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

  void _navigateToProfile(
      {@required String uid,
      @required String coverPhoto,
      @required String profilePhoto,
      @required bool comesWithUserSnap,
      @required String username,
      @required String targetReaction}) {
    final int reactionSelected = widget.reactionSelected ?? 0;
    final int initialIndex = widget.isReaction ? 1 : 0;
    Navigator.of(context)
        .push(CupertinoPageRoute(builder: (BuildContext context) {
      return Profile(
        targetReaction: targetReaction,
        reactionSelected: reactionSelected,
        comesWithUserSnap: comesWithUserSnap,
        coverPhoto: coverPhoto,
        profilePhoto: profilePhoto,
        heroTag: widget.heroTag,
        initialIndex: initialIndex,
        uid: uid,
        username: username,
      );
    }));
  }

  @override
  void initState() {
    super.initState();
    _hasPushedToSeen = false;
    _whenWasThisPosted = _getPostageTime();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: _visibilityKey,
      onVisibilityChanged: _onVisibilityChanged,
      child: Material(
        elevation: this.widget.elevation,
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: () {
              _navigateToProfile(
                  uid: widget.uid,
                  coverPhoto: widget.coverPhoto,
                  profilePhoto: widget.profilePhoto,
                  comesWithUserSnap: false,
                  username: widget.username,
                  targetReaction: widget.postID);
            },
            child: Padding(
                padding: EdgeInsets.all(kPanelPadding * (1 + 1 / 3)),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: kPanelPadding / 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: RichText(
                                    overflow: TextOverflow.ellipsis,
                                    text: TextSpan(children: [
                                      TextSpan(
                                        text: '${widget.username} ',
                                        style: TextStyle(
                                          color: Colors.blueAccent,
                                          fontSize: kTitleFontSize,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      TextSpan(
                                        text: widget.isReaction
                                            ? 'responds '
                                            : 'follows ',
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: kTitleFontSize,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      TextSpan(
                                        text: widget.isReaction
                                            ? 'to your post'
                                            : 'your account',
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: kTitleFontSize,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ]),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10 / 9),
                            RichText(
                              text: TextSpan(children: [
                                TextSpan(
                                  text: _whenWasThisPosted,
                                  style: TextStyle(
                                      color: Colors.blueGrey[200],
                                      fontSize: kTitleFontSize * 0.875 * 0.875,
                                      fontWeight: FontWeight.w400),
                                ),
                              ]),
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        backgroundColor: Colors.transparent,
                        radius: kPostFaceRadius,
                        child: Text(
                          this.widget.emoji,
                          style: TextStyle(fontSize: 22.5),
                        ),
                      ),
                    ],
                  ),
                )),
          ),
        ),
      ),
    );
  }
}
