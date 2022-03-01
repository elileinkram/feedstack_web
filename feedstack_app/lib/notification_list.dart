import 'package:flutter/material.dart';
import 'package:jasper/constants.dart';
import 'package:jasper/digest_notifier.dart';
import 'package:jasper/notification_tile.dart';
import 'package:jasper/waiting_widget.dart';

class NotificationList extends StatefulWidget {
  final List<Map<String, dynamic>> snapshots;
  final Future<void> Function(String tabLabel) updateList;
  final String tabLabel;
  final bool nothingLeftInside;
  final bool isRefreshing;

  NotificationList(
      {@required this.snapshots,
      @required this.updateList,
      @required this.tabLabel,
      @required this.nothingLeftInside,
      @required this.isRefreshing});

  @override
  _NotificationListState createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  final double _notificationPadding = kPanelPadding / 2;
  bool _isLoading;

  bool _shouldUpdate() {
    return !widget.nothingLeftInside &&
        !widget.isRefreshing &&
        widget.snapshots.isNotEmpty;
  }

  void _toggleIsLoading() {
    _isLoading = !_isLoading;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _onUpdate() async {
    _toggleIsLoading();
    await widget.updateList(widget.tabLabel);
    _toggleIsLoading();
  }

  @override
  void initState() {
    super.initState();
    _isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return DigestNotifier(
      onUpdate: _onUpdate,
      shouldUpdate: _shouldUpdate,
      cutoff: MediaQuery.of(context).size.height,
      child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Column(
              children: [
                Column(
                  children: List.generate(widget.snapshots.length, (index) {
                    final Map<String, dynamic> snapshot =
                        widget.snapshots[index];
                    final int reactionSelected = snapshot['reactionSelected'];
                    final bool isReaction = snapshot['isReaction'];
                    String emoji =
                        isReaction ? kEmojis[reactionSelected] : kPartyEmoji;
                    final String profilePhoto = snapshot['profilePhoto'];
                    final UniqueKey key = snapshot['key'];
                    final bool seen = snapshot['seen'];
                    final String uid = snapshot['uid'];
                    final String postID = snapshot['postID'];
                    final String notificationID = snapshot['notificationID'];
                    final int bookmark = snapshot['bookmark'];
                    final String coverPhoto = snapshot['coverPhoto'];
                    final String username = snapshot['username'];
                    return Padding(
                        key: key,
                        padding: EdgeInsets.only(
                          top: _notificationPadding,
                          right: _notificationPadding,
                          left: _notificationPadding,
                        ),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.all(Radius.circular(10 / 9)),
                          child: NotificationTile(
                            isReaction: isReaction,
                            coverPhoto: coverPhoto,
                            heroTag: key.toString(),
                            postID: postID,
                            notificationID: notificationID,
                            reactionSelected: reactionSelected,
                            uid: uid,
                            bookmark: bookmark,
                            seen: seen,
                            elevation: 0,
                            emoji: emoji,
                            profilePhoto: profilePhoto,
                            username: username,
                          ),
                        ));
                  }),
                ),
                SizedBox(
                  height: kDefaultLoadingHeight,
                  child: Align(
                    alignment: Alignment.center,
                    child: WaitingWidget(
                      color: Colors.blueAccent,
                      isLoading: _isLoading,
                    ),
                  ),
                ),
                SizedBox(height: _notificationPadding)
              ],
            ),
          )),
    );
  }
}
