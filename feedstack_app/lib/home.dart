import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jasper/constants.dart';
import 'package:jasper/digest_notifier.dart';
import 'package:jasper/waiting_widget.dart';
import 'digest.dart';

class Home extends StatefulWidget {
  final List<Map<String, dynamic>> postSnapshots;
  final Future<void> Function() redigest;
  final VoidCallback updateTownHall;
  final bool thereIsNothingLeftInHome;
  final bool isRefreshing;

  Home({
    @required this.postSnapshots,
    @required this.redigest,
    @required this.updateTownHall,
    @required this.thereIsNothingLeftInHome,
    @required this.isRefreshing,
  });

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _isLoading;

  void _toggleIsLoading() {
    _isLoading = !_isLoading;
    if (mounted) {
      setState(() {});
    }
  }

  bool _shouldUpdate() {
    return !_isLoading &&
        !widget.thereIsNothingLeftInHome &&
        !widget.isRefreshing &&
        widget.postSnapshots.isNotEmpty;
  }

  Future<void> _onUpdate() async {
    _toggleIsLoading();
    await widget.redigest();
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
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: kPanelPadding),
                  child: Column(
                    children: [
                      Digest(
                        showReactionPanel: true,
                        shouldLoadMorePosts: _shouldUpdate,
                        loadMorePosts: _onUpdate,
                        shouldIncludeHero: true,
                        isInsideComments: false,
                        postSnapshots: widget.postSnapshots,
                        refreshParent: widget.updateTownHall,
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
                    ],
                  ),
                ),
              ],
            )),
      ),
    );
  }
}

