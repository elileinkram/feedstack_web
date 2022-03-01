import 'package:flutter/material.dart';
import 'package:jasper/waiting_widget.dart';
import 'constants.dart';
import 'digest.dart';
import 'digest_notifier.dart';

class UserPosts extends StatefulWidget {
  final List<Map<String, dynamic>> postSnapshots;
  final String tabLabel;
  final TabController tabController;
  final Future<void> Function(String label) redigest;
  final bool thereIsNothingLeft;
  final int index;
  final VoidCallback refreshProfile;
  final Widget inBetweeners;
  final bool isRefreshing;
  final bool showReactionPanel;

  UserPosts(
      {@required this.postSnapshots,
      @required this.tabLabel,
      @required this.tabController,
      @required this.redigest,
      @required this.thereIsNothingLeft,
      @required this.index,
      @required this.refreshProfile,
      @required this.inBetweeners,
      @required this.isRefreshing,
      @required this.showReactionPanel});

  @override
  _UserPostsState createState() => _UserPostsState();
}

class _UserPostsState extends State<UserPosts> {
  bool _isLoading;

  void _toggleIsLoading() {
    _isLoading = !_isLoading;
    if (mounted) {
      setState(() {});
    }
  }

  bool _isOnThisPage() {
    return widget.tabController.index == widget.index;
  }

  bool _shouldUpdate() {
    return !_isLoading &&
        _isOnThisPage() &&
        !widget.thereIsNothingLeft &&
        !widget.isRefreshing &&
        widget.postSnapshots.isNotEmpty;
  }

  Future<void> _onUpdate() async {
    _toggleIsLoading();
    await widget.redigest(widget.tabLabel);
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
        shouldUpdate: _shouldUpdate,
        cutoff: MediaQuery.of(context).size.height,
        onUpdate: _onUpdate,
        child: SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: Column(
                  children: [
                    widget.inBetweeners,
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: kPanelPadding),
                      child: Column(
                        children: [
                          Digest(
                            showReactionPanel: widget.showReactionPanel,
                            shouldLoadMorePosts: _shouldUpdate,
                            loadMorePosts: _onUpdate,
                            shouldIncludeHero: true,
                            isInsideComments: false,
                            postSnapshots: widget.postSnapshots,
                            refreshParent: widget.refreshProfile,
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
                          SizedBox(height: kPanelPadding)
                        ],
                      ),
                    ),
                  ],
                ))));
  }
}
