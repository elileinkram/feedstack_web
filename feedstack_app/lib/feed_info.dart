import 'dart:ui';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:jasper/web_doc.dart';
import 'constants.dart';
import 'human.dart';

class FeedInfo extends StatefulWidget {
  final String name;
  final String channelID;
  final String photo;
  final String description;
  final bool hasDownloaded;
  final int bookmark;
  final String code;

  FeedInfo({
    @required this.name,
    @required this.channelID,
    @required this.photo,
    @required this.description,
    @required this.hasDownloaded,
    @required this.code,
    @required this.bookmark,
  });

  @override
  _FeedInfoState createState() => _FeedInfoState();
}

class _FeedInfoState extends State<FeedInfo> {
  String _whenWasThisPosted;

  bool _hasDownloaded;

  void _onBack() {
    Navigator.of(context).pop();
  }

  String _buttonTxt() {
    return _hasDownloaded ? 'Remove from library' : 'Add to library';
  }

  Color _buttonColor() {
    return _hasDownloaded ? Colors.blueGrey[50] : Colors.blueAccent;
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

  void _navigateToSourceCode() {
    Navigator.of(context)
        .push(CupertinoPageRoute(builder: (BuildContext context) {
      return WebDoc(title: 'Source code', initialUrl: widget.code);
    })).catchError((error) => print(error));
  }

  void _installChannel() {
    final HttpsCallable installChannel = CloudFunctions.instance
        .getHttpsCallable(functionName: 'installChannel');
    installChannel
        .call({'uid': Human.uid, 'channelID': widget.channelID}).catchError(
            (error) => print(error));
  }

  String _newCurrentChannel() {
    Human.myChannels.sort((a, b) => b['lastUsed'] - a['lastUsed']);
    return Human.myChannels.first['channelID'];
  }

  void _uninstallChannel() {
    final HttpsCallable uninstallChannel = CloudFunctions.instance
        .getHttpsCallable(functionName: 'uninstallChannel');
    uninstallChannel.call({
      'uid': Human.uid,
      'channelID': widget.channelID,
      'newChannelID': _newCurrentChannel(),
    }).catchError((error) => print(error));
  }

  Future<bool> _canUninstall() {
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
                  text: 'uninstall ',
                  style: TextStyle(
                      color: Colors.black87,
                      fontSize: kTitleFontSize,
                      fontWeight: FontWeight.w300),
                ),
                TextSpan(
                  text: widget.name,
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

  void _uninstallErrorMsg() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10 * 2 / 3))),
            content: RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: 'You can\'t ',
                  style: TextStyle(
                      color: Colors.black87, fontSize: kTitleFontSize),
                ),
                TextSpan(
                  text: 'uninstall ',
                  style: TextStyle(
                      color: Colors.black87,
                      fontSize: kTitleFontSize,
                      fontWeight: FontWeight.w300),
                ),
                TextSpan(
                  text: widget.name,
                  style: TextStyle(
                      color: Colors.black87,
                      fontSize: kTitleFontSize,
                      fontWeight: FontWeight.w400),
                ),
                TextSpan(
                  text: '.',
                  style: TextStyle(
                      color: Colors.black87, fontSize: kTitleFontSize),
                )
              ]),
            ),
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

  void _toggleDownload() async {
    if (_hasDownloaded && kDefaultChannelNames.contains(widget.channelID)) {
      _uninstallErrorMsg();
      return;
    } else if (_hasDownloaded) {
      final bool canUninstall = await _canUninstall() ?? false;
      if (!canUninstall) {
        return;
      }
    }
    if (!_hasDownloaded && Human.numberOfChannels >= 250) {
      _showErrorMsg('You can\'t have more than 250 channels in your library.');
      return;
    }
    if (_hasDownloaded && Human.numberOfChannels == 1) {
      _showErrorMsg('You can\'t delete your only feed!');
      return;
    }
    _hasDownloaded = !_hasDownloaded;
    if (_hasDownloaded) {
      Human.numberOfChannels++;
      Human.channelsToDownload[widget.channelID] = 1;
      Human.myChannels.insert(0, {
        'name': widget.name,
        'lastUsed': DateTime.now().millisecondsSinceEpoch,
        'channelID': widget.channelID,
        'bookmark': widget.bookmark,
        'description': widget.description,
        'photo': widget.photo,
        'code': widget.code,
        'key': UniqueKey(),
      });
    } else {
      Human.numberOfChannels--;
      Human.channelsToDownload[widget.channelID] = 0;
      Human.myChannels
          .removeWhere((channel) => channel['channelID'] == widget.channelID);
    }
    if (_hasDownloaded == widget.hasDownloaded) {
      Human.channelsToDownload
          .removeWhere((key, value) => key == widget.channelID);
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _whenWasThisPosted = _getPostageTime();
    _hasDownloaded = widget.hasDownloaded;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.blueAccent,
      child: SafeArea(
        child: Scaffold(
            backgroundColor: Colors.white,
            extendBodyBehindAppBar: true,
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
                automaticallyImplyLeading: false,
                elevation: 0.0,
                backgroundColor: Colors.transparent,
                title: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                      onPressed: _onBack,
                    ),
                    Expanded(
                      child: Text(
                        widget.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white, fontSize: kTitleFontSize),
                      ),
                    )
                  ],
                )),
            body: Column(
              children: [
                Expanded(
                  flex: 9,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: FancyShimmerImage(
                          imageUrl: widget.photo,
                          boxFit: BoxFit.cover,
                        ),
                      ),
                      Positioned.fill(
                          child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                              sigmaX: 10 * 2 / 3, sigmaY: 10 * 2 / 3),
                          child: Container(
                            decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                  Colors.black87.withOpacity(1 / 3 * 2 / 3),
                                  Colors.black87
                                      .withOpacity(1 / 3 * 2 / 3 * 1 / 3),
                                  Colors.black87.withOpacity(
                                      1 / 3 * 2 / 3 * 1 / 3 * 2 / 3),
                                  Colors.black87.withOpacity(
                                      1 / 3 * 2 / 3 * 1 / 3 * 2 / 3),
                                  Colors.black87
                                      .withOpacity(1 / 3 * 2 / 3 * 1 / 3),
                                  Colors.black87.withOpacity(1 / 3 * 2 / 3)
                                ])),
                          ),
                        ),
                      )),
                      Center(
                        child: SizedBox(
                            height: MediaQuery.of(context).size.height / 4.5,
                            width: MediaQuery.of(context).size.height / 4.5,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Material(
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(
                                            MediaQuery.of(context).size.height /
                                                9 *
                                                0.875 *
                                                (1 - 1 / 30))),
                                    color: Colors.transparent,
                                    elevation: 10 / 3 * (1 - 1 / 30),
                                  ),
                                ),
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(
                                            MediaQuery.of(context).size.height /
                                                9 *
                                                0.875 *
                                                (1 - 1 / 30))),
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: Material(
                                              color: Colors.blueGrey[50]),
                                        ),
                                        Positioned.fill(
                                            child: Center(
                                          child: Icon(
                                            FontAwesome5Solid.stream,
                                            color: Colors.blueGrey[200],
                                            size: MediaQuery.of(context)
                                                    .size
                                                    .height /
                                                9 *
                                                2 /
                                                3,
                                          ),
                                        )),
                                        Positioned.fill(
                                          child: FancyShimmerImage(
                                            imageUrl: widget.photo,
                                            boxFit: BoxFit.cover,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )),
                      )
                    ],
                  ),
                ),
                Expanded(
                  flex: 12,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: kPanelPadding * (1 + 1 / 3) * (1 + 1 / 9)),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: kPanelPadding *
                                  (1 + 1 / 3) *
                                  (1 + 1 / 9) *
                                  (1 + 1 / 3)),
                          child: Material(
                            color: Color(kDefaultBackgroundColor),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                    Radius.circular(kPanelPadding))),
                            child: Padding(
                                padding: EdgeInsets.all(kTitleFontSize * 0.875),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    RichText(
                                      text: TextSpan(children: [
                                        TextSpan(
                                          text: 'Description',
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: kTitleFontSize,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ]),
                                    ),
                                    SizedBox(height: kTitleFontSize / 3),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10 / 9),
                                      child: RichText(
                                        text: TextSpan(children: [
                                          TextSpan(
                                            text: widget.description,
                                            style: TextStyle(
                                              color: Colors.black87,
                                              fontSize: kTitleFontSize * 0.875,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ]),
                                      ),
                                    ),
                                  ],
                                )),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: kPanelPadding * (1 + 1 / 3)),
                            child: FlatButton(
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              color: _buttonColor(),
                              height: 40.0,
                              padding: EdgeInsets.all(0.0),
                              shape: StadiumBorder(),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _hasDownloaded
                                      ? Container()
                                      : Row(
                                          children: [
                                            Icon(Icons.add,
                                                size: 18.0,
                                                color: Colors.white),
                                            SizedBox(width: 10 * 2 / 3),
                                          ],
                                        ),
                                  Text(
                                    _buttonTxt(),
                                    style: TextStyle(
                                      color: _hasDownloaded
                                          ? Colors.black87
                                          : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              onPressed: _toggleDownload,
                            ),
                          ),
                        ),
                        SizedBox(
                            height: kPanelPadding *
                                (1 + 1 / 3) *
                                (1 + 1 / 9) *
                                (1 + 1 / 3)),
                        SizedBox(
                          width: double.infinity,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: kPanelPadding * (1 + 1 / 3)),
                            child: FlatButton(
                              height: 40.0,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              color: Color(kDefaultBackgroundColor),
                              shape: StadiumBorder(),
                              child: Text(
                                'Source code',
                                style: TextStyle(
                                  color: Colors.blueAccent,
                                ),
                              ),
                              onPressed: _navigateToSourceCode,
                            ),
                          ),
                        ),
                        Expanded(child: Container()),
                        Padding(
                          padding: EdgeInsets.only(bottom: 10 * 2 / 3),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FlatButton(
                              child: Text(
                                'Created $_whenWasThisPosted',
                                style: TextStyle(
                                  color: Colors.blueGrey[200],
                                  fontSize: kTitleFontSize * 0.75,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              onPressed: null,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            )),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    if (_hasDownloaded && !Human.hasDownloaded.contains(widget.channelID)) {
      Human.hasDownloaded.add(widget.channelID);
    }
    if (Human.channelsToDownload.containsKey(widget.channelID)) {
      Human.channelsToDownload.remove(widget.channelID);
      if (_hasDownloaded) {
        _installChannel();
      } else {
        _uninstallChannel();
      }
    }
  }
}
