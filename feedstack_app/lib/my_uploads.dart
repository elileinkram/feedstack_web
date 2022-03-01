// import 'package:flutter/material.dart';
// import 'package:jasper/post.dart';
// import 'constants.dart';
// import 'human.dart';
//
// class MyUploads extends StatefulWidget {
//   final List<Map<String, dynamic>> posts;
//   final VoidCallback refreshParent;
//   final Future<void> Function() loadMorePosts;
//   final bool Function() shouldLoadMorePosts;
//   final List<Map<String, dynamic>> snapshots;
//
//   MyUploads(
//       {@required this.posts,
//       @required this.refreshParent,
//       @required this.loadMorePosts,
//       @required this.shouldLoadMorePosts,
//       @required this.snapshots});
//
//   @override
//   _MyUploadsState createState() => _MyUploadsState();
// }
//
// class _MyUploadsState extends State<MyUploads> {
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: List.generate(widget.posts.length, (index) {
//         final Map<String, dynamic> data = widget.posts[index];
//         final String caption = data['caption'];
//         final String postID = data['postID'];
//         final int bookmark = data['bookmark'];
//         final dynamic image = data['image'];
//         final String profilePhoto = Human.profilePhoto;
//         final String coverPhoto = Human.coverPhoto;
//         final String username = Human.username;
//         final String authorUID = Human.uid;
//         final UniqueKey key = data['key'];
//         final String heroTag = key.toString();
//         return Padding(
//           key: key,
//           padding: EdgeInsets.only(top: kPanelPadding),
//           child: Hero(
//             tag: heroTag,
//             child: Post(
//               showReactionPanel: true,
//               isUpload: true,
//               loadMorePosts: widget.loadMorePosts,
//               shouldLoadMorePosts: widget.shouldLoadMorePosts,
//               index: index,
//               snapshots: widget.snapshots,
//               uploads: widget.posts,
//               isInsideComments: false,
//               heroTag: heroTag,
//               refreshParent: widget.refreshParent,
//               coverPhoto: coverPhoto,
//               reactionSelected: kNullActionValue,
//               postID: postID,
//               elevation: 0.0,
//               caption: caption,
//               bookmark: bookmark,
//               image: image,
//               profilePhoto: profilePhoto,
//               radius: kPanelPadding,
//               authorUID: authorUID,
//               username: username,
//             ),
//           ),
//         );
//       }),
//     );
//   }
// }
