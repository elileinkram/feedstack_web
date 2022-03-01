import 'package:flutter/material.dart';
import 'package:jasper/post.dart';
import 'constants.dart';

class Digest extends StatefulWidget {
  final List<Map<String, dynamic>> postSnapshots;
  final VoidCallback refreshParent;
  final bool isInsideComments;
  final bool shouldIncludeHero;
  final Future<void> Function() loadMorePosts;
  final bool Function() shouldLoadMorePosts;
  final List<Map<String, dynamic>> uploads;
  final bool showReactionPanel;

  Digest(
      {@required this.postSnapshots,
      @required this.refreshParent,
      @required this.isInsideComments,
      @required this.shouldIncludeHero,
      @required this.shouldLoadMorePosts,
      this.uploads,
      @required this.loadMorePosts,
      @required this.showReactionPanel});

  @override
  _DigestState createState() => _DigestState();
}

class _DigestState extends State<Digest> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.postSnapshots.length, (int index) {
        final Map<String, dynamic> post = widget.postSnapshots[index];
        final String postID = post['postID'];
        final String caption = post['caption'];
        final int bookmark = post['bookmark'];
        final dynamic image = post['image'];
        final String profilePhoto = post['profilePhoto'];
        final String authorUID = post['authorUID'];
        final String username = post['username'];
        UniqueKey key = post['key'];
        final int reactionSelected = post['reactionSelected'];
        final String coverPhoto = post['coverPhoto'];
        String heroTag = key.toString();
        if (!widget.shouldIncludeHero) {
          heroTag += heroTag + 'bla';
        }
        return Padding(
          key: key,
          padding: EdgeInsets.only(top: kPanelPadding),
          child: Hero(
            tag: heroTag,
            child: Post(
              showReactionPanel: widget.showReactionPanel,
              isUpload: false,
              loadMorePosts: widget.loadMorePosts,
              shouldLoadMorePosts: widget.shouldLoadMorePosts,
              index: index,
              uploads: widget.uploads,
              snapshots: widget.postSnapshots,
              isInsideComments: widget.isInsideComments,
              heroTag: heroTag,
              refreshParent: widget.refreshParent,
              coverPhoto: coverPhoto,
              reactionSelected: reactionSelected,
              postID: postID,
              elevation: 0.0,
              caption: caption,
              bookmark: bookmark,
              image: image,
              profilePhoto: profilePhoto,
              radius: kPanelPadding,
              authorUID: authorUID,
              username: username,
            ),
          ),
        );
      }),
    );
  }
}
