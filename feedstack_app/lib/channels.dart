import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jasper/feed_info.dart';
import 'package:jasper/human.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'constants.dart';

class Channels extends StatefulWidget {
  final VoidCallback refreshParent;
  final String currentChannel;
  final void Function(String currentChannel, bool isTrending)
      updateCurrentChannel;
  final ScrollController scrollController;
  final List<Map<String, dynamic>> trendingChannels;

  Channels({
    @required this.refreshParent,
    @required this.trendingChannels,
    @required this.currentChannel,
    @required this.updateCurrentChannel,
    @required this.scrollController,
  });

  @override
  _ChannelsState createState() => _ChannelsState();
}

class _ChannelsState extends State<Channels> {
  bool _isSelected(String documentID) {
    return documentID == widget.currentChannel;
  }

  final UniqueKey _uniqueKey = UniqueKey();

  Color _labelColor(bool isSelected) {
    return isSelected ? Colors.white : Colors.white.withOpacity(2 / 3);
  }

  Color _backgroundColor(bool isSelected) {
    return isSelected ? Colors.blueAccent : Colors.transparent;
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (info.visibleFraction == 0.0) {
      widget.trendingChannels.sort((a, b) => b['lastUsed'] - a['lastUsed']);
      Human.myChannels.sort((a, b) => b['lastUsed'] - a['lastUsed']);
      widget.scrollController.jumpTo(0.0);
    }
  }

  bool _showingTrending;

  @override
  void initState() {
    super.initState();
    _showingTrending = false;
  }

  void _navigateToFeedInfo(
    String name,
    String channelID,
    String photo,
    String description,
    bool hasDownloaded,
    String code,
    int bookmark,
  ) {
    Navigator.of(context)
        .push(CupertinoPageRoute(
            builder: (BuildContext context) {
              return FeedInfo(
                code: code,
                bookmark: bookmark,
                hasDownloaded: hasDownloaded,
                photo: photo,
                channelID: channelID,
                name: name,
                description: description,
              );
            },
            fullscreenDialog: false))
        .then((_) {
      widget.refreshParent();
    }).catchError((error) => print(error));
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      onVisibilityChanged: _onVisibilityChanged,
      key: _uniqueKey,
      child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: widget.scrollController,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width + kPanelPadding,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(width: kPanelPadding),
                Padding(
                  padding: EdgeInsets.only(right: kPanelPadding * 2 / 3),
                  child: Theme(
                      data: ThemeData(
                          canvasColor: Colors.transparent,
                          splashColor: Colors.transparent),
                      child: Stack(
                        children: [
                          FlatButton(
                            shape: StadiumBorder(),
                            minWidth: 0.0,
                            height: 100 / 3,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.symmetric(
                                horizontal:
                                    kPanelPadding * (1 + 1 / (10 * 2 / 3))),
                            color: !_showingTrending
                                ? Colors.blueAccent
                                : Colors.blueAccent[400],
                            onPressed: () {
                              String channelID = 'a';
                              if (widget.trendingChannels.isNotEmpty) {
                                channelID =
                                    widget.trendingChannels.first['channelID'];
                              }
                              _showingTrending = true;
                              setState(() {});
                              widget.updateCurrentChannel(
                                  channelID, _showingTrending);
                              Human.myChannels.sort(
                                  (a, b) => b['lastUsed'] - a['lastUsed']);
                            },
                            child: Text(
                              'Trending',
                              style: TextStyle(
                                color: _labelColor(_showingTrending),
                              ),
                            ),
                          ),
                          Positioned.fill(
                              child: !_showingTrending
                                  ? Container()
                                  : Material(color: Colors.transparent))
                        ],
                      )),
                ),
                Padding(
                  padding: EdgeInsets.only(right: kPanelPadding * 2 / 3),
                  child: Theme(
                      data: ThemeData(
                          canvasColor: Colors.transparent,
                          splashColor: Colors.transparent),
                      child: Stack(
                        children: [
                          FlatButton(
                            shape: StadiumBorder(),
                            minWidth: 0.0,
                            height: 100 / 3,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.symmetric(
                                horizontal:
                                    kPanelPadding * (1 + 1 / (10 * 2 / 3))),
                            color: _showingTrending
                                ? Colors.blueAccent
                                : Colors.blueAccent[400],
                            onPressed: () {
                              String channelID = kDefaultChannelNames.first;
                              if (Human.myChannels.isNotEmpty) {
                                channelID = Human.myChannels.first['channelID'];
                              }
                              _showingTrending = false;
                              setState(() {});
                              widget.updateCurrentChannel(
                                  channelID, _showingTrending);
                              widget.trendingChannels.sort(
                                  (a, b) => b['lastUsed'] - a['lastUsed']);
                            },
                            child: Text(
                              'My feeds',
                              style: TextStyle(
                                  color: _labelColor(!_showingTrending)),
                            ),
                          ),
                          Positioned.fill(
                              child: _showingTrending
                                  ? Container()
                                  : Material(color: Colors.transparent))
                        ],
                      )),
                ),
                Row(
                  children: List<Widget>.generate(
                      _showingTrending
                          ? widget.trendingChannels.length
                          : Human.myChannels.length, (int index) {
                    final Map<String, dynamic> data = _showingTrending
                        ? widget.trendingChannels[index]
                        : Human.myChannels[index];
                    final String channelID = data['channelID'];
                    final int bookmark = data['bookmark'];
                    final String description = data['description'];
                    final String name = data['name'];
                    final bool hasDownloaded = !_showingTrending ||
                        Human.hasDownloaded.contains(channelID);
                    final String photo = data['photo'];
                    final String code = data['code'];
                    final bool isSelected = _isSelected(channelID);
                    return Padding(
                      padding: EdgeInsets.only(right: kPanelPadding * 2 / 3),
                      key: data['key'],
                      child: Theme(
                        data: ThemeData(canvasColor: Colors.transparent),
                        child: RawChip(
                          elevation: 0.0,
                          disabledColor: _backgroundColor(isSelected),
                          backgroundColor: _backgroundColor(isSelected),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                  Radius.circular(kPanelPadding / 3))),
                          onPressed: () => isSelected
                              ? _navigateToFeedInfo(name, channelID, photo,
                                  description, hasDownloaded, code, bookmark)
                              : widget.updateCurrentChannel(
                                  channelID, _showingTrending),
                          label: Text(
                            name,
                            style: TextStyle(
                                color: _labelColor(isSelected),
                                fontWeight: FontWeight.w500,
                                fontSize: 14.0),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                SizedBox(width: kPanelPadding / 3),
              ],
            ),
          )),
    );
  }
}
