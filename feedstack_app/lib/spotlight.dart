import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jasper/constants.dart';
import 'package:jasper/digest_notifier.dart';
import 'package:jasper/feed_info.dart';
import 'package:jasper/feed_tile.dart';
import 'package:jasper/profile.dart';
import 'package:jasper/user_tile.dart';
import 'package:jasper/waiting_widget.dart';
import 'banner_icon.dart';
import 'human.dart';

class Spotlight extends StatefulWidget {
  final bool isUserSearch;
  final TextEditingController textEditingController;
  final Key key;

  Spotlight(
      {@required this.isUserSearch,
      @required this.textEditingController,
      @required this.key})
      : super(key: key);

  @override
  _SpotlightState createState() => _SpotlightState();
}

class _SpotlightState extends State<Spotlight>
    with AutomaticKeepAliveClientMixin {
  final List<DocumentSnapshot> _userSnapshots = List<DocumentSnapshot>();
  final Map<String, UniqueKey> _userKeys = Map<String, UniqueKey>();
  final Map<String, UniqueKey> _recentKeys = Map<String, UniqueKey>();
  final Set<String> _userIDs = Set<String>();
  String _searchQ;
  bool _isLoading;
  bool _noMoreHumans;

  bool _fieldIsEmpty() {
    return widget.textEditingController.text.trim().isEmpty;
  }

  int _getSearchLimit() {
    if (widget.isUserSearch) {
      return kDefaultUserSearchLimit;
    }
    return kDefaultChannelSearchLimit;
  }

  Future<void> _getSearchResults(int humanLimit) async {
    _toggleIsLoading(true);
    final String searchQ =
        widget.textEditingController.text.toLowerCase().replaceAll(' ', '');
    _searchQ = searchQ;
    final String collectionName = widget.isUserSearch ? 'users' : 'channels';
    final QuerySnapshot qs = await FirebaseFirestore.instance
        .collection(collectionName)
        .where('names', arrayContains: _searchQ)
        .orderBy('nameLength', descending: false)
        .limit(humanLimit)
        .get()
        .catchError((error) => print(error));
    if (qs == null || qs.docs == null || _hasChangedSearch(searchQ)) {
      return;
    }
    if (qs.docs.length < humanLimit) {
      _noMoreHumans = true;
    }
    for (int i = 0; i < qs.docs.length; i++) {
      if (_userIDs.contains(qs.docs[i].id)) {
        continue;
      }
      _userIDs.add(qs.docs[i].id);
      _userKeys[qs.docs[i].id] = UniqueKey();
      _userSnapshots.add(qs.docs[i]);
    }
    _toggleIsLoading(false);
  }

  bool _hasChangedSearch(String searchQ) {
    return widget.textEditingController.text
            .toLowerCase()
            .replaceAll(' ', '') !=
        searchQ;
  }

  void _toggleIsLoading(bool isLoading) {
    _isLoading = isLoading;
    if (mounted) {
      setState(() {});
    }
  }

  void _searchListener() {
    if (_fieldIsEmpty()) {
      if (_searchQ != '') {
        _searchQ = '';
      }
      return;
    }
    if (!_hasChangedSearch(_searchQ)) {
      return;
    }
    _reset();
    _getSearchResults(_getSearchLimit());
  }

  void _reset() {
    _noMoreHumans = false;
    _userIDs.clear();
    _userSnapshots.clear();
    _userKeys.clear();
  }

  void _hideKeypad() {
    WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
  }

  void _addUserToRecents(String userUID) {
    final HttpsCallable addUserToRecents = CloudFunctions.instance
        .getHttpsCallable(functionName: 'addUserToRecents');
    addUserToRecents.call({'userUID': userUID, 'uid': Human.uid}).catchError(
        (error) => print(error));
  }

  void _addChannelToRecents(String channelID) {
    final HttpsCallable addChannelToRecents = CloudFunctions.instance
        .getHttpsCallable(functionName: 'addChannelToRecents');
    addChannelToRecents
        .call({'channelID': channelID, 'uid': Human.uid}).catchError(
            (error) => print(error));
  }

  void _removeSnapshotFromRecents(DocumentSnapshot snapshot) {
    for (int i = 0; i < _getHumanList.length; i++) {
      if (snapshot.id == _getHumanList[i].id) {
        _getHumanList.removeAt(i);
        break;
      }
    }
  }

  void _navigateToProfilePage(
      String userUID,
      String username,
      String profilePhoto,
      String coverPhoto,
      dynamic numberOfIthReactions,
      DocumentSnapshot snapshot) {
    _removeSnapshotFromRecents(snapshot);
    _getHumanList.insert(0, snapshot);
    _addUserToRecents(userUID);
    _hideKeypad();
    final bool comesWithSnap = numberOfIthReactions != null;
    Navigator.of(context)
        .push(CupertinoPageRoute(builder: (BuildContext context) {
      return Profile(
        initialIndex: 0,
        reactionSelected: 0,
        numberOfIthReactions: numberOfIthReactions,
        comesWithUserSnap: comesWithSnap,
        uid: userUID,
        username: username,
        profilePhoto: profilePhoto,
        coverPhoto: coverPhoto,
      );
    })).then((_) {
      if (mounted) {
        setState(() {});
      }
    }).catchError((error) => print(error));
  }

  List<DocumentSnapshot> get _getHumanList {
    if (widget.isUserSearch) {
      return Human.recentUserSearches;
    }
    return Human.recentChannelSearches;
  }

  int _itemCount() {
    if (_fieldIsEmpty()) {
      return _getHumanList.length;
    }
    return _userSnapshots.length;
  }

  DocumentSnapshot _getSnapshot(int index) {
    if (_fieldIsEmpty()) {
      return _getHumanList[index];
    }
    return _userSnapshots[index];
  }

  Future<void> _onUpdate() async {
    _getSearchResults(_getSearchLimit() + _userSnapshots.length);
  }

  bool _shouldUpdate() {
    return !_fieldIsEmpty() &&
        !_noMoreHumans &&
        !_isLoading &&
        _userSnapshots.isNotEmpty;
  }

  void _populateRecentKeys() {
    for (int i = 0; i < _getHumanList.length; i++) {
      _recentKeys[_getHumanList[i].id] = UniqueKey();
    }
  }

  String get _getBannerMsg {
    return widget.isUserSearch ? 'No people found' : 'No feeds found';
  }

  void _navigateToFeedInfo(
      String name,
      String channelID,
      String photo,
      String description,
      bool hasDownloaded,
      String code,
      int bookmark,
      DocumentSnapshot snapshot) {
    _removeSnapshotFromRecents(snapshot);
    _getHumanList.insert(0, snapshot);
    _addChannelToRecents(channelID);
    _hideKeypad();
    Navigator.of(context)
        .push(CupertinoPageRoute(builder: (BuildContext context) {
      return FeedInfo(
        name: name,
        channelID: channelID,
        photo: photo,
        description: description,
        hasDownloaded: hasDownloaded,
        code: code,
        bookmark: bookmark,
      );
    })).then((_) {
      if (mounted) {
        setState(() {});
      }
    }).catchError((error) => print(error));
  }

  @override
  void initState() {
    super.initState();
    _populateRecentKeys();
    _isLoading = false;
    _noMoreHumans = false;
    _searchQ = '';
    widget.textEditingController.addListener(_searchListener);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        DigestNotifier(
          cutoff: MediaQuery.of(context).size.height,
          onUpdate: _onUpdate,
          shouldUpdate: _shouldUpdate,
          child: SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: MediaQuery.of(context).size.height),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  !_isLoading || _fieldIsEmpty()
                      ? Container()
                      : SizedBox(
                          height: kDefaultLoadingHeight,
                          child: Align(
                            alignment: Alignment.center,
                            child: WaitingWidget(
                              color: Colors.blueAccent,
                              isLoading: _isLoading,
                            ),
                          ),
                        ),
                  SizedBox(height: kPanelPadding * 0.5),
                  Column(
                    children: List<Widget>.generate(_itemCount(), (int index) {
                      final DocumentSnapshot snapshot = _getSnapshot(index);
                      final Map<String, dynamic> data = snapshot.data();
                      final String documentID = snapshot.id;
                      final UniqueKey uniqueKey = _fieldIsEmpty()
                          ? _recentKeys[documentID]
                          : _userKeys[documentID];
                      if (widget.isUserSearch) {
                        return Padding(
                          key: uniqueKey,
                          padding: EdgeInsets.only(bottom: 0.0),
                          child: UserTile(
                            uid: documentID,
                            username: data['username'],
                            profilePhoto: data['profilePhoto'],
                            coverPhoto: data['coverPhoto'],
                            numberOfIthReactions: data['numberOfIthReactions'],
                            navigateToProfilePage: _navigateToProfilePage,
                            snapshot: snapshot,
                          ),
                        );
                      }
                      return Padding(
                        key: uniqueKey,
                        padding: EdgeInsets.only(bottom: 0.0),
                        child: FeedTile(
                          bookmark: data['bookmark'],
                          code: data['code'],
                          description: data['description'],
                          hasDownloaded:
                              Human.hasDownloaded.contains(documentID),
                          name: data['name'],
                          snapshot: snapshot,
                          channelID: documentID,
                          photo: data['photo'],
                          navigateToFeedInfo: _navigateToFeedInfo,
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: kPanelPadding * 0.5),
                ],
              ),
            ),
          ),
        ),
        _fieldIsEmpty() || _isLoading || _userSnapshots.isNotEmpty
            ? Container()
            : Center(
                child: BannerIcon(
                  msg: _getBannerMsg,
                  emoticon: '╚(•⌂•)╝',
                ),
              ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
